// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/*////////////////////////////////////////////////////////
                   IMPORTS
////////////////////////////////////////////////////////*/
import {UV2Pair} from "contracts/coreUV2/UV2Pair.sol";
import {IUV2Factory} from "contracts/coreUV2/Interface/IUV2Factory.sol";

contract UV2Factory is IUV2Factory {
    /*///////////////////////////////////////////////////////
                                  STATE VARIABLES
    ////////////////////////////////////////////////////////*/
    address public feeTo;
    address public feeToAddressSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    /*////////////////////////////////////////////////////////
                       ERRORS
    ////////////////////////////////////////////////////////*/
    error UV2Factory__createPair__Identical_Address();
    error UV2Factory__createPair_InvalidAddressZeroDetected();
    error UV2Factory__createPair__PairAlreadyExists();

    //event in interface only emiiting here

    constructor(address _feeToAddressSetter) {
        feeToAddressSetter = _feeToAddressSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) {
            revert UV2Factory__createPair__Identical_Address();
        }
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert UV2Factory__createPair_InvalidAddressZeroDetected();
        }
        if (getPair[token0][token1] != address(0)) {
            revert UV2Factory__createPair__PairAlreadyExists();
        }
        bytes memory bytecode = type(UV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    }
}
