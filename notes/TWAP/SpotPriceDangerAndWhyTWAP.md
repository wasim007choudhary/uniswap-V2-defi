# Why You Should Never Use Uniswap V2 Spot Price as a Price Oracle

> **One of the biggest mistakes a DeFi protocol can make is trusting the current (spot) price from a Uniswap V2 Pair contract.**
>
> Spot prices can be manipulated within a single transaction, allowing attackers to borrow, liquidate, or purchase assets using fake prices.

---

# What is a Spot Price?

A **spot price** is simply:

> **The current price at this exact moment.**

For a Uniswap V2 Pair, the spot price comes directly from the current reserves.

Example:

```
DAI Reserve  = 2,000,000 DAI
WETH Reserve = 1,000 WETH
```

Price:

```
2,000,000 / 1,000

= 2,000 DAI per ETH
```

This is the **spot price**.

---

# The Problem

The spot price is **not permanent**.

It changes **every single swap**.

Suppose someone buys ETH.

Before:

```
2,000,000 DAI
1,000 WETH

Price

= 2,000 DAI / ETH
```

After a huge purchase:

```
12,000,000 DAI
168 WETH

Price

≈ 71,428 DAI / ETH
```

Nothing magical happened.

No news.

No real increase in ETH's market value.

Someone simply traded against the pool.

The Pair contract now honestly reports:

```
ETH = 71,428 DAI
```

because **that is the current reserve ratio**.

---

# Child Analogy

Imagine a fruit market.

Normally:

```
1 Apple = $2
```

A rich customer suddenly buys almost every apple.

Now only a few apples remain.

The shop owner says:

```
1 Apple = $50
```

Did apples suddenly become worth $50 everywhere?

No.

Only this shop's shelves are almost empty.

Uniswap works exactly the same way.

The reserves determine the price.

If reserves change dramatically, so does the spot price.

---

# How a Lending Protocol Can Be Exploited

Suppose a lending protocol says:

```
Deposit ETH

↓

Borrow DAI
```

To know how much DAI someone can borrow, it asks:

```
Uniswap Pair

"What is ETH worth?"
```

The Pair replies:

```
Current Spot Price:

71,000 DAI / ETH
```

The lending protocol trusts it.

This is the mistake.

---

# The Attack

Suppose the real market price is:

```
1 ETH = 2,000 DAI
```

The attacker has:

```
10,000,000 DAI
```

---

## Step 1 — Manipulate the Pool

Attacker buys almost all ETH.

```
10,000,000 DAI

↓

Buys 832 ETH
```

Pool reserves become heavily unbalanced.

Now the Pair reports:

```
1 ETH = 71,819 DAI
```

Notice:

The attacker **didn't make ETH more valuable.**

They only changed the reserves.

---

## Step 2 — Borrow Using the Fake Price

Attacker deposits:

```
100 ETH
```

Normally:

```
100 × 2,000

=

200,000 DAI
```

worth of collateral.

But the protocol asks Uniswap:

```
How much is ETH worth?
```

Uniswap says:

```
71,819 DAI
```

So protocol believes:

```
100 ETH

=

7,181,900 DAI
```

of collateral.

Now protocol allows:

```
Borrow

5,745,599 DAI
```

---

## Step 3 — Restore the Price

Attacker immediately sells back:

```
832 ETH
```

Pool returns to roughly:

```
2,000 DAI / ETH
```

Again.

---

# Final Situation

Reality:

```
100 ETH

=

200,000 DAI
```

Debt:

```
5,745,599 DAI
```

The protocol is now massively undercollateralized.

The attacker simply walks away with millions of DAI.

---

# Why Couldn't the Protocol Stop This?

Because it asked:

```
"What is the price RIGHT NOW?"
```

Instead of asking:

```
"What has the average price been over the last 30 minutes?"
```

The current price can be manipulated.

The long-term average is much harder to manipulate.

---

# Why Is Manipulating the Spot Price Easy?

A Uniswap Pair determines price only from:

```
reserve0

reserve1
```

For example:

```
reserveDAI

/

reserveETH
```

Large swaps change the reserves.

Changing reserves changes the price.

Therefore:

```
Large Swap

↓

Reserves Change

↓

Spot Price Changes
```

No oracle.

No external verification.

Just reserve ratios.

---

# The Core Problem

A spot price answers:

> "What is the price **right now**?"

Protocols care about:

> "What is the fair market price?"

Those are **not the same thing**.

---

# Why TWAP Exists

Instead of trusting:

```
Current Price
```

TWAP uses:

```
Average Price

Over Time
```

Example:

```
Last 30 Minutes

1999
2001
2000
1998
2002
2000
1999
```

