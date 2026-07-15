// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
import {ARB1} from "contracts/Arbitrage/ARB1.sol";
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

contract testARB1 is Test {}
