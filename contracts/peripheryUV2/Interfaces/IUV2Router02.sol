// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUV2Router01} from "contracts/peripheryUV2/Interfaces/IUV2Router01.sol";

interface IUV2Router02 is IUV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
