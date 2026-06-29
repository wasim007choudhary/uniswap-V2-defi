// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/*////////////////////////////////////////////////////////
                   IMPORTS
////////////////////////////////////////////////////////*/
import {UV2Pair, IUV2Pair} from "contracts/coreUV2/UV2Pair.sol";
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
    error UV2Factory__setFeeTo__InvalidCaller();
    error UV2Factory__SetFeeToAddressSetter__AddressNotAuthorizedToSet();

    /*////////////////////////////////////////////////////////
                       EVENTS
    ////////////////////////////////////////////////////////*/
    //event in interface only emiiting here
    /*////////////////////////////////////////////////////////
                       CONSTRUCTOR
    ////////////////////////////////////////////////////////*/
    constructor(address _feeToAddressSetter) {
        feeToAddressSetter = _feeToAddressSetter;
    }

    /*////////////////////////////////////////////////////////
                       EXTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////*/
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Creates and registers a new liquidity Pair contract for two ERC-20 tokens.
     * @dev This is the core function of the Factory and is responsible for deploying
     *      new UV2Pair contracts using the CREATE2 opcode, ensuring deterministic
     *      addresses and enforcing the invariant that only one Pair can exist for
     *      any unique token combination.
     *
     *      Function flow:
     *      1. Validates that the two token addresses are different.
     *      2. Sorts the token addresses into a canonical order (token0 < token1).
     *      3. Rejects the zero address.
     *      4. Verifies that the Pair does not already exist.
     *      5. Obtains the Pair creation (init) bytecode.
     *      6. Generates a deterministic CREATE2 salt from the sorted tokens.
     *      7. Deploys a new UV2Pair contract using CREATE2.
     *      8. Initializes the newly deployed Pair with token0 and token1.
     *      9. Registers the Pair in both lookup directions.
     *      10. Stores the Pair in the global Pair registry.
     *      11. Emits a PairCreated event.
     *
     *      The Pair is deployed using CREATE2, meaning its address is deterministic
     *      and can be calculated ahead of time from:
     *      - Factory address
     *      - Salt
     *      - Pair creation code hash
     *
     *      The Pair is initially deployed as a generic contract and is immediately
     *      configured through `initialize(token0, token1)` to permanently associate
     *      it with the supplied token pair.
     *
     * @param tokenA The first ERC-20 token address supplied by the caller.
     * @param tokenB The second ERC-20 token address supplied by the caller.
     *
     * @return pair The address of the newly deployed and initialized UV2Pair contract.
     *
     * @custom:reverts UV2Factory__createPair__Identical_Address
     *         Thrown when both supplied token addresses are identical.
     *
     * @custom:reverts UV2Factory__createPair_InvalidAddressZeroDetected
     *         Thrown when either token address resolves to the zero address after sorting.
     *
     * @custom:reverts UV2Factory__createPair__PairAlreadyExists
     *         Thrown when a Pair has already been created for the supplied token combination.
     *
     * @custom:emits PairCreated
     *         Emitted after the Pair has been successfully deployed, initialized,
     *         registered, and added to the Factory registry.
     *
     *  @custom:see go through  [notes/Factory/4.Functions] or event better (must)[notes/Factory] for complete dissection from scrath.GGs
     */

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

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IUV2Pair(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Updates the protocol fee recipient.
     * @dev Only the current `feeToSetter` is authorized to change the protocol
     *      fee recipient. Passing the zero address effectively disables protocol
     *      fee collection until a new recipient is configured.
     *
     *      This function does not modify the administrator itself; it only updates
     *      the address that will receive protocol fees when fee collection is enabled.
     *
     * @param _feeTo The address that will receive future protocol fees.
     *
     * @custom:reverts UV2Factory__Forbidden
     *         Thrown when the caller is not the current `feeToSetter`.
     */
    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToAddressSetter) {
            revert UV2Factory__setFeeTo__InvalidCaller();
        }
        feeTo = _feeTo;
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Transfers administrative control of the Factory.
     * @dev Only the current `feeToSetter` can assign a new administrator.
     *
     *      After this function executes successfully, the previous administrator
     *      permanently loses permission to call administrative functions, and the
     *      newly assigned `feeToSetter` becomes the sole authority responsible for
     *      managing protocol fee configuration.
     *
     * @param _feeToAddressSetter The address that will become the new Factory administrator.
     *
     * @custom:reverts UV2Factory__Forbidden
     *         Thrown when the caller is not the current `feeToSetter`.
     */
    function SetFeeToAddressSetter(address _feeToAddressSetter) external {
        if (msg.sender != feeToAddressSetter) {
            revert UV2Factory__SetFeeToAddressSetter__AddressNotAuthorizedToSet();
        }
    }
}
