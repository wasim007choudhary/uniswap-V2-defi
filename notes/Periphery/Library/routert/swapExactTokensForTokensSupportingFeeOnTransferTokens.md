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

> **See:** `notes/router/internal__swapSupportingFeeOnTransferTokens.md`

---
# Final Safety Check

```solidity
require(
    IERC20(path[path.length - 1]).balanceOf(to)
        .sub(balanceBefore)
        >= amountOutMin,
    "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
);
```

## Purpose

Verifies that the recipient actually received **at least** `amountOutMin` output tokens.

Unlike the normal Router, this Router **cannot know the final output amount before the swap begins**, because fee-on-transfer tokens may deduct tokens during transfers.

Instead of trusting calculations, it measures the recipient's final balance after all swaps finish.

---

# Step 1 — Read Recipient's Current Balance

```solidity
IERC20(path[path.length - 1]).balanceOf(to)
```

Reads the recipient's **current balance** of the final output token.

Suppose before the swap:

```text
Alice

XYZ = 30
```

Earlier in this function we stored:

```solidity
balanceBefore = 30;
```

Now the entire swap has completed.

Suppose Alice's balance becomes:

```text
Alice

XYZ = 77
```

This line returns:

```text
77
```

---

# Step 2 — Calculate How Much Was Actually Received

```solidity
.sub(balanceBefore)
```

The Router computes:

```text
Current Balance

77

-

Previous Balance

30

=

47
```

Now it knows:

```text
Alice actually received

47 XYZ
```

Notice that the Router never asks:

> "How many tokens should Alice have received?"

Instead it asks:

> **"How many tokens does Alice actually own now?"**

---

# Why Doesn't It Compare Against `amountOutput`?

One of our biggest questions was:

> **"The Router already calculated `amountOutput`. Why not compare against that?"**

Because the **output token itself** may also charge a transfer fee.

Example:

The Pair sends:

```text
50 XYZ
```

Suppose XYZ charges a transfer fee.

Execution becomes:

```text
Pair sends

50 XYZ

↓

XYZ deducts

3 XYZ

↓

Alice receives

47 XYZ
```

Although the Pair sent:

```text
50
```

Alice only received:

```text
47
```

If the Router compared against the Pair's output amount, it would incorrectly believe Alice received all 50 tokens.

Instead, it measures Alice's wallet balance directly.

Reality is always more accurate than assumptions.

---

# Common Confusion — Didn't We Already Measure The Pair Balance?

Yes.

Inside:

```text
_swapSupportingFeeOnTransferTokens()
```

we measured:

```text
How many input tokens actually reached the Pair?
```

using:

```solidity
balanceOf(pair) - reserveInput;
```

That was required to calculate the correct swap output.

Now, back inside this public function, we measure something completely different:

```text
How many output tokens actually reached the recipient?
```

using:

```solidity
balanceOf(to) - balanceBefore;
```

These are two completely different measurements.

---

# Why Split The Work?

The Router intentionally splits the work into two functions.

## Public Function

Measures:

```text
Recipient's Output Balance
```

Question answered:

> **"How many output tokens actually reached the user?"**

---

## Internal Function

Measures:

```text
Pair's Input Balance
```

Question answered:

> **"How many input tokens actually reached the Pair?"**

Together, these two measurements make fee-on-transfer swaps possible.

---

# Compare Against `amountOutMin`

```solidity
>= amountOutMin
```

Suppose:

```text
amountOutMin = 45
```

Alice actually received:

```text
47
```

The check becomes:

```text
47 >= 45

✅ True
```

The transaction succeeds.

Now suppose Alice only received:

```text
43
```

The check becomes:

```text
43 >= 45

❌ False
```

Execution immediately reverts.

---

# Common Confusion — But The Swaps Already Happened!

One of our questions was:

> **"The swaps already executed. Isn't it too late to check now?"**

No.

Everything happens inside **one single Ethereum transaction**.

Timeline:

```text
Transfer Tokens

↓

Execute Every Swap

↓

Measure Recipient Balance

↓

require()

↓

Success
OR
Revert Entire Transaction
```

If this `require()` fails:

```text
Everything

↓

Reverts
```

That includes:

- Every token transfer.
- Every Pair swap.
- Every reserve update.
- Every state change.

The blockchain behaves as if the transaction never happened.

---

# Biggest Realization

The normal Router protects users by verifying a **prediction** before swapping.

```text
Predict Output

↓

Check amountOutMin

↓

Execute Swap
```

This Router cannot do that.

Instead it protects users by verifying the **actual result**.

```text
Transfer

↓

Swap

↓

Measure Actual Output

↓

Check amountOutMin

↓

Success / Revert
```

Fee-on-transfer tokens make accurate prediction impossible before transfers occur, so this Router verifies reality instead.

---

# Function Complete ✅

At this point:

- The input tokens have been transferred.
- The Pair's actual received input has been measured.
- Every swap has executed.
- The recipient's actual received output has been measured.
- The minimum output guarantee has been verified.

If the check passes, the transaction completes successfully.

If it fails, the EVM reverts the **entire transaction**, restoring the blockchain to the exact state it was in before the swap began.