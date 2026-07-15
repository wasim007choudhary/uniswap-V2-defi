# Part 5 — Two Ways to Perform Flash Swap Arbitrage

In the previous section, we learned that Flash Swaps solve the biggest limitation of traditional arbitrage:

> **We no longer need our own starting capital.**

Instead, a Uniswap Pair temporarily provides the liquidity required to execute the trade.

Now another interesting question arises.

> **Which Pair should we borrow from?**

Surprisingly, there isn't only one answer.

There are **two different approaches**.

The arbitrage itself never changes.

We still:

1. Buy where the asset is cheaper.
2. Sell where the asset is more expensive.
3. Keep the remaining profit.

The only thing that changes is **where the temporary liquidity comes from.**

---

# Method 1 — Borrow From Another Pair

This is the approach introduced first in the course because it is conceptually easier.

Suppose we observe:

| Exchange  | Price of WETH |
| --------- | ------------: |
| Uniswap   |  **3000 DAI** |
| SushiSwap |  **3100 DAI** |

We need DAI to purchase WETH.

But we don't own any.

Instead of using our own wallet, we temporarily borrow DAI from another Pair.

For example:

```text id="ib8aaj"
DAI/MKR Pair
```

Notice something extremely important.

The DAI/MKR Pair is **not** part of the arbitrage opportunity.

It doesn't have a cheaper or more expensive WETH price.

It simply happens to own a lot of DAI.

It is acting purely as our lender.

---

## Complete Flow

```text id="yrzdcj"
DAI/MKR Pair
      │
Borrow DAI
      │
      ▼
Buy WETH on Uniswap
      │
      ▼
Sell WETH on SushiSwap
      │
      ▼
Receive More DAI
      │
      ▼
Repay DAI/MKR Pair
      │
      ▼
Keep Remaining DAI
```

Notice how every participant has a separate role.

```text id="6p1rl5"
DAI/MKR Pair

↓

Temporary Lender
```

```text id="g78kwo"
Uniswap DAI/WETH

↓

Cheaper Market
```

```text id="mdgrlz"
SushiSwap DAI/WETH

↓

Expensive Market
```

Everything is nicely separated.

---

# Thinking About It Differently

This is exactly like borrowing money from a friend.

Your friend says:

> "Here's ₹50,000. Return it this evening."

You then:

* buy something cheap,
* sell it for more,
* repay your friend,
* keep the remaining money.

Your friend isn't involved in your business.

They're simply financing it.

The DAI/MKR Pair plays exactly the same role.

---

# But Then We Asked...

While studying this, a natural question came up.

> **"If the cheaper Pair itself already has the tokens I need... why am I borrowing from some completely different Pair?"**

For example:

Suppose **Uniswap DAI/WETH** is already the cheaper market.

Instead of doing this:

```text id="plzhug"
Borrow From

DAI/MKR Pair
```

Why not simply borrow directly from:

```text id="3s1mgi"
Uniswap DAI/WETH
```

After all...

We're already going to interact with that Pair anyway.

Wouldn't that be a shortcut?

The answer is:

> **Yes.**

And that's exactly what the second method does.

---

# Method 2 — Borrow Directly From the Arbitrage Pair

Instead of introducing another lending Pair,

the arbitrage Pair itself becomes our lender.

The Pair now performs **two jobs simultaneously**.

It is:

* the cheaper market,
* and the temporary lender.

The flow becomes much simpler.

```text id="g0ynuh"
Uniswap DAI/WETH
         │
Borrow WETH
         │
         ▼
Sell WETH on SushiSwap
         │
         ▼
Receive DAI
         │
         ▼
Repay Uniswap Pair
         │
         ▼
Keep Remaining DAI
```

Notice what disappeared.

The DAI/MKR Pair.

We removed an entire participant from the process.

This is exactly the intuition we arrived at during our discussion.

Instead of borrowing from another Pair,

we simply let the arbitrage Pair finance the trade itself.

---

# Another Interesting Question

At this point another question naturally arises.

> **"If I'm borrowing directly from the arbitrage Pair... why do I borrow WETH instead of DAI?"**

Initially, it feels like borrowing DAI should also work.

Suppose we tried:

```text id="jlwm9d"
Borrow DAI

↓

Buy WETH

↓

Sell WETH

↓

Repay DAI
```

This can work **only if our arbitrage naturally ends with DAI.**

Otherwise,

if we finish holding WETH,

we now need:

```text id="jlwm9f"
Swap WETH

↓

Receive DAI

↓

Repay Pair
```

That introduces:

* another swap,
* another swap fee,
* additional gas,
* lower overall profit.

---

# Why Borrow WETH Instead?

This becomes much easier to understand once we remember what a Flash Swap really is.

A normal swap is:

```text id="jlwm9g"
Pay DAI

↓

Receive WETH
```

A Flash Swap simply reverses the order.

```text id="jlwm9h"
Receive WETH

↓

Pay DAI Later
```

You're still performing exactly the same swap.

The payment is simply delayed until the callback.

Borrowing WETH therefore aligns naturally with how the Pair already expects swaps to work.

---

# The Big Realization

Initially these two methods appear completely different.

But after stepping back,

they are actually solving the exact same problem.

Method 1 says:

```text id="jlwm9i"
I need capital.

I'll borrow it from another Pair.
```

Method 2 says:

```text id="jlwm9j"
I'm already interacting with this Pair.

Why not let THIS Pair provide the capital?
```

Method 2 is essentially an optimization.

Instead of introducing another lender,

we simply reuse the Pair we're already arbitraging.

That was the biggest conceptual insight we reached during this discussion.

---

# Visual Comparison

## Method 1

```text id="jlwm9k"
DAI/MKR Pair

↓

Provides Capital

↓

Uniswap

↓

SushiSwap

↓

Repay DAI/MKR

↓

Profit
```

---

## Method 2

```text id="jlwm9l"
Uniswap Pair

↓

Provides Capital

↓

SushiSwap

↓

Repay Uniswap

↓

Profit
```

Same arbitrage.

One fewer participant.

A cleaner execution flow.

---

# Key Takeaways

* Both methods execute the **same arbitrage strategy**.
* The only difference is where the temporary liquidity comes from.
* Method 1 borrows from an unrelated Pair that simply acts as a lender.
* Method 2 realizes that if the arbitrage Pair already has the liquidity we need, it can act as both the lender and the cheaper market.
* Borrowing directly from the arbitrage Pair removes an extra participant and often results in a cleaner execution flow.
* Borrowing WETH directly also aligns naturally with the Flash Swap model of **receive first, pay later**, avoiding unnecessary conversions in many scenarios.
