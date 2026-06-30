# `swapExactTokensForTokensSupportingFeeOnTransferTokens()`

## Purpose

Swaps an **exact amount of input tokens** for as many output tokens as possible while supporting **fee-on-transfer (tax/burn/reflection) tokens**.

Unlike the normal `swapExactTokensForTokens()`, this function **cannot trust that the Pair receives exactly `amountIn`**, because the input token itself may deduct a transfer fee during `transferFrom()`.

Instead of trusting assumptions, this Router measures what **actually happened**.

---

# Execution Flow

```text
User

↓

swapExactTokensForTokensSupportingFeeOnTransferTokens()

↓

Transfer input tokens to first Pair

↓

Record recipient's current output token balance

↓

_jump into_

_swapSupportingFeeOnTransferTokens()

↓

Measure actual input received by each Pair

↓

Calculate outputs

↓

Execute swaps

↓

Return back here

↓

Verify recipient actually received at least amountOutMin

↓

Success / Revert
```

---

# Parameters

## `amountIn`

The exact amount of **input tokens** the user wants to spend.

> **Important**
>
> This is the amount the user **attempts** to send.
>
> It is **not necessarily** the amount the Pair receives.
>
> If the token charges a transfer fee, the Pair may receive less.

---

## `amountOutMin`

The minimum acceptable amount of the final output token.

If the recipient receives less than this amount, the transaction reverts.

---

## `path`

The swap path.

Example:

```text
USDC → WETH → DAI
```

---

## `to`

The final recipient of the output tokens.

---

## `deadline`

Transaction expiration timestamp.

Already discussed previously.

---

# Modifier

```solidity
ensure(deadline)
```

Already dissected.

Prevents execution after the specified deadline.

---

# Transfer Input Tokens

```solidity
TransferHelper.safeTransferFrom(
    path[0],
    msg.sender,
    UniswapV2Library.pairFor(factory, path[0], path[1]),
    amountIn
);
```

## Purpose

Transfers the user's input tokens directly to the **first Pair**.

Notice that the Router is **not** sending tokens to itself.

The first Pair receives the tokens directly.

---

## Where Is The Transfer Fee Deducted?

One of our biggest questions was:

> **"Where is the fee actually getting deducted?"**

Answer:

**Not inside Uniswap.**

The Router eventually calls:

```solidity
IERC20(token).transferFrom(...)
```

Execution temporarily leaves the Router and enters the **token contract**.

If that token is a fee-on-transfer token, its own `transferFrom()` implementation deducts the transfer fee.

For example:

```text
Alice

USDC = 100
XYZ  = 30
```

Alice swaps:

```text
50 USDC → XYZ
```

Suppose USDC charges a **2% transfer fee**.

Execution becomes:

```text
Router

↓

TransferHelper.safeTransferFrom()

↓

USDC.transferFrom()

↓

USDC deducts 1 token

↓

Pair receives 49

↓

Return back to Router
```

After the transfer:

```text
Alice

USDC = 50
XYZ  = 30

Pair

+49 USDC
```

Notice:

The Router never deducted anything.

The **USDC contract** deducted the fee.

---

# Common Confusion — Why Doesn't The Router Check Safety Before The Transfer?

We compared this to the normal Router.

Normal Router:

```text
Calculate Outputs

↓

Safety Check

↓

Transfer

↓

Swap
```

Why?

Because it assumes:

```text
User Sends 100

↓

Pair Receives 100
```

So it already knows every amount before any transfer occurs.

---

Fee-on-transfer Router cannot do that.

Why?

Because before the transfer happens, it has no idea whether the Pair will receive:

```text
100
```

or

```text
98
```

Only the token contract knows.

Therefore the execution order changes:

```text
Transfer

↓

Measure Actual Input

↓

Calculate Output

↓

Swap

↓

Measure Actual Output

↓

Final Safety Check
```

Instead of verifying predictions, this Router verifies reality.

---

# Record Recipient's Output Balance

```solidity
uint256 balanceBefore =
    IERC20(path[path.length - 1]).balanceOf(to);
```

## Purpose

Before performing the swap, the Router records how many **output tokens** the recipient currently owns.

Continuing our example:

```text
Alice

USDC = 50
XYZ  = 30
```

The Router executes:

```solidity
IERC20(XYZ).balanceOf(Alice);
```

Result:

```text
balanceBefore = 30
```

---

# Common Confusion — Didn't Alice's Balance Already Change?

This was one of our biggest questions.

> **"Wait... didn't `safeTransferFrom()` already execute? Alice's balance already changed!"**

Yes.

But only **Alice's input token balance** changed.

After the transfer:

```text
Alice

USDC = 50 ✅
XYZ  = 30
```

The Router is **not** checking Alice's USDC.

It is checking Alice's **XYZ** balance.

The output token has not been received yet because the swap hasn't happened.

Therefore:

```text
balanceBefore = 30
```

is still correct.

---

# Common Confusion — Are We Checking Pair Reserves Here?

Another question we had:

> **"Shouldn't we be checking the Pair balance or reserves?"**

No.

Not inside this function.

This function is responsible for measuring:

```text
Recipient's Output Balance
```

The Pair balance is measured later inside:

```solidity
_swapSupportingFeeOnTransferTokens(...)
```

using:

```solidity
amountInput =
    IERC20(input)
        .balanceOf(address(pair))
        .sub(reserveInput);
```

That answers a completely different question:

> **"How many input tokens actually reached the Pair?"**

So the work is intentionally split.

---

Public Function

```text
Measure Recipient's Output Balance
```

Internal Function

```text
Measure Pair's Input Balance
```

Together they verify both sides of the swap.

---

# Jump Into The Internal Function

```solidity
_swapSupportingFeeOnTransferTokens(path, to);
```

Execution now leaves this function and enters:

```text
_swapSupportingFeeOnTransferTokens()
```

The EVM temporarily pauses execution of the current function.

Inside the internal helper, the Router will:

- Measure how many input tokens actually reached each Pair.
- Calculate the correct output amount.
- Execute every swap.

Once the helper finishes, the EVM resumes execution **right after this line**, continuing with the remaining statements of this function.

> **See:** `notes/router/_swapSupportingFeeOnTransferTokens.md`

The remaining lines of this function will be dissected after completing the internal helper function.