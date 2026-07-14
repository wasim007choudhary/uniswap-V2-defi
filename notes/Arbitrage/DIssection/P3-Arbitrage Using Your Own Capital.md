# Part 3 — Arbitrage Using Your Own Capital

Now that we understand **what arbitrage is** and **why AMMs rely on it**, the next question is:

> **How does an arbitrageur actually execute an arbitrage trade?**

The simplest method is to use **your own funds**.

This is known as **capital-backed arbitrage** because you already possess the tokens required to initiate the first trade.

---

# The Setup

Assume we have two decentralized exchanges.

| Exchange  | Price of 1 WETH |
| --------- | --------------: |
| Uniswap   |    **3000 DAI** |
| SushiSwap |    **3100 DAI** |

Immediately we can see that:

* WETH is **cheaper** on Uniswap.
* WETH is **more expensive** on SushiSwap.

This creates an arbitrage opportunity.

The strategy is straightforward:

> **Buy WETH from Uniswap → Sell the same WETH on SushiSwap**

---

# What Capital Do We Need?

To buy WETH on Uniswap, we first need DAI.

Suppose we already own:

```text
3000 DAI
```

This DAI is our **starting capital**.

Unlike flash swaps or flash loans, nothing is borrowed.

Everything used in this arbitrage already belongs to us.

---

# Step 1 — Buy WETH on Uniswap

We use our DAI to purchase WETH.

```text
Spend:

3000 DAI

Receive:

1 WETH
```

Our portfolio changes from:

```text
3000 DAI
```

to

```text
1 WETH
```

Notice that our entire capital has now been converted into another asset.

---

# Step 2 — Sell WETH on SushiSwap

Now we immediately move to SushiSwap.

Since SushiSwap values WETH higher,

```text
1 WETH = 3100 DAI
```

we receive:

```text
3100 DAI
```

Our portfolio changes from:

```text
1 WETH
```

back to

```text
3100 DAI
```

We have now completed the arbitrage cycle.

---

# Complete Flow

```text
        Start

      3000 DAI
          │
          ▼
 Buy WETH on Uniswap
          │
          ▼
       1 WETH
          │
          ▼
 Sell WETH on SushiSwap
          │
          ▼
      3100 DAI
```

Notice something important.

We started with DAI.

We ended with DAI.

The WETH was merely a temporary asset that allowed us to exploit the pricing difference.

---

# Calculating the Profit

Ignoring every fee for a moment,

we started with:

```text
3000 DAI
```

and finished with:

```text
3100 DAI
```

Therefore,

```text
Profit

= DAI Received − DAI Spent

= 3100 − 3000

= 100 DAI
```

In reality, however, profit is never calculated this simply.

We must subtract every cost involved.

The actual formula becomes:

```text
Profit

=

Amount Received

− Amount Spent

− Swap Fees

− Gas Fees
```

If the result is positive,

the arbitrage is profitable.

If the result is negative,

the trade should never be executed.

---

# Why Does This Opportunity Disappear?

At first glance it looks like free money.

So why doesn't everyone keep repeating the same trade forever?

The answer lies in how AMMs work.

Suppose the Uniswap pool initially contains:

```text
300,000 DAI

100 WETH
```

Its implied price is:

```text
3000 DAI/WETH
```

When we buy WETH,

the reserves change.

For example:

```text
303,000 DAI

99 WETH
```

The pool now contains:

* more DAI
* less WETH

Since the reserve ratio changed,

the implied price automatically increases.

Buying WETH makes future WETH purchases more expensive.

---

# What Happens on SushiSwap?

The exact opposite.

Initially:

```text
310,000 DAI

100 WETH
```

We sell WETH into the pool.

After the swap,

the pool may contain something like:

```text
306,900 DAI

101 WETH
```

Now the reserve ratio changes in the opposite direction.

The SushiSwap price decreases.

Selling WETH makes future sales less profitable.

---

# One Trade Corrects Two Markets

This is one of the elegant aspects of arbitrage.

A single arbitrage transaction changes **both exchanges simultaneously**.

### On Uniswap

```text
Buy WETH

↓

DAI Reserve ↑

WETH Reserve ↓

↓

Price Goes Up
```

### On SushiSwap

```text
Sell WETH

↓

DAI Reserve ↓

WETH Reserve ↑

↓

Price Goes Down
```

One exchange becomes more expensive.

The other becomes cheaper.

The prices naturally move toward each other.

---

# When Does Arbitrage Stop?

Imagine many arbitrageurs performing the same strategy.

Eventually the prices become:

```text
Uniswap

3075 DAI
```

```text
SushiSwap

3078 DAI
```

Now the remaining difference is only:

```text
3 DAI
```

That difference is far too small.

Why?

Because every arbitrage must pay:

* swap fee on the first DEX,
* swap fee on the second DEX,
* blockchain gas fee,
* possible slippage.

The remaining spread no longer covers the execution costs.

At that point,

the arbitrage opportunity disappears.

This is why arbitrage opportunities usually exist only briefly.

---

# The Biggest Limitation of Capital Arbitrage

Everything we've discussed assumes one important condition.

We already own:

```text
3000 DAI
```

But what if we don't?

Suppose we identify an opportunity worth:

```text
100,000 DAI
```

Yet we only own:

```text
500 DAI
```

We cannot execute the trade.

The opportunity is effectively inaccessible because we lack sufficient capital.

This is the biggest limitation of traditional arbitrage.

**Your profit is limited by the capital you already own.**

---

# This Leads to Flash Swaps

Wouldn't it be amazing if we could temporarily borrow the required capital,

execute the arbitrage,

repay the borrowed amount,

and keep the remaining profit—

all within a single transaction?

That is exactly what **Uniswap V2 Flash Swaps** allow us to do.

Instead of needing our own funds,

we temporarily use the liquidity inside a Uniswap pair itself.

This removes the biggest limitation of traditional arbitrage.

---

# Key Takeaways

* Capital arbitrage uses your own tokens to execute the first trade.
* Buy the asset where it is cheaper and sell it where it is more expensive.
* Profit equals the value received minus all execution costs.
* Every arbitrage trade changes the reserves of both liquidity pools.
* These reserve changes naturally push prices toward equilibrium.
* Once the remaining price difference is smaller than fees and gas costs, the opportunity disappears.
* The major limitation of this approach is that it requires sufficient starting capital.
* Flash swaps solve this limitation by allowing capital to be borrowed and repaid within the same transaction.
