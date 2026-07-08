// SPDX-Lisense-Identifeir: MIT

pragma solidity ^0.8.20;

import {IUV2ERC20} from "contracts/coreUV2/Interface/IUV2ERC20.sol";

contract UniswapV2ERC20 is IUV2ERC20 {
    error UV2ERC20__permit__SignatureImplementationDeadlinePassed();
    error UV2ERC20__permit__InvalidSignature();

    string public constant name = "Uniswap-V2 LP Token";
    string public constant symbol = "UV2-LP";
    uint8 public constant decimal = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    //BASICALLY hash of the permit function with the args, not value tho, computer language of what the functio looks like
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public nonces;

    constructor() {
        uint256 chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        totalSupply -= value;
        balanceOf[from] -= value;
        emit Transfer(from, address(0), value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another using a previously granted allowance.
     * @dev Allows an approved spender to move tokens owned by `from`.
     *
     *      Execution flow:
     *      1. Checks whether the spender has an unlimited allowance (`type(uint256).max`).
     *      2. If the allowance is not unlimited, decreases it by `value`.
     *         - If `value` exceeds the remaining allowance, the subtraction underflows
     *           and the transaction automatically reverts in Solidity 0.8+.
     *      3. Calls `_transfer(from, to, value)` to move the tokens.
     *      4. Returns `true` on success.
     *
     *      Unlimited allowance is treated as a special sentinel value. When the allowance
     *      equals `type(uint256).max`, it is not decremented after each transfer,
     *      allowing repeated transfers without requiring additional approvals.
     *
     *      This function does not explicitly compare `allowance >= value`; instead,
     *      the subtraction operation enforces this requirement through Solidity's
     *      built-in underflow checks.
     *
     *      Note that an unlimited allowance does not bypass balance checks. The owner
     *      must still own at least `value` tokens, otherwise `_transfer()` reverts due
     *      to an insufficient balance.
     *
     * @param from The address currently owning the tokens.
     * @param to The recipient address that will receive the tokens.
     * @param value The amount of tokens to transfer.
     *
     * @return success Returns `true` if the transfer completes successfully.
     *
     * @custom:reverts Panic(0x11)
     * Reverts if the remaining allowance is less than `value`, causing an arithmetic
     * underflow during allowance subtraction.
     *
     * @custom:reverts Panic(0x11)
     * Reverts if `from` does not have at least `value` tokens, causing an arithmetic
     * underflow during the balance update inside `_transfer()`.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice Approves `spender` to spend `owner`'s tokens using an off-chain EIP-712 signature.
     * @dev Implements the EIP-2612 permit mechanism, allowing token approvals without requiring
     *      the token owner to submit an on-chain `approve()` transaction.
     *
     *      Execution flow:
     *      1. Verifies that the signed permit has not expired.
     *      2. Builds the EIP-712 message digest using:
     *         - The EIP-712 prefix (`\x19\x01`)
     *         - The cached DOMAIN_SEPARATOR
     *         - The hashed Permit struct
     *      3. Recovers the signer from the provided signature using `ecrecover`.
     *      4. Verifies that the recovered signer matches `owner`.
     *      5. Updates the allowance by calling `_approve(owner, spender, value)`.
     *
     *      The current nonce is included in the signed message and is post-incremented
     *      (`nonces[owner]++`) to prevent replay attacks. If this function reverts at
     *      any point, the nonce increment is reverted as well because Ethereum
     *      transactions are atomic.
     *
     *      Unlike `approve()`, the owner is authenticated through a cryptographic
     *      signature rather than `msg.sender`, allowing third parties (such as the
     *      Uniswap Router) to submit the permit transaction on the owner's behalf.
     *
     * @param owner The address granting the spending allowance.
     * @param spender The address that will be allowed to spend the owner's tokens.
     * @param value The amount of tokens to approve.
     * @param deadline The Unix timestamp after which the signature becomes invalid.
     * @param v The recovery identifier component of the ECDSA signature.
     * @param r The first 32-byte component of the ECDSA signature.
     * @param s The second 32-byte component of the ECDSA signature.
     *
     * @custom:reverts UV2ERC20__permit__SignatureImplementationDeadlinePassed
     * Reverts if the current block timestamp is greater than the provided deadline.
     *
     * @custom:reverts UV2ERC20__permit__InvalidSignature
     * Reverts if signature recovery fails or if the recovered signer is not the owner.
     *  -----------------------------------------------------------------------------------------------
     * @custom:see Visit notes/UV2ERC20.sol/P4 or better notes/UV2ERC20.sol P1 to P4 to understand this contract and especially this function!
     * It is dissected and normalized to its bone so now worries!
     *   -----------------------------------------------------------------------------------------------
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (deadline < block.timestamp) {
            revert UV2ERC20__permit__SignatureImplementationDeadlinePassed();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01", //eip712 tag
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert UV2ERC20__permit__InvalidSignature();
        }
        _approve(owner, spender, value);
    }
}
