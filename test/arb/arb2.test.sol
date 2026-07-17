// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
import {ARB2} from "contracts/ArbitrageExampleContractS/ARB2.sol";
import {
    DAI,
    WETH,
    UNISWAP_V2_ROUTER_02,
    UNISWAP_V2_PAIR_DAI_WETH,
    SUSHISWAP_V2_ROUTER_02,
    SUSHISWAP_V2_PAIR_DAI_WETH
} from "test/ConstantsForTest.sol";
import {IWETH} from "test/IWETH.sol";
import {IERC20} from "contracts/coreUV2/Interface/IERC20.sol";

contract ARB2test is Test {
    ARB2 public arb2;
    IUV2Router02 public constant uniRouter = IUV2Router02(UNISWAP_V2_ROUTER_02);
    IUV2Router02 public constant sushiRouter = IUV2Router02(SUSHISWAP_V2_ROUTER_02);
    IUV2Pair public constant uniPair0 = IUV2Pair(UNISWAP_V2_PAIR_DAI_WETH);
    IUV2Pair public constant sushiPiar1 = IUV2Pair(SUSHISWAP_V2_PAIR_DAI_WETH);
    IERC20 public constant dai = IERC20(DAI);
    IWETH public constant weth = IWETH(WETH);

    address userW = address(2);

    function setUp() public {
        arb2 = new ARB2();

        deal(address(this), 50 ether);
        weth.deposit{value: 50 ether}();

        weth.approve(address(uniRouter), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        uniRouter.swapExactTokensForTokens(weth.balanceOf(address(this)), 1, path, userW, block.timestamp);
        (uint112 u0, uint112 u1,) = uniPair0.getReserves();
        (uint112 s0, uint112 s1,) = sushiPiar1.getReserves();

        console2.log("UNI DAI :", u0);
        console2.log("UNI WETH:", u1);
        console2.log("SUSHI DAI :", s0);
        console2.log("SUSHI WETH:", s1);
        console2.log("UNI token0", address(uniPair0.token0()));
        console2.log("UNI token1", address(uniPair0.token1()));

        console2.log("SUSHI token0", address(sushiPiar1.token0()));
        console2.log("SUSHI token1", address(sushiPiar1.token1()));
        console2.log(block.number);
    }

    function test__ARB2FlashSwap() external {
        address user1 = address(5);
        uint256 balanceDAIbeforeARB = dai.balanceOf(user1);
        uint256 balanceWETHbeforeARB = weth.balanceOf(user1);

        vm.prank(user1);

        arb2.FlashSwap(
            ARB2.ARB2param({
                tokenIn: address(weth),
                tokenOut: address(dai),
                pair0: address(uniPair0),
                pair1: address(sushiPiar1),
                amountToBorrow: 2 ether, // here from 3 onwars it fails as we were using the latest reserves and amm in our fork no a specific block, its live type feeling
                minProfit: 5
            })
        );

        uint256 balanceDAIafterARB = dai.balanceOf(user1);
        uint256 balanceOfARBcontract = dai.balanceOf(address(arb2));
        uint256 profit = balanceDAIafterARB - balanceDAIbeforeARB;
        console2.log("balanceDAIbeforeARB :- ", balanceDAIbeforeARB);
        console2.log("balanceDAIafterARB :-", balanceDAIafterARB);
        console2.log("balanceOfARBcontract :-", balanceOfARBcontract);

        assertGe(balanceDAIafterARB, balanceDAIbeforeARB);
        assertEq(balanceWETHbeforeARB, 0);
        assertEq(balanceOfARBcontract, 0);
        assertEq(profit, balanceDAIafterARB);
    }
}
