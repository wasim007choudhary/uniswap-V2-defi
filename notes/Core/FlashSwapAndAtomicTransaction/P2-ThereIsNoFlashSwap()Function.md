# 2. There Is No `flashSwap()` Function

## First Thought

After learning that flash swaps are possible because Ethereum transactions are atomic, the next natural question is:

> **"Where is the `flashSwap()` function?"**

Most developers expect to find something like:

```solidity
function flashSwap(...) external {}
```

or perhaps:

```solidity
function borrow(...) external {}
```

After all, borrowing millions of dollars sounds like a completely different operation from swapping tokens.

Surprisingly...

Neither exists.

---

# There Is Only One Function

Inside `UniswapV2Pair.sol`, there is only one function responsible for both operations.

```solidity
swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
)
```

This single function performs both:

```text
Normal Swap

AND

Flash Swap
```

At first glance, that sounds impossible.

How can one function perform two completely different jobs?

---

# The Hidden Switch

The answer is hidden in a single condition inside `swap()`.

```solidity
if (data.length > 0) {
    IUniswapV2Callee(to).uniswapV2Call(
        msg.sender,
        amount0Out,
        amount1Out,
        data
    );
}
```

This tiny `if` statement completely changes the behavior of the function.

Think of it as a hidden switch.

```text
swap()

↓

Is data empty?

↓

YES ----------------→ Normal Swap

↓

NO -----------------→ Flash Swap
```

Everything depends on one thing.

```text
data.length
```

---

# Normal Swap

Suppose the Router performs a regular swap.

It calls:

```solidity
pair.swap(
    amount0Out,
    amount1Out,
    receiver,
    ""
);
```

Notice that the last argument is empty.

```text
data = ""
```

Therefore,

```solidity
if (data.length > 0)
```

evaluates to:

```text
FALSE
```

The callback is skipped entirely.

Execution simply continues.

```text
Transfer Tokens

↓

Read Final Balances

↓

Verify K Invariant

↓

Update Reserves

↓

Done
```

Nothing unusual happens.

This is an ordinary Uniswap swap.

---

# Flash Swap

Now imagine another contract calls:

```solidity
pair.swap(
    amount0Out,
    amount1Out,
    address(this),
    abi.encode(...)
);
```

This time,

```text
data ≠ empty
```

So the condition becomes true.

Immediately, the Pair executes:

```solidity
IUniswapV2Callee(to).uniswapV2Call(...)
```

That single callback transforms the swap into a flash swap.

Notice something interesting.

There is still no dedicated flash swap function.

The exact same `swap()` function simply takes a different execution path because `data` is no longer empty.

---

# Wait...

Notice the execution order carefully.

The Pair performs the following steps:

```text
Transfer Tokens Out

↓

Call Borrower's Contract

↓

Borrower Executes Any Logic

↓

Read Final Balances

↓

Verify K Invariant

↓

Success / Revert
```

The borrower receives the tokens **before** Uniswap checks whether it has been repaid.

This is the opposite of how almost every traditional financial system works.

---

# Child Analogy

Imagine your teacher says:

> "Here's the science lab key."

> "Go perform your experiment."

> "When you're finished, come back."

Only after you return does the teacher inspect the laboratory to make sure everything is still there.

The teacher doesn't continuously watch what you're doing.

She only cares about the final result.

Uniswap behaves in almost exactly the same way.

It sends the tokens first.

Then it waits.

Only after your contract finishes executing does it inspect its balances.

---

# The Most Important Realization

Many developers believe the callback exists **to repay the loan.**

That isn't actually its purpose.

The callback exists to give your contract an opportunity to perform **any arbitrary logic** before the Pair verifies repayment.

During that callback, your contract can:

* Perform arbitrage.
* Liquidate a lending position.
* Refinance debt.
* Interact with multiple DeFi protocols.
* Execute dozens of smart contract calls.
* Or perform any other computation.

Uniswap doesn't care what you do.

It only cares about one thing.

> **"When control returns to me, does my invariant still hold?"**

---

# The Pair Never Asks...

Notice what the Pair never checks.

It never asks:

```text
Did you perform arbitrage?

Did you make a profit?

Did you interact with Aave?

Did you use another DEX?
```

Instead, it asks only one question.

```text
After everything is finished...

Do I still have enough tokens?
```

If the answer is:

```text
YES
```

the transaction succeeds.

If the answer is:

```text
NO
```

the entire transaction reverts.

---

# Final Mental Model

A flash swap is **not** a separate feature.

It is simply the normal `swap()` function taking a different execution path.

```text
swap()

↓

Is data empty?

↓

YES ─────────► Normal Swap

↓

NO ──────────► Callback Executed

↓

Borrower Executes Logic

↓

Pair Verifies Repayment

↓

Flash Swap Complete
```

The callback creates a temporary window between:

```text
Tokens Leave The Pair

↓

Borrower Executes Logic

↓

Pair Verifies Repayment
```

That small window is what makes flash swaps possible.

Without the callback, `swap()` would always behave like a normal token swap.

With the callback, the exact same function becomes one of the most powerful primitives in decentralized finance.