Average:

```
≈ 2,000
```

Now suppose an attacker manipulates the price to:

```
71,819
```

for just one block.

The average barely changes.

The protocol still sees approximately:

```
2,000 DAI / ETH
```

The attack becomes economically infeasible because the attacker would have to maintain the fake price over many blocks instead of only one transaction.

---

# Spot Price vs TWAP

| Spot Price               | TWAP                            |
| ------------------------ | ------------------------------- |
| Current reserve ratio    | Average reserve price over time |
| Changes every swap       | Changes gradually               |
| Easily manipulated       | Much harder to manipulate       |
| Unsafe as a price oracle | Designed for oracle usage       |

---

# Mental Model

```
Spot Price

"What is the price RIGHT NOW?"

↓

Easy to manipulate



TWAP

"What has the average price been for the last X minutes?"

↓

Much safer
```

---

# Key Takeaways

* A Uniswap V2 Pair does **not** know the real market price.
* It only knows the ratio of its current reserves.
* Large swaps can temporarily distort that ratio.
* Lending protocols, liquidation systems, and collateral calculations should **never** rely on the instantaneous spot price.
* Instead, protocols use **TWAP (Time-Weighted Average Price)** or external oracle networks such as Chainlink to obtain prices that are much more resistant to manipulation.

# Does TWAP Completely Prevent Price Manipulation?

A common question after learning about TWAP is:

> **"If an attacker manipulates the Uniswap reserves and simply leaves them manipulated, won't the TWAP eventually become manipulated too?"**

The answer is:

> **Yes. TWAP is not manipulation-proof. It is manipulation-resistant.**

---

# Why Does This Happen?

A TWAP is still calculated from the Pair's reserves.

If the reserves remain manipulated for a long enough period, then the average price will naturally move toward that manipulated price.

For example:

Real price:

```text
2,000 DAI / ETH
```

Attacker manipulates the pool:

```text
72,000 DAI / ETH
```

If the attacker somehow keeps the reserves in this manipulated state for the **entire TWAP window** (e.g., 30 minutes), then the TWAP will also approach:

```text
≈72,000 DAI / ETH
```

So TWAP is **not magically immune** to reserve manipulation.

---

# Then Why Is TWAP Considered Secure?

The difference is **cost**.

Manipulating the spot price requires only **one large swap**.

Manipulating the TWAP requires **maintaining** that manipulated price for the entire averaging period.

This means the attacker must continuously keep the pool reserves distorted.

---

# The Real Enemy: Arbitrage

Suppose the attacker manipulates a DAI/WETH pool so that:

```text
1 ETH = 72,000 DAI
```

Meanwhile, every other exchange still prices ETH at:

```text
1 ETH = 2,000 DAI
```

This creates an enormous arbitrage opportunity.

Professional arbitrage bots immediately detect this price difference.

They repeatedly:

```text
Buy ETH cheaply on another exchange
            ↓
Sell ETH into the manipulated Uniswap pool
            ↓
Receive a huge amount of DAI
            ↓
Repeat
```

Every arbitrage trade pushes the Uniswap reserves back toward their fair market ratio.

---

# The Attacker Must Fight the Entire Market

To keep the fake price alive, the attacker must constantly counteract every arbitrage trade.

The attacker is effectively fighting every arbitrage bot and trader trying to restore the correct price.

This requires locking up a massive amount of capital and continuously spending money to maintain the manipulated reserves.

For most attacks, the cost quickly becomes greater than the potential profit.

---

# Spot Price vs TWAP Attack

## Spot Price Attack

```text
Manipulate reserves
        ↓
Read the manipulated price
        ↓
Exploit protocol
        ↓
Restore reserves
```

Duration:

```text
One transaction
```

Cost:

```text
Relatively low
```

---

## TWAP Attack

```text
Manipulate reserves
        ↓
Keep reserves manipulated
        ↓
Fight arbitrage for minutes or hours
        ↓
Average price slowly changes
        ↓
Attempt exploit
```

Duration:

```text
Minutes or hours
```

Cost:

```text
Extremely high
```

---

# Key Takeaway

TWAP does **not** prevent manipulation.

Instead, it makes manipulation **economically impractical**.

An attacker can manipulate a spot price for a single transaction with relatively little capital.

Manipulating a TWAP requires maintaining that false price over time while continuously fighting arbitrage traders attempting to restore the market.

This dramatically increases the cost of the attack, making it unprofitable in most real-world scenarios.

> **Spot Price:** Easy to manipulate, cheap to attack.
>
> **TWAP:** Still theoretically manipulable, but so expensive to manipulate over time that the attack is usually not worth attempting.
