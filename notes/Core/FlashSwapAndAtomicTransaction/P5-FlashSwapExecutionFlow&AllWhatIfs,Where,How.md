# Topic 5 - Flash Swap Execution Flow

Now that we understand why `bytes data` exists, let's follow the entire flash swap execution step by step.

Understanding this flow is far more important than memorizing the code because once you understand **who calls whom** and **when the checks happen**, the entire flash swap mechanism becomes intuitive.

---

# Step 1 - User Starts the Flash Swap

The user calls **your contract**.

```text
Alice

↓

Your Contract

flashSwap()
```

> **Note:** `flashSwap()` is just an example name. It is **not** a special Solidity or Uniswap function. You can name it anything you like (`execute()`, `startArbitrage()`, `target()`, etc.).

Inside this function, your contract decides things like:

* Which Pair to borrow from.
* Which token to borrow.
* How much to borrow.
* Any arbitrage parameters.
* Any callback data.

At this point:

**No tokens have been borrowed yet.**

---

# Step 2 - Prepare The Swap

Your contract determines which token should be borrowed.

```solidity
amount0Out
amount1Out
```

Depending on whether you are borrowing `token0` or `token1`.

It also prepares:

```solidity
bytes memory data = abi.encode(...);
```

if it needs to send information to the callback later.

---

# Step 3 - Call The Pair

Your contract now calls:

```solidity
pair.swap(
    amount0Out,
    amount1Out,
    address(this),
    data
);
```

At this exact moment...

Control leaves your contract.

The EVM now starts executing the Pair contract's `swap()` function.

---

# Step 4 - The Pair Sends The Tokens First

One of the most surprising parts of Uniswap V2 is that it sends the borrowed tokens **before** checking whether you have repaid them.

```text
Pair

↓

Send Tokens

↓

Callback

↓

Verify Repayment
```

At first, this seems dangerous.

Why would Uniswap send assets before getting paid?

Because otherwise a flash swap would be impossible.

Imagine Uniswap required:

```text
Pay First

↓

Receive Tokens
```

That would defeat the entire purpose.

A flash swap exists because we **don't already own** the tokens.

We need to borrow them first so we can perform arbitrage, liquidation, refinancing, or any other custom logic.

Therefore, the Pair must first do:

```text
Borrow Tokens

↓

Use Them

↓

Repay

↓

Finish Swap
```

Without borrowing first, flash swaps could never exist.

---

# Where Is The Promise To Repay?

Many beginners think there must be some agreement between both contracts.

Something like:

```text
"I promise to repay."
```

There isn't.

There is:

* ❌ No signature
* ❌ No agreement
* ❌ No promise
* ❌ No handshake
* ❌ No phone call

Our contract simply calls:

```solidity
pair.swap(...);
```

The Pair immediately sends the tokens.

Instead of trusting us, the Pair follows a much simpler philosophy:

> **Don't Trust. Verify.**

The Pair never asks us whether we'll repay.

It simply verifies later whether we actually did.

---

# Step 5 - The Callback

After sending the tokens, the Pair executes:

```solidity
IUniswapV2Callee(to).uniswapV2Call(...);
```

The execution flow now becomes:

```text
Your Contract

flashSwap()

        │
        ▼
Pair.swap()

        │
        ▼
Pair Sends Tokens

        │
        ▼
Pair Calls

uniswapV2Call()

        │
        ▼
Your Contract Executes Callback
```

Notice something important.

The EVM **pauses** execution of `Pair.swap()`.

It then begins executing your callback.

This is just like a normal Solidity function call.

When your callback finishes, execution resumes inside `Pair.swap()` exactly where it paused.

The callback is **not** a new transaction.

It is simply another function call inside the same transaction.

---

# Step 6 - Perform Your Custom Logic

Inside `uniswapV2Call()` you may perform any custom logic you want.

For example:

* Arbitrage
* Liquidation
* Refinance debt
* Multi-hop swaps
* Any custom protocol interaction

This is the "flash" part of the flash swap.

After completing your logic, your contract must repay the Pair.

---

# Step 7 - Pair Resumes Execution

When your callback returns, execution immediately continues inside `Pair.swap()`.

The Pair now begins verifying everything.

For example:

```solidity
balance0 = IERC20(token0).balanceOf(address(this));
balance1 = IERC20(token1).balanceOf(address(this));
```

Then it calculates:

* Amount returned.
* Fees paid.
* Constant product invariant.

If everything is correct:

```text
Success

↓

_update()

↓

swap() returns

↓

Transaction committed
```

Otherwise:

```text
revert

↓

Entire transaction rolls back
```

---

## Important Discussion — Where Is the "Promise" to Repay?

A common misconception is that during a flash swap, our contract somehow promises the Pair that it will return the borrowed tokens.

In reality, **there is no promise at all.**

There is:

* ❌ No agreement
* ❌ No signature
* ❌ No handshake
* ❌ No phone call
* ❌ No "I promise to repay"

