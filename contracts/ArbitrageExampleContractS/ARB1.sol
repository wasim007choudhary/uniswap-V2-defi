// SPDX-License-Identifeir: MIT
///@dev see notes/Arbitrage Dissectiom aNd ARB ExampleContracts for dissection
pragma solidity ^0.8.20;

import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {IERC20} from "contracts/peripheryUV2/Interfaces/IERC20.sol";

contract ARB1 {
    error ARB1__swap__RequiredMinimumProfitLimitNotReached();
    error ARB1__uniswapV2Call__RequiredMinimumProfitLimitNotReached();

    struct Arb1Params {
        address tokenIn;
        address tokenOut;
        address router0;
        address router1;
        uint256 inputAmount;
        uint256 minProfitFromArb;
    }

    function _swap(Arb1Params memory arbParam) internal returns (uint256 amountOut) {
        //first swap lets say it is uniswap
        IERC20(arbParam.tokenIn).approve(arbParam.router0, arbParam.inputAmount);
        address[] memory pathForRouter0 = new address[](2);

        pathForRouter0[0] = arbParam.tokenIn;
        pathForRouter0[1] = arbParam.tokenOut;
        uint256[] memory outputAmountsFromRouter0 = IUV2Router02(arbParam.router0)
            .swapExactTokensForTokens({
                amountIn: arbParam.inputAmount,
                amountOutMin: 0,
                path: pathForRouter0,
                to: address(this),
                deadline: block.timestamp + 300
            });

        // second swap lets say it is xyzSwap protocl
        IERC20(arbParam.tokenOut).approve(arbParam.router1, outputAmountsFromRouter0[1]);
        address[] memory pathForRouter1 = new address[](2);
        pathForRouter1[0] = arbParam.tokenOut;
        pathForRouter1[1] = arbParam.tokenIn;
        uint256[] memory outputAmountsFromRouter1 = IUV2Router02(arbParam.router1)
            .swapExactTokensForTokens({
                amountIn: outputAmountsFromRouter0[1],
                amountOutMin: 0,
                path: pathForRouter1,
                to: address(this),
                deadline: block.timestamp
            });
        amountOut = outputAmountsFromRouter1[1];
    }

    function swap(Arb1Params memory arbParam) external {
        // before here the aprroveal must happen first so say the user must aprrove thier arb contarct to ab able to use the or move the tokens
        IERC20(arbParam.tokenIn).transferFrom(msg.sender, address(this), arbParam.inputAmount);
        uint256 amountOut = _swap(arbParam);
        if (amountOut - arbParam.inputAmount < arbParam.minProfitFromArb) {
            revert ARB1__swap__RequiredMinimumProfitLimitNotReached();
        }
        IERC20(arbParam.tokenIn).transfer(msg.sender, amountOut);
    }

    //now lets try flash swap using uniswap v2 and xyzSwap protocl, remebr router0 is noit strictly uniswap it csn be any protocol which hav e those unctions a mean but here lets say uni and 1 is xyzprotocol or shuiswa[p
    function flashSwap(address pairContract, Arb1Params memory arbParam) external {
        address _token0 = IUV2Pair(pairContract).token0();
        bool isToken0 = (arbParam.tokenIn == _token0);
        bytes memory data = abi.encode(msg.sender, pairContract, arbParam);

        IUV2Pair(pairContract)
            .swap({
                amount0Out: isToken0 ? arbParam.inputAmount : 0,
                amount1Out: isToken0 ? 0 : arbParam.inputAmount,
                to: address(this),
                data: data
            });
        // in if block
        /* uint256 amount0Out;
        uint256 amount1Out;

        if (isToken0) {
            amount0Out = params.amountIn;
            amount1Out = 0;
        } else {
            amount0Out = 0;
            amount1Out = params.amountIn;
        }

        IUniswapV2Pair(pair).swap({
            amount0Out: amount0Out,
            amount1Out: amount1Out,
            to: address(this),
            data: data
        });*/

        // or more simple way -

        /*uint256 amount0Out = 0;
        uint256 amount1Out = 0;

        if (isToken0) {
            amount0Out = params.amountIn;
        } else {
            amount1Out = params.amountIn;
        }

        IUniswapV2Pair(pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            data
        );*/
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        (address originalFunctionCaller, address pairAddressCalled, Arb1Params memory arbParam) =
            abi.decode(data, (address, address, Arb1Params));
        uint256 amountOut = _swap(arbParam);

        uint256 fee = ((arbParam.inputAmount * 3) / 997) + 1;
        uint256 amountToRepay = arbParam.inputAmount + fee;
        uint256 profit = amountOut - amountToRepay;

        if (profit < arbParam.minProfitFromArb) {
            revert ARB1__uniswapV2Call__RequiredMinimumProfitLimitNotReached();
        }
        IERC20(arbParam.tokenIn).transfer(pairAddressCalled, amountToRepay);
        IERC20(arbParam.tokenIn).transfer(originalFunctionCaller, profit);
    }
}
