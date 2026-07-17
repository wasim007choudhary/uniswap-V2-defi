// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {ARB1} from "contracts/ArbitrageExampleContractS/ARB1.sol";
import {
    DAI,
    WETH,
    UNISWAP_V2_ROUTER_02,
    SUSHISWAP_V2_ROUTER_02,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_PAIR_DAI_MKR
} from "test/ConstantsForTest.sol";
import {IWETH} from "test/IWETH.sol";
import {IERC20} from "contracts/coreUV2/Interface/IERC20.sol";

contract ARB1test is Test {
    IUV2Router02 public constant uniRouter = IUV2Router02(UNISWAP_V2_ROUTER_02);
    IUV2Router02 public constant sushiRouter = IUV2Router02(SUSHISWAP_V2_ROUTER_02);
    IERC20 public constant dai = IERC20(DAI);
    IWETH public constant weth = IWETH(WETH);
    address user = address(5);

    ARB1 private arb1;

    function setUp() public {
        arb1 = new ARB1();
        deal(address(this), 50 ether);
        weth.deposit{value: 50 ether}();
        weth.approve(address(uniRouter), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(dai);

        uniRouter.swapExactTokensForTokens(weth.balanceOf(address(this)), 10, path, user, block.timestamp);

        deal(address(dai), user, 5000 ether);
        vm.prank(user);
        dai.approve(address(arb1), type(uint256).max);
    }

    function test_NormalSwapArbitrage() external {
        uint256 balanceBeforeArb = dai.balanceOf(user);
        vm.prank(user);
        arb1.swap(
            ARB1.Arb1Params({
                tokenIn: DAI,
                tokenOut: WETH,
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                inputAmount: 100 ether,
                minProfitFromArb: 1
            })
        );
        uint256 balanceAfterArbitrage = dai.balanceOf(user);
        assertGe(balanceAfterArbitrage, balanceBeforeArb);
        assertEq(dai.balanceOf(address(this)), 0);
        console2.log("balanceBeforeArb : ", balanceBeforeArb);
        console2.log("balanceAfterArb : ", balanceAfterArbitrage);
        console2.log("ProfitMade - ", balanceAfterArbitrage - balanceBeforeArb);
    }

    function test_flash_swapArbitage() external {
        address user1 = address(2);
        uint256 balanceBeforeBorrow = dai.balanceOf(user1);
        uint256 balanceBeforeBorrowUser = dai.balanceOf(user);

        vm.prank(user1);
        arb1.flashSwap(
            UNISWAP_V2_PAIR_DAI_MKR,
            ARB1.Arb1Params({
                tokenIn: DAI,
                tokenOut: WETH,
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                inputAmount: 10 ether,
                minProfitFromArb: 1
            })
        );
        uint256 balanceAfterBorrowArb = dai.balanceOf(user1);
        console2.log("balanceBeforeBorrow : ", balanceBeforeBorrow);
        console2.log("balanceAfterBorrowArb : ", balanceAfterBorrowArb);
        assertGe(balanceAfterBorrowArb, balanceBeforeBorrow);
        assertEq(balanceBeforeBorrow, 0);
        assertEq(dai.balanceOf(address(this)), 0);
        uint256 profit1 = balanceAfterBorrowArb - balanceBeforeBorrow;
        assertEq(profit1, balanceAfterBorrowArb);

        vm.prank(user);
        arb1.flashSwap(
            UNISWAP_V2_PAIR_DAI_MKR,
            ARB1.Arb1Params({
                tokenIn: DAI,
                tokenOut: WETH,
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                inputAmount: 10 ether,
                minProfitFromArb: 1
            })
        );
        uint256 balanceAfterARB = dai.balanceOf(user);
        uint256 profit = balanceAfterARB - balanceBeforeBorrowUser;
        assertEq(balanceAfterARB, profit + balanceBeforeBorrowUser);
        assertEq(balanceBeforeBorrowUser, 5000 ether);
        console2.log(balanceBeforeBorrowUser);
        console2.log(balanceAfterARB);
        console2.log(profit);
    }
}

