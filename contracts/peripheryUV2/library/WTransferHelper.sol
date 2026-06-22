// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MyTransferHelper {
    ///////////////////////////////////////////////////////////////////////////
    //                                ERRORS
    ///////////////////////////////////////////////////////////////////////////
    error TrasnferHelper__safeApprove__ApproveNotSuccessful();
    error TrasnferHelper__safeApprove__TokenReturnData_ApprovalFailed();
    error TrasnferHelper__safeTransfer__TransferNotSuccessful();
    error TrasnferHelper__safeTransfer__TokenReturnData_TransferFailed();
    error TrasnferHelper__safeTransferFrom__TransferFromNotSuccessful();
    error TrasnferHelper__safeTransferFrom__TokenReturnData_TransferFromFailed();
    error TrasnferHelper__safeETHTrasnfer__ETHtransferNotSuccessful();

    //////////////////////////////////////////////////////////////////////////////
    //                              iNTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Safely approves a spender to spend tokens.
     *
     * @dev WHY THIS EXISTS (Instead of plain IERC20.approve):
     *
     *      Plain `IERC20(token).approve(spender, amount)` breaks on non-standard tokens.
     *      This function uses low-level `call` + manual validation to handle ALL tokens.
     *
     * ============================================================================
     * THE PROBLEM WITH PLAIN approve()
     * ============================================================================
     *
     *      IERC20(token).approve(spender, amount)
     *
     *      Solidity uses the ERC-20 interface, which expects approve() to return a bool.
     *      Different tokens behave differently:
     *
     *      ┌──────────────────────┬────────────────────┬──────────────────────────┐
     *      │ Token Type           │ Returns            │ What Happens              │
     *      ├──────────────────────┼────────────────────┼──────────────────────────┤
     *      │ Standard (DAI, UNI)  │ true (bool)        │ ✅ Works                  │
     *      │ USDT (non-standard)  │ NOTHING (void)     │ ❌ REVERTS!               │
     *      │ Broken token         │ false (bool)       │ ❌ Silent failure!        │
     *      └──────────────────────┴────────────────────┴──────────────────────────┘
     *
     *      USDT PROBLEM:
     *      USDT was deployed before the ERC-20 standard was finalized.
     *      Its approve() function has NO return value (void).
     *      But the IERC20 interface says approve() returns (bool).
     *      Solidity checks the return data. It's empty. Expected 32 bytes.
     *      → REVERTS with "function returned an unexpected amount of data"
     *      → The approval ACTUALLY WORKED, but your transaction FAILS!
     *
     *      BROKEN TOKEN PROBLEM:
     *  Some tokens return false on failure.
     *
     * If the caller ignores the returned bool,
     * the operation may silently fail.
     *
     * safeApprove explicitly validates the returned bool.
     *
     * ============================================================================
     * HOW safeApprove FIXES IT
     * ============================================================================
     *
     *      1. Uses low-level `call` instead of interface:
     *         - No return type enforcement
     *         - Returns (bool success, bytes memory data) raw
     *         - Won't revert just because return data is unexpected
     *
     *      2. Manual validation logic:
     *         require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
     *
     *         "Did the call succeed? AND (did the token return nothing? OR did it return true?)"
     *
     *      ┌──────────┬──────────────────┬──────────────────┬──────────────────────────┐
     *      │ success  │ data             │ data.length == 0 │ abi.decode(data, (bool)) │ Result   │
     *      ├──────────┼──────────────────┼──────────────────┼──────────────────────────┤
     *      │ true     │ "" (empty)       │ TRUE → PASS      │ (short-circuits)        │ ✅ PASS  │
     *      │ true     │ true (32 bytes)  │ FALSE            │ TRUE                    │ ✅ PASS  │
     *      │ true     │ false (32 bytes) │ FALSE            │ FALSE → REVERT          │ ❌ REVERT│
     *      │ false    │ anything         │ (not reached)    │ (not reached)           │ ❌ REVERT│
     *      └──────────┴──────────────────┴──────────────────┴──────────────────────────┘
     *
     *      CASE 1: success=true, data empty (USDT)
     *        - Approval worked. Token returned nothing (silent success).
     *        - data.length == 0 is TRUE → short-circuits → PASS ✅
     *
     *      CASE 2: success=true, data=true (Standard ERC-20 like DAI)
     *        - Approval worked. Token returned true.
     *        - data.length == 0 is FALSE → check abi.decode → TRUE → PASS ✅
     *
     *      CASE 3: success=true, data=false (Broken token)
     *        - Approval failed but didn't revert. Token returned false.
     *        - data.length == 0 is FALSE → check abi.decode → FALSE → REVERT ❌
     *
     *      CASE 4: success=false (Any token that reverted)
     *        - Approval reverted entirely.
     *        - success is false → short-circuits the && → REVERT ❌
     *
     * ============================================================================
     * WHY NOT JUST USE PLAIN approve() EVERYWHERE?
     * ============================================================================
     *
     *      Plain approve:
     *        ✅ Standard tokens: Works
     *        ❌ USDT: Reverts even though approval succeeded
     *        ❌ Broken tokens: Silent failure (returns false, code thinks it passed)
     *
     *      safeApprove:
     *        ✅ Standard tokens: Works (decodes true)
     *        ✅ USDT: Works (treats empty data as success)
     *        ✅ Broken tokens: Reverts with clear error (catches false)
     *        ✅ ALL TOKENS: Works correctly
     *
     * ============================================================================
     * @custom:q-and-a From our discussion:
     *
     *      Q: "Tokens either return true or nothing. If it returns nothing and fails?"
     *      A: If the function fails, it REVERTS. success becomes false.
     *         The require catches it on the first check (success == false).
     *         It never reaches data.length or abi.decode.
     *
     *      Q: "What if success happened and data returned by the token is nothing?"
     *      A: It PASSES. data.length == 0 is true → short-circuits → success assumed.
     *         This is the USDT case. Silent success = success.
     *
     *      Q: "Token ever only returns true or false nothing else?"
     *      A: Yes. approve() and transfer() return true or nothing (USDT).
     *         They never return false in practice. If they fail, they revert.
     *         But the abi.decode check for false is there as a safety net for broken tokens.
     *
     * ============================================================================
     * @param token The token contract address to call approve on
     * @param to The spender address being approved
     * @param value The amount of tokens to approve
     * ==========================================================================
     * @dev The token's return data (if any) is ABI-encoded as a uint256:
     *      - `true`  = 0x00...01 (32 bytes, value 1)
     *      - `false` = 0x00...00 (32 bytes, value 0)
     *      `abi.decode(data, (bool))` converts the number back to a Solidity bool.
     */
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)'))) = 0x095ea7b3
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        if (!success) {
            revert TrasnferHelper__safeApprove__ApproveNotSuccessful();
        }
        if (data.length > 0 && !abi.decode(data, (bool))) {
            revert TrasnferHelper__safeApprove__TokenReturnData_ApprovalFailed();
        }
    }

    /**
     *  Read the safeApprove natspec same logic here too, wont repeart myself just , its trasnfer this time
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        //bytes4(keccak256(bytes('transfer(address,uint256)'))) = 0xa9059cbb
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (!success) {
            revert TrasnferHelper__safeTransfer__TransferNotSuccessful();
        }
        if (data.length > 0 && !abi.decode(data, (bool))) {
            revert TrasnferHelper__safeTransfer__TokenReturnData_TransferFailed();
        }
    }

    /**
     *  Read the safeApprove natspec same logic here too, wont repeart myself just , its trasnferFrom this time
     */
    function safeTrasnferFrom(address token, address from, address to, uint256 value) internal {
        //bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))) = 0x23b872dd
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if (!success) {
            revert TrasnferHelper__safeTransferFrom__TransferFromNotSuccessful();
        }
        if (data.length > 0 && !abi.decode(data, (bool))) {
            revert TrasnferHelper__safeTransferFrom__TokenReturnData_TransferFromFailed();
        }
    }

    /**
     * @notice Safely transfers ETH to a recipient address.
     *
     * @dev WHY ONLY `success` IS CHECKED (Unlike safeTransfer/safeApprove):
     *
     * ETH is the native currency of Ethereum.
     *
     * Unlike ERC20 token transfers, sending ETH does not require interacting
     * with a token contract that returns success values or ABI-encoded data.
     *
     * As a result:
     *
     * - There is no ERC20 interface to enforce
     * - No bool return value to validate
     * - No USDT-style non-standard return behavior
     * - No token-specific compatibility issues
     *
     *      The EVM guarantees atomicity:
     *        - success = true  → ETH was delivered ✅
     *        - success = false → The call reverted, ETH stayed ❌
     *
     *      There is NO scenario where success=true but ETH wasn't sent. {there are weird edge cases around selfdestruct, forced ETH, contract accounting, etc. we ignore that here tho! no worries}
     *      No false positives. No silent failures. No return data quirks.
     *
     *  Unlike ERC20 transfers, there is no token return value that must be
     * decoded or validated after the transfer succeeds.
     *
     *      COMPARISON WITH safeTransfer (TOKENS):
     *
     *      ┌──────────────────────┬─────────────────────────────┬─────────────────────────┐
     *      │                      │ safeTransfer (ERC-20)       │ safeTransferETH (ETH)   │
     *      ├──────────────────────┼─────────────────────────────┼─────────────────────────┤
     *      │ What it sends        │ ERC-20 tokens               │ Native ETH              │
     *      │ How it sends         │ Calls token.transfer()      │ Direct value transfer   │
     *      │ Calldata             │ transfer selector + args    │ Empty (new bytes(0))    │
     *      │ Return data possible?│ Yes (true/false/nothing)    │ No                      │
     *      │ USDT-style quirk?    │ Yes (returns nothing)       │ No equivalent           │
     *      │ False positives?     │ Yes (success=true, data=false)│ No                    │
     *      │ Validation needed    │ success + decode data       │ success only            │
     *      └──────────────────────┴─────────────────────────────┴─────────────────────────┘
     *
     *      TOKEN PROBLEMS (safeTransfer must handle):
     *        - Standard token: returns true → decode and verify ✅
     *        - USDT: returns nothing → data.length == 0 → treat as success ✅
     *        - Broken token: returns false → decode and REVERT ❌
     *
     *      ETH HAS NONE OF THESE:
     *        - No contract = no return data at all
     *        - No interface = no unexpected return types
     *        - success is the ONLY signal needed
     *
     *  ============================================================================
     * WHY USE `call` INSTEAD OF `transfer()` OR `send()`?
     * ============================================================================
     *
     * Historically Solidity provided:
     *
     * - transfer()
     * - send()
     *
     * Both forward only 2300 gas to the recipient.
     *
     * After EIP-1884, certain opcodes became more expensive, causing some
     * contracts to require more than 2300 gas in their receive/fallback logic.
     *
     * As a result:
     *
     * - transfer() may unexpectedly revert
     * - send() may unexpectedly fail
     * - perfectly valid recipient contracts may become unable to receive ETH
     *
     * Using:
     *
     * payable(to).call{value: value}("")
     *
     * forwards the remaining available gas and is now considered the
     * recommended method for transferring ETH.
     *
     * This helper follows the modern Solidity best practice.
     * @param to The recipient address
     * @param value The amount of ETH (in wei) to send
     *
     * @dev ETH can be sent to any address: EOA or contract. No distinction.
     * The only check is success — did the transfer go through?The only validation required is the call's success status:
     * did the ETH transfer and recipient execution complete without reverting?
     */
    function safeETHTrasnfer(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        if (!success) {
            revert TrasnferHelper__safeETHTrasnfer__ETHtransferNotSuccessful();
        }
    }
}
