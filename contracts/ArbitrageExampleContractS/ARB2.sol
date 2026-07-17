//SPDX-Licesne-Identifier: MIT
///@dev see notes/Arbitrage Dissectiom aNd ARB ExampleContracts for dissection
pragma solidity ^0.8.20;
import {console2} from "forge-std/console2.sol";
import {IERC20} from "contracts/peripheryUV2/Interfaces/IERC20.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";

contract ARB2 {
    error ARB2__FlashSwap__InavlidToken();
    error ARB2__uniswapV2Call__MinimumProfitLimitNotReached();

    struct ARB2param {
        address tokenIn; // the token which we will inpout for arb
        address tokenOut; // the output whoich we want from the arb
        address pair0; // our target of flash swap and repaymetn where we will make proifit from pair 1
        address pair1; // here we will do the main trade and sell high on pair 0
        uint256 amountToBorrow; // amount we will borrow

        uint256 minProfit;
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function FlashSwap(ARB2param calldata params) external {
        address _token0 = IUV2Pair(params.pair0).token0();
        address _token1 = IUV2Pair(params.pair0).token1();
        if (params.tokenIn != _token0 && params.tokenIn != _token1) {
            revert ARB2__FlashSwap__InavlidToken();
        }
        (uint112 reserve0, uint112 reserve1,) = IUV2Pair(params.pair0).getReserves();
        bool isToken0 = (params.tokenIn == _token0);
        uint256 amountToRepay;
        if (isToken0) {
            amountToRepay = getAmountIn(params.amountToBorrow, reserve1, reserve0);
        } else {
            amountToRepay = getAmountIn(params.amountToBorrow, reserve0, reserve1);
        }
        bytes memory data = abi.encode(msg.sender, params, amountToRepay);

        IUV2Pair(params.pair0)
            .swap({
                amount0Out: isToken0 ? params.amountToBorrow : 0,
                amount1Out: isToken0 ? 0 : params.amountToBorrow,
                to: address(this),
                data: data
            });
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        (address originalCaller, ARB2param memory params, uint256 repaymentAmount) =
            abi.decode(data, (address, ARB2param, uint256));
        address _token0 = IUV2Pair(params.pair1).token0();

        (uint112 reserve0, uint112 reserve1,) = IUV2Pair(params.pair1).getReserves();

        IERC20(params.tokenIn).transfer(params.pair1, params.amountToBorrow);

        bool isBoolToken0 = (params.tokenIn == _token0);
        uint256 amountOut;
        if (isBoolToken0) {
            amountOut = getAmountOut(params.amountToBorrow, reserve0, reserve1);
        } else {
            amountOut = getAmountOut(params.amountToBorrow, reserve1, reserve0);
        }
        IUV2Pair(params.pair1)
            .swap({
                amount0Out: isBoolToken0 ? 0 : amountOut,
                amount1Out: isBoolToken0 ? amountOut : 0,
                to: address(this),
                data: ""
            });

        console2.log("Calculated amountOut", amountOut);
        console2.log("Contract DAI balance", IERC20(params.tokenOut).balanceOf(address(this)));
        console2.log("Repayment amount", repaymentAmount);

        IERC20(params.tokenOut).transfer(params.pair0, repaymentAmount);
        uint256 profit = amountOut - repaymentAmount;
        if (profit < params.minProfit) {
            revert ARB2__uniswapV2Call__MinimumProfitLimitNotReached();
        }
        IERC20(params.tokenOut).transfer(originalCaller, profit);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}

