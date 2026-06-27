// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {UV2Pair} from "contracts/coreUV2/UV2Pair.sol";
import {IUV2Factory} from "contracts/coreUV2/Interface/IUV2Factory.sol";

contract UV2Factory is IUV2Factory {
    address public feeTo;
    address public feeToAddressSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
}