Our contract simply calls:

```solidity
pair.swap(...);
```

The Pair immediately sends the requested tokens.

It never asks us to promise anything.

Instead, the Pair follows a much simpler philosophy:

> **"I don't care what you promise. I'll verify the result myself."**

This is one of the core ideas behind blockchain systems:

> **Don't Trust. Verify.**

After the callback finishes, the Pair checks its own balances.

It calculates:

* How many tokens came back.
* Whether the required fee was paid.
* Whether the constant product invariant (`K`) still holds.

If every check passes:

```text
Success

↓

swap() returns

↓

Transaction is committed
```

If **any** check fails:

```text
revert

↓

Entire transaction rolls back
```

There is no trust involved.

The Pair only trusts mathematics and the final state of its own balances.

---

# Where Does the Revert Actually Happen?

Another important realization is that **the EVM does not automatically revert flash swaps**.

The Pair contract itself performs the checks.

For example:

```solidity
balance0 = IERC20(token0).balanceOf(address(this));
balance1 = IERC20(token1).balanceOf(address(this));
```

Then later:

```solidity
if (...) {
    revert;
}
```

The Pair decides:

> "The rules were broken."

Once the Pair executes:

```solidity
revert;
```

the EVM takes over and rolls back **every state change** that happened during the transaction.

So remember:

* **The Pair decides when to revert.**
* **The EVM performs the rollback.**

---

# Does the Pair Wait for Us?

Another common question is:

> **How long does the Pair wait for repayment?**

The answer is:

**It doesn't wait at all.**

There is:

* ❌ No timer
* ❌ No timeout
* ❌ No 5-second window
* ❌ No waiting until the next block

Instead, everything happens inside one continuous transaction.

Execution looks like this:

```text
Pair.swap()

↓

Send Tokens

↓

Call uniswapV2Call()

↓

Resume Pair.swap()

↓

Verify Balances

↓

Verify K

↓

Return or Revert
```

When the Pair calls our callback, the EVM temporarily pauses execution of `Pair.swap()`.

The EVM then starts executing our callback function.

Once our callback returns, the EVM immediately resumes `Pair.swap()` from the exact next line.

Therefore, the "time window" is **not measured in seconds**.

It lasts only until `swap()` finishes executing.

---

# What If Our Callback Never Returns?

Suppose we accidentally write:

```solidity
while (true) {

}
```

or create an endless chain of function calls.

Will the Pair wait forever?

No.

Every EVM instruction consumes gas.

Eventually:

```text
Gas = 0

↓

Out Of Gas

↓

revert

↓

Entire transaction rolls back
```

The Pair never resumes because the transaction fails before it can continue.

This is one of the reasons gas exists.

Besides paying validators, gas also prevents:

* Infinite loops
* Infinite recursion
* Contracts that never finish
* Denial-of-service attacks

---

# What If We Spend the Borrowed Tokens Before the Revert?

Another common thought is:

> "Suppose I borrow tokens, buy an NFT, transfer tokens to someone else, or perform other actions before the transaction eventually reverts."

Everything still rolls back.

Example:

```text
Borrow Tokens

↓

Buy NFT

↓

Transfer Tokens

↓

Swap Assets

↓

revert
```

Result:

```text
Borrow ❌

NFT Purchase ❌

Transfer ❌

Swap ❌
```

Every blockchain state change is undone.

It is as if the transaction never happened.

---

# Can We Cash Out Before the Revert?

What if we transfer tokens to another person and ask them to immediately hand us physical cash?

For example:

```text
Borrow Tokens

↓

Transfer Tokens To Bob

↓

Bob Gives Us Cash

↓

Transaction Reverts
```

Can we keep the cash?

A properly designed system won't allow this.

While the transaction is still executing, it is only:

```text
Pending
```

The blockchain has **not** committed the transfer yet.

Bob does **not** actually own those tokens.

Only after the entire transaction succeeds and is mined does the transfer become permanent.

If the transaction later reverts:

```text
Failed

↓

Transfer Never Happened
```

The only way Bob would lose money is if he ignored the pending status and trusted an unconfirmed transaction.

That would be a mistake by Bob, **not** an exploit of Ethereum or Uniswap.

---

# Final Mental Model

Think of every Ethereum transaction like working on a temporary draft.

```text
Start Transaction

↓

Temporary State Changes

↓

Borrow

↓

Trade

↓

Transfer

↓

Repay
```

Nothing becomes permanent yet.

At the very end:

If everything succeeds:

```text
Commit Changes ✅
```

If anything fails:

```text
Discard Everything ❌
```

The blockchain only "saves" the new state after the outermost transaction finishes successfully.

That atomic execution model is the foundation that makes flash swaps possible.
The Pair does not rely on promises.

It relies on mathematics, verification, and Ethereum's ability to roll back the entire transaction if any rule is violated.