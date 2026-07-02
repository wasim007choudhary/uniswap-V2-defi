# 6. Why Liquidity Requires Two Assets

## 🎯 Goal

Understand **why Uniswap V2 requires Liquidity Providers to deposit two different tokens** instead of allowing deposits of just one token.

> **Important**
>
> This is a purely conceptual chapter.
>
> There is **no mathematics** here.
>
> The objective is to understand the design decisions that naturally lead to the mathematical equations we'll derive in the next section.

---

# 📌 The Question We Left Unanswered

Everything we've learned so far assumed a simple pool containing only one asset.

For example:

```text
USDC Pool
```

In that world, everything was straightforward.

- We measured the pool's value using USDC.
- We minted Pool Shares.
- We burned Pool Shares.
- Ownership was easy to understand.

However, Uniswap V2 doesn't work like that.

Every liquidity pool always contains **two assets**.

Examples:

```text
ETH + USDC

WBTC + ETH

LINK + USDC
```

This immediately raises a question.

> **Why?**

Why can't Uniswap simply allow Liquidity Providers to deposit only one token?

For example:

```text
Only ETH

or

Only USDC
```

Why force users to provide both?

---

# 🤔 A Thought Experiment

Imagine a brand-new ETH/USDC pool.

Current reserves:

```text
100 ETH

100,000 USDC
```

The current price inside the pool is:

```text
1 ETH = 1,000 USDC
```

Now suppose Alice wants to provide liquidity.

Instead of depositing both assets, she deposits only:

```text
10 ETH
```

No USDC.

The pool now becomes:

```text
110 ETH

100,000 USDC
```

---

# ❓What Changed?

At first glance, it looks like Alice simply added more liquidity.

But something much more important happened.

The price changed.

Before:

```text
100,000 / 100

=

1,000 USDC per ETH
```

After:

```text
100,000 / 110

≈

909.09 USDC per ETH
```

ETH suddenly became **cheaper** inside this pool.

Nothing happened to ETH in the real world.

Alice accidentally changed the AMM's exchange rate simply by adding liquidity.

---

# 🧠 Biggest Realization

Adding liquidity should **not** change the market price.

Adding liquidity is supposed to:

- Increase the liquidity available for trading.
- Make large trades cause less slippage.

It is **not** supposed to:

- Reprice ETH.
- Move the market.
- Create arbitrage opportunities.

Yet depositing only ETH did exactly that.

---

# 🤔 How Could Alice Prevent This?

Alice still wants to add:

```text
10 ETH
```

The current pool is:

```text
100 ETH

100,000 USDC
```

Notice the ratio:

```text
100 ETH

:

100,000 USDC

=

1

:

1,000
```

To preserve this ratio, Alice must also deposit:

```text
10,000 USDC
```

The pool now becomes:

```text
110 ETH

110,000 USDC
```

Let's check the price.

Before:

```text
100,000 / 100

=

1,000
```

After:

```text
110,000 / 110

=

1,000
```

Nothing changed.

The pool simply became larger.

---

# 💡 The Key Idea

Adding liquidity should **scale the pool**, not change it.

Think of it like enlarging a photograph.

Everything becomes bigger.

Nothing becomes distorted.

The same principle applies here.

The reserves increase proportionally, so the exchange rate remains exactly the same.

---

# 🚨 What If Uniswap Allowed One-Token Deposits?

Suppose Alice deposits only:

```text
10 ETH
```

The pool now values ETH at:

```text
≈909 USDC
```

Meanwhile, every other exchange still values ETH at:

```text
1,000 USDC
```

An arbitrage trader immediately notices this.

He thinks:

> **"ETH is cheaper inside this Uniswap pool."**

So he:

1. Buys ETH from the Uniswap pool.
2. Sells it on another exchange.
3. Keeps the difference as profit.

As this happens:

- ETH leaves the pool.
- USDC enters the pool.

Eventually, the pool price returns to the true market price.

---

# 🤔 Where Did The Arbitrage Profit Come From?

Did the arbitrage trader create money?

No.

The profit came from Alice.

By depositing liquidity incorrectly, Alice unintentionally donated value to arbitrage traders.

---

# 🔄 The Reverse Situation

The exact same thing happens in reverse.

Suppose Alice deposits only:

```text
10,000 USDC
```

The pool becomes:

```text
100 ETH

110,000 USDC
```

The new price becomes:

```text
1 ETH = 1,100 USDC
```

Now ETH is **more expensive** inside this pool than everywhere else.

An arbitrage trader immediately notices.

This time, he:

1. Buys ETH on another exchange.
2. Sells it into the Uniswap pool.
3. Keeps the profit.

As this happens:

- ETH flows into the pool.
- USDC leaves the pool.

Eventually, the pool price once again returns to the true market price.

---

# 🧠 Another Huge Realization

Whether a Liquidity Provider deposits:

- Only ETH, or
- Only USDC,

the outcome is exactly the same.

They accidentally change the pool's price.

That creates an arbitrage opportunity.

The arbitrage trader profits.

The Liquidity Provider pays the cost.

---

# 🎯 The Real Purpose Of Adding Liquidity

Many beginners think:

> **Adding liquidity simply means adding more tokens to the pool.**

That isn't the real objective.

The true objective is:

> **Increase the amount of assets available for trading without changing the current exchange rate.**

Suppose the pool starts with:

```text
100 ETH

100,000 USDC
```

Now it doubles in size:

```text
200 ETH

200,000 USDC
```

The price remains:

```text
1 ETH = 1,000 USDC
```

Nothing changed about the market price.

However, something important improved.

The pool became **deeper**.

A deeper pool means:

- Large trades move the price less.
- Slippage decreases.
- Traders receive better execution.
- The market becomes more efficient.

This is the true purpose of liquidity.

---

# 🍎 Real-World Analogy

Imagine a grocery store.

Before restocking:

```text
100 Apples

100 Bananas
```

After restocking:

```text
200 Apples

200 Bananas
```

Did the owner suddenly decide apples are worth more?

No.

He simply increased the inventory.

Nothing about the exchange rate between apples and bananas changed.

Uniswap liquidity works exactly the same way.

Liquidity Providers increase the available inventory.

They do **not** determine the market price.

---

# ⚠️ Common Misconceptions

### ❌ Adding liquidity means changing the market price.

No.

Adding liquidity should only increase the pool's depth.

The price should remain unchanged.

---

### ❌ Liquidity Providers decide the price.

No.

The market determines the price.

Liquidity Providers join the market at the current price.

---

### ❌ Depositing only one token is harmless.

No.

Single-token deposits immediately change the reserve ratio.

That changes the pool price.

---

### ❌ Arbitrage traders are exploiting a bug.

No.

Arbitrage is the mechanism that restores the pool price to the true market price.

The mistake was introducing liquidity in the wrong ratio.

---

# 🧠 Biggest Realizations

- Uniswap pools always contain two assets.
- Adding liquidity should never change the exchange rate.
- Depositing only one token changes the reserve ratio.
- Changing the reserve ratio changes the price.
- Price changes immediately create arbitrage opportunities.
- Arbitrage profits come at the expense of the Liquidity Provider who disturbed the price.
- Liquidity Providers are not trying to set prices.
- Their job is to increase market depth while preserving the existing price.

---

# 🔗 Bridge To The Next Section

We now understand **why** liquidity must be added using **both assets**.

The next question is:

> **Exactly how much of the second token should be deposited to preserve the current price?**

That question leads directly to one of the most important equations in Uniswap V2:

```text
dy / dx = y / x
```

This equation is simply the mathematical expression of the idea we've just developed:

> **Add liquidity without changing the current exchange rate.**