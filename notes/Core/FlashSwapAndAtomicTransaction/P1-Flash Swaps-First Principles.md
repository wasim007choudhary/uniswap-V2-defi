# 1. Flash Swaps — First Principles
>For swap dissection visit **[notes/Core/UV2Pair--swap.md]** Here we will only dissect the code lines and conceopts FlashSwap and such!


## First Thought

When most developers first hear the term **Flash Swap**, they immediately imagine that Uniswap must have another function called:

```solidity
flashSwap(...)
```

or perhaps another contract dedicated to lending tokens.

After all, borrowing millions of dollars sounds like a completely different operation from performing a normal token swap.

Surprisingly...

Neither is true.

Uniswap V2 does **not** have a `flashSwap()` function.

Instead, flash swaps are simply another mode of the existing `swap()` function.

That naturally raises a much bigger question.

---

# The Impossible Question

Imagine I own a shop.

You walk in and ask:

> "Can I borrow $1,000,000?"

I ask:

> "When will you pay me back?"

You answer:

> "About three seconds."

Every sane shop owner would immediately reply:

> "Absolutely not."

Yet this is exactly what Uniswap appears to do.

It willingly sends you millions of dollars worth of tokens **before receiving any payment.**

How can that possibly be safe?

---

# Wait...

Doesn't Uniswap Always Take Payment First?

Throughout the rest of the protocol we've learned something important.

The Pair contract always protects itself.

Naturally, we would expect the execution flow to look something like this:

```text
Receive Tokens

↓

Verify Payment

↓

Send Tokens Out
```

At least that's what intuition tells us.

However, inside `swap()`, something very strange happens.

The execution order is actually closer to:

```text
Transfer Tokens Out

↓

???

↓

Read Final Balances

↓

Verify Invariant

↓

Finish
```

Notice something shocking.

The Pair sends the tokens **before** verifying that it has been repaid.

At first glance...

this looks incredibly dangerous.

---

# Child Analogy

Imagine your teacher says:

> "Take my laptop home."

> "Finish your homework."

> "Bring it back before class ends."

Not tomorrow.

Not next week.

Before today's class finishes.

If you fail to return it before the bell rings...

it's as though you never borrowed it at all.

Flash swaps work in almost exactly the same way.

---

# The Secret

The reason this is possible has nothing to do with Uniswap itself.

It has everything to do with Ethereum.

Ethereum transactions are **atomic**.

This single property is what makes flash swaps possible.

Without atomic transactions...

Flash swaps simply could not exist.

---

# What Does "Atomic" Mean?

An atomic transaction means:

> **Everything succeeds, or nothing happens.**

There is no middle ground.

Imagine a transaction performing ten different operations.

```text
Operation 1 ✅

↓

Operation 2 ✅

↓

Operation 3 ✅

↓

Operation 4 ❌
```

The moment Operation 4 fails...

Ethereum does **not** keep Operations 1, 2, and 3.

Instead, everything is rolled back.

```text
Operation 1 ❌

Operation 2 ❌

Operation 3 ❌

Operation 4 ❌
```

It is exactly as though the transaction never happened.

---

# Another Child Analogy

Imagine writing an essay with a pencil.

You write ten sentences.

Your teacher says:

> "If sentence number ten is wrong..."

she erases the **entire page.**

Not just sentence ten.

Everything disappears.

Ethereum behaves in exactly the same way.

---

# Why This Changes Everything

Now imagine Uniswap says:

> "I'll send you 1,000 ETH right now."

You receive the ETH.

You then perform whatever work you need:

* Arbitrage
* Liquidations
* Debt refinancing
* Cross-protocol swaps
* Or anything else

Finally...

you repay the Pair.

If repayment succeeds:

```text
Entire Transaction Commits ✅
```

If repayment fails:

```text
Entire Transaction Reverts ❌
```

The borrowed ETH disappears.

Your arbitrage disappears.

Your profits disappear.

Even the original transfer from the Pair disappears.

From Ethereum's perspective, it is as though the flash swap never happened.

---

# The Biggest Mental Model

A flash swap is **not**:

```text
Borrow Today

↓

Repay Tomorrow
```

Instead, it is:

```text
Borrow

↓

Use The Funds

↓

Repay

↓

Transaction Ends
```

There is never a point where the borrower owns the funds across multiple transactions.

Everything must begin and end inside **one single Ethereum transaction.**

---

# Final Realization

Flash swaps initially appear impossible because they seem to violate one of the oldest rules in finance:

> **"Nobody gives away money before getting paid."**

The trick is that Uniswap is **not trusting the borrower.**

Instead...

Uniswap is trusting the guarantees provided by the Ethereum Virtual Machine.

The EVM guarantees that if the borrowed funds are **not** returned before the transaction finishes, the **entire transaction is reverted.**

From the Pair's perspective, there are only two possible outcomes.

```text
Borrow

↓

Repay

↓

Transaction Succeeds ✅
```

or

```text
Borrow

↓

Fail To Repay

↓

Entire Transaction Reverts

↓

As If Nothing Ever Happened ❌
```

That single guarantee is the foundation upon which the entire flash swap mechanism is built.

Everything else we will learn throughout this chapter builds on that one idea.
