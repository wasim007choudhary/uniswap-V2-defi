# Part 4 — Arbitrage Using Flash Swaps

> **Prerequisite**
>
> Before continuing, you should already understand **Uniswap V2 Flash Swaps**.
>
> 📖 **Reference:** ***[ notes/Core/FlashSwapAndAtomicTransaction ]***
>
> In our Flash Swaps chapter, we thoroughly dissected:
>
> * Why `swap()` sends tokens before receiving payment.
> * How the `uniswapV2Call()` callback works.
> * Why atomic transactions make Flash Swaps safe.
> * How repayment is verified.
> * Flash Swap fees.
> * Internal Pair contract implementation.
>
> This chapter **will not repeat those concepts**.
>
> Instead, we'll briefly refresh the core idea of Flash Swaps and then focus on **how Flash Swaps are used to perform arbitrage**.

---

# Why Do We Even Need Flash Swaps?

In the previous chapter, we performed arbitrage using **our own capital**.

The process looked like this:

```text
3000 DAI

↓

Buy WETH

↓

Sell WETH

↓

3100 DAI
```

This works perfectly...

**if you already own the 3000 DAI.**

But imagine the opportunity is much larger.

Suppose an arbitrage opportunity requires:

```text
250,000 DAI
```

Yet your wallet only contains:

```text
500 DAI
```

You immediately recognize the opportunity.

You know exactly how to profit from it.

Yet you cannot execute it because you simply don't have enough capital.

This is the biggest limitation of traditional arbitrage.

Your profits are limited by **how much money you already own.**

---

# The Simple Idea Behind Flash Swaps

Flash Swaps remove this limitation.

Instead of saying:

> **"I don't have enough money to start."**

Flash Swaps allow you to say:

> **"I'll temporarily borrow the money, execute the arbitrage, repay everything, and keep whatever remains."**

Notice something important.

The arbitrage strategy itself **does not change.**

The only thing that changes is **where the starting capital comes from.**

---

# A Child-Friendly Analogy

Imagine your friend owns a bicycle.

Normally the conversation would be:

> **You:** "Can I use your bicycle?"

> **Friend:** "Pay me first."

That is similar to a normal swap.

You pay first.

Then you receive the asset.

Now imagine your friend trusts you.

Instead, they say:

> **"Take the bicycle now. Use it however you want. Just return it before sunset."**

You:

* borrow the bicycle,
* deliver food,
* earn money,
* return the bicycle,
* keep the delivery earnings.

Everyone wins.

The only rule is:

> **The bicycle must be returned before sunset.**

If you fail,

pretend the day never happened.

You never borrowed the bicycle.

You never earned any money.

Everything returns to exactly how it was before.

That is surprisingly close to how a Flash Swap works.

---

# Translating the Analogy

| Real World        | Uniswap Flash Swap |
| ----------------- | ------------------ |
| Friend            | Uniswap Pair       |
| Bicycle           | Borrowed Tokens    |
| Deliver Food      | Execute Arbitrage  |
| Return Bicycle    | Repay Flash Swap   |
| Delivery Earnings | Arbitrage Profit   |

---

# The Most Important Difference

With a normal swap:

```text
You

↓

Pay Tokens

↓

Receive Tokens
```

With a Flash Swap:

```text
You

↓

Receive Tokens

↓

Use Them

↓

Repay Later
```

Notice that the order is completely reversed.

Instead of:

> **Pay → Receive**

the order becomes:

> **Receive → Use → Repay**

This single difference is what makes Flash Swaps so powerful.

---

# Why Doesn't Everyone Just Steal the Tokens?

This is probably the first question every developer asks.

> **"If Uniswap gives me the tokens first, why don't I simply keep them?"**

Because Ethereum transactions are **atomic**.

An atomic transaction has only two possible outcomes.

## Success

```text
Borrow Tokens

↓

Execute Arbitrage

↓

Repay Pair

↓

Transaction Succeeds
```

Everything becomes permanent.

---

## Failure

```text
Borrow Tokens

↓

Execute Arbitrage

↓

Cannot Repay

↓

Transaction Reverts
```

When a transaction reverts:

* every transfer is reversed,
* every storage change disappears,
* every balance returns to its previous value,
* every intermediate state is discarded.

It is literally as though the borrowing never happened.

This guarantee allows Uniswap to safely send tokens before receiving payment.

---

# Using Flash Swaps for Arbitrage

Now suppose we observe the following prices.

| Exchange  | Price of 1 WETH |
| --------- | --------------: |
| Uniswap   |    **3000 DAI** |
| SushiSwap |    **3100 DAI** |

Immediately we identify an arbitrage opportunity.

The problem?

Our wallet contains:

```text
0 DAI
```

With traditional arbitrage,

the opportunity is useless.

We cannot even execute the first trade.

Flash Swaps solve this problem.

Instead of using our own money,

we temporarily borrow the required funds directly from a Uniswap Pair.

The overall flow becomes:

```text
Borrow Tokens

↓

Execute Arbitrage

↓

Receive More Tokens

↓

Repay Borrowed Amount + Flash Swap Fee

↓

Keep Remaining Profit
```

The Pair temporarily provides the capital required to execute the trade.

---

# Notice What Didn't Change

This is a subtle but very important observation.

The **arbitrage itself** is exactly the same.

We still:

* buy where the asset is cheaper,
* sell where the asset is more expensive,
* keep the difference.

The only difference is the source of the initial funds.

Traditional arbitrage begins with:

```text
Your Wallet
```

Flash Swap arbitrage begins with:

```text
Uniswap Pair
```

Everything else remains identical.

---

# Flash Swaps Are Not Magic

Many beginners misunderstand Flash Swaps.

They think:

> **"Flash Swaps generate free money."**

They don't.

Flash Swaps only provide **temporary liquidity**.

Suppose every exchange already has the exact same price.

Example:

| Exchange  |   WETH Price |
| --------- | -----------: |
| Uniswap   | **3000 DAI** |
| SushiSwap | **3000 DAI** |

There is no arbitrage opportunity.

Borrowing funds changes nothing.

You still cannot make a profit.

Flash Swaps do **not** create opportunities.

They simply make existing opportunities accessible without requiring upfront capital.

---

# The Big Picture

Traditional Arbitrage

```text
Need Your Own Capital

↓

Execute Arbitrage

↓

Earn Profit
```

Flash Swap Arbitrage

```text
Borrow Capital

↓

Execute Arbitrage

↓

Repay Borrowed Capital

↓

Keep Remaining Profit
```

The trading strategy is identical.

Only the funding mechanism changes.

---

# Key Takeaways

* Flash Swaps solve the biggest limitation of traditional arbitrage: **the need for starting capital.**
* The Pair temporarily lends you the required liquidity.
* You must repay the borrowed amount (plus the required fee) before the transaction finishes.
* If repayment fails, the entire transaction reverts as though nothing happened.
* Flash Swaps do **not** create arbitrage opportunities—they simply allow you to execute existing opportunities without owning the initial funds.
* The arbitrage strategy itself never changes; only the source of the starting capital changes.

---

# What's Next?

Now that we understand **why Flash Swaps are useful for arbitrage**, the next section explores the **two different ways** to perform Flash Swap arbitrage in Uniswap V2.

Although both approaches achieve the same goal, they differ in **which asset is borrowed first** and **how the borrowed amount is ultimately repaid**.
