# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

> **Status:** Part 1
> **Topic:** Why TWAP Exists + Understanding `Pᵢ`

---

# Introduction

Before learning **how Uniswap V2 calculates TWAP**, we first need to answer a much more important question:

> **Why does TWAP exist in the first place?**

Many developers immediately jump into equations like:

```text
P₀
P₁
ΔT
Σ
```

and start memorizing formulas.

That approach usually leads to confusion.

Instead, we'll derive every equation from first principles so that, by the end, the formulas feel obvious rather than something to memorize.

---

# The Problem

Imagine a Uniswap V2 Pair.

Suppose its reserves are:

```text
DAI  = 2,000,000
ETH  = 1,000
```

Current spot price:

```text
2,000,000 / 1,000

=

2,000 DAI per ETH
```

Everything looks normal.

---

Now imagine someone performs a huge swap.

New reserves become approximately:

```text
DAI = 12,000,000

ETH = 168
```

The spot price suddenly becomes

```text
≈ 71,428 DAI per ETH
```

Question:

> Did ETH suddenly become worth **71,428 DAI**?

Of course not.

Nothing magical happened to ETH.

Only the reserves inside this single liquidity pool changed.

---

# The Problem With Spot Price

The Pair only knows one thing:

```text
Current reserves.
```

From those reserves it calculates:

```text
Current Price
=
ReserveY
/
ReserveX
```

This is called the **Spot Price**.

Spot price simply answers:

> **"If I asked right now, what would the price be?"**

The problem is that **"right now" can be manipulated.**

---

# Timeline Example

Imagine the following sequence.

```text
Time 0

Price = 2,000
```

↓

A whale performs a huge swap.

↓

```text
Time 1

Price = 71,428
```

↓

Arbitrage traders restore the pool.

↓

```text
Time 2

Price = 2,003
```

Question:

Which one is the "real" market price?

```text
2,000 ?

71,428 ?

2,003 ?
```

Obviously not the manipulated one.

---

# Child Analogy

Imagine you're measuring today's temperature.

At

```text
9:00 AM

20°C
```

Someone places a lighter under the thermometer.

Now:

```text
120°C
```

One minute later they remove it.

Temperature returns to

```text
20°C
```

Would you tell someone:

> Today's temperature was **120°C**?

No.

Because that abnormal temperature only existed briefly.

Instead you'd say:

> Let's average the temperature over a longer period.

That is exactly what TWAP does.

---

# TWAP Asks A Different Question

Spot Price asks:

```text
"What is the price right now?"
```

TWAP asks:

```text
"What has the average price been over the last X minutes?"
```

Notice the difference.

TWAP doesn't care about one brief spike.

It cares about **how long prices existed.**

---

# Understanding `P`

The documentation introduces this notation:

```text
P₀

P₁

P₂

...

Pₙ
```

This looks intimidating.

It isn't.

The letter

```text
P
```

simply means

```text
Price
```

Exactly like writing:

```solidity
uint256 price;
```

Mathematicians simply shorten it to

```text
P
```

---

# What Does The Small Number Mean?

The tiny number underneath is called an **index**.

It answers one question:

> **Which price?**

For example

```text
P₀
```

means

```text
Price at observation 0.
```

---

```text
P₁
```

means

```text
Price at observation 1.
```

---

```text
P₂
```

means

```text
Price at observation 2.
```

---

## Programmer Mental Model

Think of:

```text
P₀
P₁
P₂
```

as

```solidity
prices[0]

prices[1]

prices[2]
```

Exactly the same thing.

The only difference is notation.

---

# Example

Suppose every minute we record ETH price.

Minute 0

```text
ETH = 2,000
```

becomes

```text
P₀ = 2,000
```

---

One minute later

```text
ETH = 2,010
```

becomes

```text
P₁ = 2,010
```

---

Another minute

```text
ETH = 1,995
```

becomes

```text
P₂ = 1,995
```

Nothing complicated.

These are simply snapshots of the price over time.

---

# Understanding

```text
Pᵢ = Y / X
```

The documentation writes

```text
Pᵢ = Y / X
```

Let's decode every symbol.

---

## P

Means

```text
Price
```

---

## i

Means

```text
Current observation number.
```

It could be

```text
0

1

2

...

100
```

---

## Y

Reserve of Token Y.

Example:

```text
DAI
```

---

## X

Reserve of Token X.

Example:

```text
ETH
```

---

So

```text
Pᵢ = Y / X
```

simply means

```text
Current Price

=

Reserve of Token Y

/

Reserve of Token X
```

---

# Example

Suppose

```text
DAI Reserve

=

4,000,000
```

ETH Reserve

```text
2,000
```

Price

```text
4,000,000

/

2,000

=

2,000
```

Therefore

```text
Pᵢ

=

2,000 DAI per ETH
```

---

# Why Does Uniswap Use Reserves?

Because the Pair knows nothing else.

It doesn't ask:

```text
CoinGecko

Binance

Chainlink
```

It only knows

```text
How much Token0 do I own?

How much Token1 do I own?
```

The ratio of those reserves **is** the spot price.

---

# Mental Model

Whenever you see

```text
P₀
```

read

> Price at observation 0.

Whenever you see

```text
P₁
```

read

> Price at observation 1.

Whenever you see

```text
Pᵢ
```

read

> Price at observation i.

Whenever you see

```text
Pᵢ = Y / X
```

read

> Current price equals ReserveY divided by ReserveX.

---

# Questions We Asked During Learning

## Question

**"If the price changes from 10 to 20 at exactly 5:05, what is the price at 5:05?"**

### Answer

The price changes **instantly**, not gradually.

Timeline:

```text
5:00 ---------------------- 5:05 ---------------------- 5:10

Price = 10                 Swap Happens               Price = 20
```

There are **no intermediate prices** like:

```text
11

12

13

...

19
```

The reserves change atomically, so the price changes atomically.

---

## Child Analogy

Imagine a classroom.

Initially:

```text
10 boys

10 girls
```

Ratio:

```text
1 : 1
```

The bell rings.

All 10 boys leave.

The ratio becomes:

```text
0 : 10
```

Did the ratio gradually change?

No.

It changed immediately the moment the students left.

That is exactly how Uniswap reserves work.

---

# Key Takeaways

* Spot price uses the **current reserves only**.
* Spot price can be manipulated for a short period.
* TWAP exists to reduce the influence of those short-lived manipulations.
* `P` simply means **Price**.
* The subscript (`₀`, `₁`, `₂`, `ᵢ`) is just an index, similar to an array index in programming.
* Reserve ratios determine the spot price.
* Price changes are **instantaneous**, not gradual, because reserve updates happen atomically during a swap.

---

> **Next Part:** Understanding `Tᵢ`, `Tᵢ₊₁`, why prices are valid over intervals, why `[Tᵢ, Tᵢ₊₁)` is used, why smart contracts don't continuously update prices, and every discussion we had around timestamps and intervals.
