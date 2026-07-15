// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {IERC20} from "contracts/peripheryUV2/Interfaces/IERC20.sol";

contract ARB1 {
    error ARB1__swap__RequiredMinimumProfitLimitNotReached();

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
}
