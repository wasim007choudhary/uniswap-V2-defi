# 3.1.1 — Introduction

In Parts **1** and **2**, we focused entirely on understanding the Uniswap V2 Oracle from a conceptual and mathematical perspective.

In **Part 1**, we answered questions such as:

* Why is Spot Price unsafe?
* Why do we need a Time-Weighted Average Price (TWAP)?
* What is a cumulative price?
* Why does multiplying Price × Time solve the manipulation problem?

Then, in **Part 2**, we built the mathematics from scratch.

Instead of memorizing equations from the Uniswap documentation, we derived them ourselves. We proved why cumulative prices work, how subtracting two cumulative values isolates the contribution between two timestamps, why dividing by the elapsed time produces the TWAP, how counterfactual cumulative prices are calculated, and finally why

```text
TWAP(token1) ≠ 1 / TWAP(token0)
```

even though

```text
SpotPrice(token1) = 1 / SpotPrice(token0)
```

By the end of Part 2, every mathematical concept behind the oracle had been established.

Now we move to the implementation.

However, before opening the Solidity code, it is important to answer another question.

## Should We Read the Code First?

A common approach when learning smart contracts is to immediately open the source code and begin reading variables and functions.

For example, many developers see variables such as

```solidity
uint public price0CumulativeLast;
uint public price1CumulativeLast;
uint32 public blockTimestampLast;
```

and simply memorize their purpose.

While this approach may help someone read the contract, it rarely helps them understand **why those variables exist in the first place**.

Throughout this series, we have followed a different philosophy.

Instead of memorizing implementation details, we first derive **why the implementation must be written that way.**

This means that before reading a single line of Solidity, we will ask ourselves the same questions the Uniswap developers likely asked while designing the oracle.

By the time we finally open the source code, every storage variable and every line inside `_update()` should feel like the natural consequence of the mathematics developed in Parts 1 and 2.

The implementation should no longer appear mysterious.

Instead, it should feel inevitable.

---

# The Goal of Part 3

Part 3 is not about learning new mathematics.

Instead, it answers a different question.

> **How did the Uniswap developers convert the mathematics into Solidity code?**

Every design decision inside the Pair contract exists for a reason.

Rather than memorizing those decisions, we will derive each one ourselves.

Throughout this chapter, we will answer questions such as:

* Why does the Pair contract store the cumulative price instead of individual users?
* Why are two cumulative prices maintained?
* Why are cumulative prices updated only during transactions?
* Why is `blockTimestampLast` necessary?
* Why is the cumulative price updated before the reserves?
* Why does Uniswap trade using the Spot Price instead of the TWAP?
* If swaps use the Spot Price, then what is the purpose of maintaining a TWAP oracle?
* Why doesn't using the Spot Price make Uniswap vulnerable?
* How does arbitrage restore the market price after large trades?

Every one of these questions arose naturally during our discussions, and answering them will allow us to understand not only **what** the code does, but **why** it was written that way.

---

# The Learning Philosophy

Throughout this document, we will continue using the same approach followed in Parts 1 and 2.

Rather than treating the Solidity implementation as something to memorize, we will treat it as the final step of a logical process.

For every storage variable and every function, we will first answer:

> **Why does this need to exist?**

Only after reaching that conclusion ourselves will we examine the Solidity implementation.

This approach allows every line of code to become intuitive rather than something that must be remembered mechanically.

By the end of Part 3, the goal is that opening the Uniswap V2 Pair contract should feel less like reading unfamiliar code and more like reading the implementation of concepts we have already fully understood.

With that objective established, we can now begin by answering the first design question.

> **Why should the Pair contract store the cumulative price instead of each individual user?**
---
---
---
# 3.1.2 — Why Does the Pair Contract Store the Cumulative Price?

Now that we understand the mathematical foundation of the oracle, we can begin deriving the storage variables inside the Pair contract.

The first and perhaps the most fundamental question is:

> **Who should store the cumulative price?**

At first glance, there appear to be two possible designs.

## Option A — Every User Stores Their Own Cumulative Price

One possible design would be for every user interacting with the Pair to maintain their own cumulative price.

For example,

```text
Alice
└── Cumulative Price

Bob
└── Cumulative Price

Charlie
└── Cumulative Price

David
└── Cumulative Price
```

Initially, this might not seem like a bad idea.

Each user could simply update their cumulative price whenever they interacted with the Pair.

However, during our discussion, an important question naturally arose.

> **Would all of these cumulative prices remain the same?**

The answer is **no.**

Imagine the following situation.

* Alice starts using the Pair today.
* Bob starts using it next week.
* Charlie interacts only once every month.
* David interacts several times every day.

Since each user's cumulative price would only be updated when **they** interacted with the Pair, everyone would eventually end up with different cumulative values.

Alice's cumulative price would not match Bob's.

Bob's would not match Charlie's.

Charlie's would not match David's.

Yet all four users are observing the **exact same liquidity pool.**

This immediately reveals a contradiction.

How can one liquidity pool have four different cumulative prices?

It cannot.

---

## The Important Realization

During our discussion, this led to an important realization.

The cumulative price is **not a property of the user.**

It is a property of the **Pair itself.**

Just like the reserves belong to the liquidity pool,

the cumulative price also belongs to the liquidity pool.

Every user should observe exactly the same cumulative price because everyone is observing exactly the same reserves and exactly the same price history.

In other words,

the cumulative price represents **the history of the pool**, not the history of an individual user.

---

# Child Analogy — The Speedometer

One analogy that made this idea much easier to understand was a car's speedometer.

Imagine four people are sitting inside the same car.

```text
Alice

Bob

Charlie

David
```

Would each passenger have a different speed?

For example,

```text
Alice   → 60 km/h

Bob     → 95 km/h

Charlie → 42 km/h

David   → 80 km/h
```

Of course not.

There is only **one car.**

Therefore,

there is only **one speed.**

Every passenger simply observes that same speed.

The liquidity pool works in exactly the same way.

There is only **one Pair contract.**

There is only **one reserve state.**

There is only **one Spot Price at any given moment.**

Therefore,

there is also only **one cumulative price** for that price direction.

Users do not own their own cumulative prices.

They simply observe the cumulative price maintained by the Pair.

---

# Another Important Observation

Another interesting question came up during our discussion.

Suppose a new user interacts with the Pair for the very first time after the pool has already existed for two years.

If cumulative prices were stored per user,

what cumulative history would that user have?

The answer would be

```text
0
```

because they have never interacted with the Pair before.

However,

does that mean the pool itself has no history?

Of course not.

The Pair has already existed for two years.

It has already accumulated two years of price history.

That historical information belongs to the liquidity pool,

not to whoever happens to interact with it.

If cumulative prices were stored individually,

every new user would lose access to the historical information that makes TWAP possible.

Clearly,

this is not the desired design.

---

# Pool State vs User State

This discussion led us to distinguish between two completely different types of data.

### User State

Examples include

* Token balances
* LP token ownership
* Allowances

These naturally belong to individual users.

Different users have different balances.

Different users own different amounts of liquidity.

Different users approve different spenders.

Therefore,

these values should be stored per user.

---

### Pool State

Examples include

* Reserve0
* Reserve1
* Spot Price
* Cumulative Price

These describe the liquidity pool itself.

They are shared by everyone.

Every user looking at the Pair should observe the same reserves,

the same Spot Price,

and the same cumulative price.

Therefore,

these values belong inside the Pair contract.

---

# Conclusion

This reasoning leaves only one correct design.

The Pair contract must own the cumulative price.

Not because it is more convenient,

but because the cumulative price represents the shared price history of the liquidity pool itself.

This is exactly why the Pair contract stores variables such as

```solidity
uint public price0CumulativeLast;
uint public price1CumulativeLast;
```

These variables do **not** belong to Alice,

Bob,

Charlie,

or David.

They belong to the Pair,

and every user observes the same values.

Now that we know **where** the cumulative prices should be stored,

another question immediately appears.

> **If the Pair stores cumulative prices, should it store only one cumulative price, or should it maintain two separate cumulative prices?**
---
---
---
# 3.1.3 — Why Does the Pair Contract Store Two Cumulative Prices?

Now that we have established **where** the cumulative price should be stored, another important design question naturally arises.

> **Should the Pair contract store one cumulative price or two?**

At first glance,

storing one cumulative price appears to be sufficient.

After all,

a Pair contains only two tokens.

If we know the cumulative price of one token,

can't we simply calculate the other one by taking its inverse?

This seems like a perfectly reasonable assumption.

In fact, during our discussion, this was one of the first ideas we explored.

However,

to answer this question correctly,

we first need to revisit something we learned in Part 2.

---

# Consider an ETH/USDC Pair

Suppose our Pair contains

```text
token0 = ETH

token1 = USDC
```

The Spot Price of ETH is

```text
USDC
────────
 ETH
```

which answers the question

> **How many USDC is one ETH worth?**

Suppose the reserves imply

```text
1 ETH = 2000 USDC
```

Therefore,

the Spot Price is

```text
2000
```

Now imagine another user asks a different question.

Instead of asking

> **How many USDC for one ETH?**

they ask

> **How many ETH for one USDC?**

Notice that this is a completely different price.

Instead of

```text
USDC
────────
 ETH
```

we now have

```text
ETH
────────
USDC
```

Mathematically,

this is simply

```text
1
────
2000
```

or

```text
0.0005
```

This immediately reminds us of an important mathematical property.

For **Spot Price**,

taking the inverse works perfectly.

```text
SpotPrice(token1)

=

1
────────────────────
SpotPrice(token0)
```

This equation is completely correct.

---

# A Natural Assumption

Because the inverse works for Spot Price,

it is very natural to assume that the same idea should also work for TWAP.

In other words,

it seems reasonable to think

```text
TWAP(token1)

=

1
──────────────────
TWAP(token0)
```

During our discussion,

this was exactly the next question we explored.

If Spot Price behaves this way,

why shouldn't TWAP?

The answer lies in one of the most important mathematical concepts from Part 2.

---

# Revisiting the Mathematics

Earlier,

we proved that TWAP is not one Spot Price.

Instead,

TWAP is an average of **many Spot Prices**, each weighted by the amount of time it remained active.

One of the biggest realizations during our discussion was the following observation.

> **TWAP is basically many Spot Prices over different time intervals added together and then divided by the total observation time.**

This turns out to be an extremely useful way to think about TWAP.

Instead of imagining one price,

imagine many prices.

For example,

```text
Time 0 → 10

Spot Price = 2000
```

During this interval,

the opposite direction is simply

```text
1
────
2000
```

Now consider another interval.

```text
Time 10 → 20

Spot Price = 1000
```

Again,

the opposite direction is simply

```text
1
────
1000
```

Notice something important.

Each interval has **its own Spot Price.**

Since Spot Price can always be inverted,

each interval's price can also be inverted.

This explains why,

inside the TWAP equation,

we naturally write

```text
Σ ΔTᵢ × (1/Pᵢ)
```

instead of

```text
Σ ΔTᵢ × Pᵢ
```

The inverse is applied to **each individual Spot Price before averaging.**

---

# A Common Confusion

During our discussion,

an important question arose.

> **If taking the inverse works inside the Sigma, why doesn't taking the inverse of the final TWAP work?**

The answer is subtle.

The Sigma itself is not doing anything special.

It simply adds together whatever values we provide.

If we provide

```text
P₀

P₁

P₂
```

it calculates

```text
ΣP
```

If we instead provide

```text
1/P₀

1/P₁

1/P₂
```

it calculates

```text
Σ(1/P)
```

Sigma has no problem with reciprocals.

The mistake happens **after** the averaging.

Some people first compute

```text
TWAP(token0)
```

and then attempt

```text
1
──────────────
TWAP(token0)
```

Unfortunately,

this is **not** the same calculation.

The reciprocal must be applied **before** the averaging,

not after it.

---

# The Mathematical Rule

This leads to one of the most important mathematical observations in the entire oracle design.

> **The average of reciprocals is generally not equal to the reciprocal of the average.**

In mathematical notation,

```text
Average(1/P)

≠

1
────────────────
Average(P)
```

This is exactly why

```text
TWAP(token1)

≠

1
──────────────────
TWAP(token0)
```

even though

```text
SpotPrice(token1)

=

1
────────────────────
SpotPrice(token0)
```

---

# The Design Decision

Now the Pair contract's storage layout makes perfect sense.

If one cumulative price cannot be derived from the other,

then the Pair must maintain both independently.

Therefore,

the Pair stores

```solidity
uint public price0CumulativeLast;

uint public price1CumulativeLast;
```

These variables are **not duplicates.**

They represent two different cumulative prices.

One continuously accumulates

```text
token1
────────
token0
```

while the other continuously accumulates

```text
token0
────────
token1
```

Each follows its own history,

and neither can be reconstructed from the other using a simple inverse.

---

# Looking Ahead

At this point,

we now understand two important storage decisions inside the Pair contract.

1. Cumulative prices belong to the Pair rather than individual users because they represent the shared history of the liquidity pool.

2. Two cumulative prices are required because the TWAP of one token cannot be derived from the TWAP of the other by taking a reciprocal.

The next design question is equally important.

Even if the Pair stores the correct cumulative prices,

**when should those cumulative prices actually be updated?**

Should they change every block,

or only when someone interacts with the Pair?

Answering that question leads directly to one of Uniswap V2's most elegant gas optimization techniques.
---
---
---
# 3.1.4 — Why Are Cumulative Prices Updated Only During Transactions?

Now that we know the Pair contract stores two cumulative prices, another important design question naturally appears.

> **When should these cumulative prices be updated?**

At first, one idea seems obvious.

Since Ethereum produces new blocks continuously, why not simply update the cumulative price every block?

Although this sounds reasonable, it is actually one of the least efficient designs possible.

During our discussion, we explored why Uniswap intentionally chose a different approach.

---

# Option 1 — Update Every Block

Suppose Ethereum produces a block approximately every 12 seconds.

That means roughly

```text
7,200
```

blocks are produced every day.

If the Pair contract updated its cumulative price every block,

it would need to execute something similar to

```text
Cumulative += Price × Time
```

thousands of times every day.

Now imagine a liquidity pool that nobody has interacted with for several hours.

Should the contract continue updating storage every block?

Not really.

Nothing about the pool has changed.

The reserves remain identical.

The Spot Price remains identical.

Only time has passed.

This leads to an important question.

> **Who would even pay the gas for these updates?**

Ethereum does not execute smart contract code automatically.

Every state change requires someone to send a transaction and pay gas.

Without a transaction,

nothing executes.

Therefore,

continuously updating every block would not only be expensive,

it would also be impossible without someone constantly paying for those transactions.

---

# The Better Design

Instead of updating every block,

Uniswap follows a much more efficient approach.

The cumulative prices are updated **only when the Pair is already being modified.**

Examples include

* Swap
* Mint
* Burn
* Sync

Notice something interesting.

All of these operations already require a transaction.

Someone is already paying gas.

Therefore,

while updating reserves,

the Pair performs one additional calculation.

Instead of creating an entirely separate transaction,

the oracle update is performed as part of an existing transaction.

This is a very elegant gas optimization.

---

# Why Doesn't This Lose Information?

At first,

this design can feel surprising.

If the cumulative price is not updated every block,

doesn't that mean we lose all the time between updates?

This was one of the most important questions during our discussion.

The answer is

**No.**

Nothing is lost.

Suppose the cumulative price was last updated at

```text
Time = 100
```

with

```text
Cumulative = 11800
```

Now imagine that no one interacts with the Pair for another ten minutes.

The stored cumulative price remains

```text
11800
```

It does **not** change.

At first,

this seems incorrect.

After all,

time is still passing.

However,

remember what we proved in Part 2.

As long as the reserves do not change,

the Spot Price also does not change.

If the Spot Price remains constant,

then we already know exactly what happened during those missing ten minutes.

The contribution is simply

```text
Current Price × Time Elapsed
```

Therefore,

the missing portion can always be calculated later.

Nothing needed to be written to storage while the pool was idle.

---

# Connecting This to Counterfactual Cumulative Prices

This design immediately connects back to one of the final concepts from Part 2.

There,

we derived the counterfactual cumulative price.

Instead of updating storage every block,

we simply calculate

```text
Current Cumulative

=

Stored Cumulative

+

(Current Time − Last Update Time)

×

Current Spot Price
```

This equation allows us to determine what the cumulative price **would be right now** without modifying storage.

This is exactly why updating every block is unnecessary.

Storage contains only the most recently recorded cumulative price.

Whenever the current cumulative price is needed,

the missing contribution is calculated in memory.

This saves gas while still producing the correct result.

---

# Reality vs Storage

One of the most useful ways to think about this is to distinguish between reality and storage.

Reality continues moving forward every second.

Storage does not.

For example,

suppose

```text
Time = 100

Cumulative = 11800
```

Ten minutes pass.

No one interacts with the Pair.

Reality has advanced.

However,

storage still contains

```text
11800
```

The storage value is simply the **last recorded cumulative price.**

The current cumulative price can always be reconstructed using

```text
Stored Cumulative

+

Price × Time Elapsed
```

This is why the Pair contract does not need to update itself continuously.

---

# The Gas Optimization

During our discussion,

we summarized this design with a very simple observation.

> **Uniswap updates the cumulative price only when a transaction already exists.**

This avoids unnecessary storage writes,

avoids unnecessary gas costs,

and still preserves all the information required to calculate an accurate TWAP.

Instead of forcing the blockchain to perform work every block,

Uniswap performs the minimum amount of work necessary.

This is one of the reasons the oracle design is considered so elegant.

---

# The Next Question

At this point,

another question naturally appears.

If cumulative prices are updated only during transactions,

how does the Pair know **how much time has passed since the previous update?**

In other words,

how can it calculate

```text
ΔT
```

for

```text
Cumulative += Price × ΔT
```

The answer is another storage variable inside the Pair contract.

```solidity
uint32 public blockTimestampLast;
```

Understanding why this variable exists is the next step before reading the Solidity implementation.
---
---
---
# 3.1.5 — Why Does the Pair Contract Store `blockTimestampLast`?

We have now answered another important design question.

The Pair contract updates its cumulative prices only when a transaction modifies the pool.

However, this immediately creates another problem.

Suppose the cumulative price was last updated at

```text id="lcp5pb"
Time = 100
```

and the next transaction occurs at

```text id="d3jbtm"
Time = 130
```

Question.

How does the Pair know that

```text id="zx9p4n"
30 seconds
```

have passed?

Without knowing the elapsed time,

it cannot calculate

```text id="rmgbnt"
Price × Time
```

which is the entire foundation of cumulative pricing.

This means the Pair must remember **when the previous cumulative update occurred.**

---

# Why Isn't Price Alone Enough?

At first,

one might think that updating the cumulative price is as simple as

```text id="j64nqh"
Cumulative += Price
```

However,

this is incorrect.

During our discussion,

this was one of the first misconceptions we addressed.

The cumulative price is **not** the sum of prices.

Instead,

it is the sum of

```text id="v08qvq"
Price × Time Elapsed
```

or,

more precisely,

```text id="39tbnw"
ΔT × Price
```

The amount added to the cumulative price depends on **how long** the current Spot Price remained active.

Without the elapsed time,

the Pair cannot determine how much should be added.

---

# A Simple Example

Suppose the previous cumulative update happened at

```text id="jlwm5m"
Time = 100
```

The Spot Price is

```text id="5pb3n4"
2000
```

The next transaction happens at

```text id="ozqltr"
Time = 130
```

Question.

Should we update the cumulative price by adding

```text id="l59yvx"
2000
```

or

```text id="vdd3wz"
30 × 2000
```

The answer is obviously

```text id="9ij5uh"
30 × 2000
```

because the Spot Price remained active for thirty seconds.

The Pair therefore needs to calculate

```text id="qckjn2"
130 − 100
```

before it can update the cumulative price.

---

# Where Does The Previous Timestamp Come From?

This leads directly to another storage requirement.

The Pair must remember the timestamp of the previous cumulative update.

Otherwise,

when the next transaction occurs,

it has no reference point.

It would know

```text id="rqeod0"
Current Time
```

but it would have no idea what to subtract.

Therefore,

the Pair stores

```solidity id="6hquyh"
uint32 public blockTimestampLast;
```

This variable exists for one simple reason.

It allows the Pair to calculate

```text id="z9wcgo"
Time Elapsed

=

Current Timestamp

−

Previous Timestamp
```

Without this variable,

the oracle cannot determine how much cumulative price should be added.

---

# Walking Through An Example

Suppose the Pair currently stores

```text id="td4it6"
price0CumulativeLast = 11800

blockTimestampLast = 100
```

A new transaction arrives at

```text id="bgyt25"
130
```

The Pair calculates

```text id="5r2m2y"
Time Elapsed

=

130 − 100

=

30
```

It then updates the cumulative price by adding

```text id="q4x0h8"
Current Price × 30
```

Finally,

it replaces

```text id="mej9gp"
blockTimestampLast
```

with

```text id="5s6j8r"
130
```

Why?

Because

```text id="jlwm3d"
130
```

has now become the new reference point.

Suppose the following transaction occurs at

```text id="87xz7d"
170
```

The Pair should calculate

```text id="l5n3xe"
170 − 130

=

40
```

not

```text id="lgcb6q"
170 − 100
```

Otherwise,

the first thirty seconds would be counted twice.

Every update replaces the previous reference point with the current one.

---

# An Important Discussion

During our discussion,

another interesting question arose.

> **Does `blockTimestampLast` represent the timestamp of the last swap, or the timestamp of the last cumulative update?**

The precise answer is

> **It stores the timestamp of the last successful `_update()` execution.**

This distinction is important.

The `_update()` function is called during

* Swap
* Mint
* Burn
* Sync

Therefore,

`blockTimestampLast` is **not specifically** the timestamp of the last swap.

Instead,

it stores the timestamp of the last reserve update.

Since cumulative prices are updated inside `_update()`,

this also makes it the timestamp of the last cumulative update.

Whenever `_update()` executes,

these operations always happen together.

```text id="vqujlwm"
1. Calculate Time Elapsed

2. Update price0CumulativeLast

3. Update price1CumulativeLast

4. Store blockTimestampLast
```

Because they occur together,

the timestamp naturally represents the last cumulative update as well.

---

# Child Analogy — The Bus Journey

One analogy that made this concept much easier to visualize was a bus journey.

Suppose a bus leaves Station A at

```text id="8mbr6h"
10:00
```

When it reaches Station B,

the time is

```text id="bivowt"
10:30
```

The journey lasted

```text id="vs9jcn"
30 minutes
```

Now suppose the bus continues to Station C,

arriving at

```text id="d2h8r8"
11:10
```

Should we calculate

```text id="2vv0yu"
11:10 − 10:00
```

No.

That would count the first journey twice.

Instead,

after reaching Station B,

we replace the reference time.

Now the next journey becomes

```text id="0jivmh"
11:10 − 10:30

=

40 minutes
```

This is exactly how `blockTimestampLast` works.

Every successful `_update()` establishes a new reference point for measuring the next time interval.

---

# Conclusion

The cumulative price cannot be updated using the Spot Price alone.

It also requires knowing **how long** that Spot Price remained active.

This is exactly why the Pair contract stores

```solidity id="tfnjlwm"
uint32 public blockTimestampLast;
```

Without this variable,

the Pair would have no way to calculate

```text id="hzv0lw"
ΔT
```

and without

```text id="mwbbl2"
ΔT
```

there is no way to calculate

```text id="gb1ltp"
Price × Time
```

which means the entire cumulative pricing mechanism would fail.

Now that we understand why the Pair stores cumulative prices and timestamps,

another design question naturally follows.

> **When a transaction occurs, should the Pair update the cumulative price first, or should it update the reserves first?**

The answer to this question turns out to be one of the most important implementation details inside `_update()`.
---
---
---
# 3.1.6 — Why Must the Cumulative Price Be Updated Before the Reserves?

At this point, we know that the Pair contract stores

```solidity
price0CumulativeLast
price1CumulativeLast
blockTimestampLast
```

We also know that whenever `_update()` executes, it must calculate

```text
ΔT = Current Timestamp − blockTimestampLast
```

and add

```text
Price × ΔT
```

to the cumulative price.

However, another important design decision still remains.

Suppose a swap occurs.

Should the Pair

1. update the reserves first and then update the cumulative price,

or

2. update the cumulative price first and then update the reserves?

At first glance, either order might seem acceptable.

After all,

both operations occur within the same transaction.

During our discussion, this was one of the most interesting conceptual questions because the correct answer depends on understanding **what the cumulative price actually represents.**

---

# What Does the Cumulative Price Record?

The cumulative price records

> **How long a particular Spot Price remained active.**

Notice the wording carefully.

It does **not** record

> **What the next Spot Price will be.**

Instead,

it records

> **What the previous Spot Price was, and how long it lasted.**

This distinction is extremely important.

---

# Consider the Timeline

Suppose the last update happened at

```text
Time = 100
```

The Spot Price during this period is

```text
2000
```

No one interacts with the Pair for the next thirty seconds.

Finally,

a swap arrives at

```text
Time = 130
```

The timeline looks like

```text
100 ------------------------------ 130
        Price = 2000
```

Question.

Which Spot Price existed during

```text
100 → 130
```

The answer is

```text
2000
```

because the reserves did not change during this interval.

The new Spot Price does not exist yet.

It will only begin **after** the swap updates the reserves.

---

# What Happens If We Update The Reserves First?

Suppose we update the reserves immediately.

The reserves now become

```text
New Reserve0

New Reserve1
```

Since Spot Price is calculated directly from the reserves,

the Pair would now calculate

```text
New Spot Price
```

instead of the previous one.

During our discussion,

an important question arose at this point.

> **"Doesn't price calculation depend on the reserves?"**

Yes.

In Uniswap,

the Spot Price is derived directly from the reserve ratio.

For example,

```text
Price(token0)

=

reserve1
──────────
reserve0
```

Therefore,

changing the reserves immediately changes the Spot Price.

If the Pair were to calculate the cumulative price after replacing the reserves,

it would accidentally use the **new Spot Price** to represent a time interval during which that price never actually existed.

This would be incorrect.

---

# The Correct Order

Instead,

the Pair must first calculate

```text
Old Price × Time Elapsed
```

because the old Spot Price is the one that remained active throughout the interval that just finished.

Only after recording that contribution should the Pair replace the reserves.

The sequence therefore becomes

```text
Old Reserves
      │
      ▼
Calculate Old Spot Price
      │
      ▼
Update Cumulative Price
      │
      ▼
Update Reserves
      │
      ▼
New Spot Price Begins
```

This guarantees that every second of history is assigned to the correct Spot Price.

---

# An Important Realization

During our discussion,

another interesting observation emerged.

You summarized it as

> **"The next guy only will pay more."**

Although this statement referred to trading,

it also provides an intuitive way to think about the oracle timeline.

The swap arriving at

```text
Time = 130
```

marks the **end** of the previous price interval.

Everything before

```text
130
```

belongs to the old Spot Price.

Everything after

```text
130
```

belongs to the new Spot Price.

The transaction itself separates these two intervals.

Therefore,

the oracle first closes the previous interval by recording

```text
Old Price × Time Elapsed
```

Only then does it begin the next interval using the updated reserves.

---

# Oracle Timeline vs Swap Execution

During our discussion,

another important distinction had to be made.

At one point,

it seemed as though the trader was simply buying at the old Spot Price.

This is not exactly how an AMM works.

In reality,

a swap executes against the constant product curve,

meaning the execution price changes continuously as the reserves change.

Large swaps therefore experience price impact.

However,

this does **not** change how the oracle records history.

The oracle is not trying to determine the trader's average execution price.

Instead,

it is determining

> **Which Spot Price existed during the interval that has just ended?**

For the interval

```text
100 → 130
```

the answer is always

```text
Old Spot Price
```

because the reserve update had not yet occurred.

The new Spot Price begins only after the reserves have been updated.

This distinction between **swap execution** and **oracle accounting** is extremely important.

The oracle is recording the history of the pool,

not the trader's execution path.

---

# Why This Design Is Correct

The cumulative price is essentially a historical record.

Each update answers one simple question.

> **What Spot Price existed during the interval that has just finished?**

It does not ask

> **What Spot Price will exist next?**

That next Spot Price belongs to the next time interval.

Therefore,

every update naturally follows this sequence.

```text
Old Interval Ends
        │
        ▼
Record Old Price × Time
        │
        ▼
Replace Reserves
        │
        ▼
New Interval Begins
```

This ordering guarantees that every second of the pool's history is associated with the correct Spot Price.

---

# Bridge To The Next Topic

At this point,

the oracle design is almost completely understood.

However,

during our discussion,

another important question naturally appeared.

If the Pair contract maintains a sophisticated TWAP oracle,

then why do swaps still execute using the **Spot Price** derived from the current reserves?

Why doesn't the router simply trade using the TWAP instead?

Answering this question will reveal one of the most important conceptual distinctions in Uniswap V2.

The Pair contract contains **both** an Automated Market Maker and an Oracle,

but these two systems serve completely different purposes.
---
---
---
# 3.1.7 — Why Does Uniswap Execute Swaps Using the Spot Price Instead of the TWAP?

By this point, we understand that the Pair contract continuously maintains cumulative prices, allowing anyone to compute a Time-Weighted Average Price (TWAP).

This naturally leads to another important question.

> **If Uniswap already maintains a manipulation-resistant TWAP, why doesn't it simply use the TWAP when executing swaps?**

At first glance, this seems like the obvious design.

After all,

if TWAP is more resistant to manipulation,

wouldn't trading using the TWAP make Uniswap even safer?

During our discussion, this became one of the most important conceptual distinctions in the entire oracle design.

---

# The Pair Actually Contains Two Different Systems

One of the biggest realizations during our discussion was that the Pair contract is performing two completely different jobs simultaneously.

On one side,

it behaves as an Automated Market Maker (AMM).

On the other,

it also behaves as an Oracle.

Although both systems exist inside the same Pair contract,

they solve completely different problems.

---

## System 1 — The AMM

The first responsibility of the Pair contract is to execute swaps.

Whenever someone trades,

the Pair calculates the output amount using the **current reserves**.

Conceptually,

the process looks like

```text
Current Reserves
        │
        ▼
Current Spot Price
        │
        ▼
Swap Executes
```

The AMM only cares about the **current state** of the liquidity pool.

It does not care what the price was five minutes ago,

or thirty minutes ago,

or yesterday.

It only cares about the reserves that exist **right now**.

---

## System 2 — The Oracle

While the AMM is executing trades,

the Pair is also maintaining

```solidity
price0CumulativeLast
price1CumulativeLast
```

These variables are **not used to determine swap prices.**

Instead,

they continuously record historical price information.

That historical information is later converted into a TWAP.

Conceptually,

the oracle looks like

```text
Spot Price
      │
      ▼
Cumulative Price
      │
      ▼
TWAP
```

Notice something important.

The oracle is built **from** the Spot Price.

It does not replace the Spot Price.

---

# A Natural Confusion

During our discussion,

a very natural question arose.

> **"If Uniswap V2 already has a TWAP oracle, then when I trade, shouldn't I be trading using the TWAP instead of the Spot Price?"**

The answer is

**No.**

The swap logic never reads

```solidity
price0CumulativeLast
```

or

```solidity
price1CumulativeLast
```

Instead,

it uses the current reserves.

The cumulative prices exist for an entirely different purpose.

---

# Why Can't The AMM Trade Using TWAP?

Suppose the current reserves imply

```text
1 ETH = 2000 USDC
```

However,

the last thirty-minute TWAP is

```text
1 ETH = 1900 USDC
```

Now imagine someone wants to swap ETH.

Which price should the AMM use?

```text
2000 ?
```

or

```text
1900 ?
```

The correct answer is

```text
2000
```

Why?

Because the liquidity pool currently contains reserves that represent a price of

```text
2000
```

The AMM's mathematics depend entirely on the **current reserve balances**.

Using an average price from the past would completely disconnect the swap calculation from the actual state of the pool.

---

# The Constant Product Formula

Earlier,

we learned that Uniswap's AMM is based on

```text
x × y = k
```

This equation only works with the **current reserves**.

Every swap immediately changes

```text
reserve0

reserve1
```

which immediately changes the Spot Price.

If swaps were instead executed using a historical average,

the reserve mathematics would no longer match the price used for trading.

The AMM would no longer satisfy its own invariant.

Therefore,

the Spot Price is not simply a design choice.

It is a mathematical requirement of the AMM.

---
---
---
# 3.1.8 — Does Using the Spot Price Make Uniswap Unsafe?

After understanding that the AMM always executes swaps using the current Spot Price, another important question naturally arises.

> **If traders always use the Spot Price, can't someone simply manipulate the price and break Uniswap?**

This was one of the biggest conceptual questions during our discussion because it appears to expose a weakness in the AMM.

After all, if the Spot Price changes whenever someone trades, couldn't an attacker continuously move the price to whatever value they want?

The answer is more subtle than it first appears.

---

# Can Someone Manipulate the Spot Price?

The short answer is

**Yes.**

Suppose an ETH/USDC pool currently has a Spot Price of

```text
1 ETH = 2000 USDC
```

An attacker can perform a very large purchase of ETH.

As ETH is removed from the pool and USDC is added,

the reserves change.

Since the Spot Price is derived directly from the reserves,

the Spot Price also changes.

For example,

```text
Before Trade

100 ETH

200,000 USDC

↓

Spot Price = 2000
```

After a sufficiently large purchase,

the reserves might become

```text
95 ETH

199,500 USDC
```

The Spot Price is now higher than before.

Therefore,

yes,

the Spot Price can be manipulated.

---

# Why Isn't This Free?

This is where the constant product formula protects the AMM.

Earlier, we learned that Uniswap follows

```text
x × y = k
```

As the attacker continues buying ETH,

the remaining ETH inside the pool becomes increasingly scarce.

Each additional ETH purchased becomes more expensive than the previous one.

This phenomenon is known as **price impact** (or slippage).

During our discussion, an important realization emerged.

The attacker is not changing the Spot Price for free.

They are literally paying to move it.

The further they attempt to move the price,

the more expensive it becomes.

---

# Why Doesn't This Break Uniswap?

At first,

it might seem that repeatedly manipulating the Spot Price would eventually break the protocol.

However,

another important mechanism immediately comes into play.

**Arbitrage.**

Suppose every centralized exchange values ETH at

```text
2000 USDC
```

but after a large purchase,

the Uniswap pool temporarily values ETH at

```text
3000 USDC
```

Professional arbitrage traders immediately recognize this opportunity.

They simply

1. Buy ETH elsewhere for approximately 2000 USDC.
2. Sell that ETH into the Uniswap pool for close to 3000 USDC.
3. Collect the difference as profit.

As they perform these trades,

the reserves move back toward equilibrium.

Consequently,

the Spot Price gradually returns toward the broader market price.

In other words,

the market itself continuously repairs temporary price distortions.

---

# So Who Actually Gets Exploited?

During our discussion,

another important distinction became clear.

It is tempting to say

> **"Someone can exploit Uniswap."**

However,

this wording is slightly misleading.

Uniswap is behaving exactly as designed.

The Spot Price is supposed to change whenever the reserves change.

That is the entire purpose of an Automated Market Maker.

The real danger exists elsewhere.

Imagine another protocol reads the current Spot Price immediately after the attacker manipulates it.

For example,

a lending protocol might incorrectly assume

```text
ETH = 3000 USDC
```

even though the broader market still values ETH much closer to

```text
2000 USDC
```

If that protocol makes financial decisions using this temporary Spot Price,

it can be exploited.

Therefore,

the vulnerability does **not** come from Uniswap itself.

The vulnerability comes from external protocols trusting an instantaneous Spot Price.

---

# Why Does the TWAP Exist?

This naturally leads to another important question.

> **If swaps never use the TWAP, then why does the Pair contract spend time maintaining cumulative prices?**

The answer is that the TWAP was never designed primarily for executing swaps.

Instead,

it was designed for **external consumers** of price data.

Examples include

* Lending protocols
* Stablecoin systems
* Liquidation engines
* Derivatives
* Other smart contracts requiring reliable on-chain prices

Rather than trusting a price that can temporarily move because of one large transaction,

these protocols calculate the average price over a chosen observation window.

Because the average incorporates both **price** and **time**,

brief manipulations have only a limited influence on the final TWAP.

This makes the oracle significantly more resistant to manipulation than the instantaneous Spot Price.

---

# The Complete Picture

By the end of our discussion,

the relationship between the AMM and the Oracle became much clearer.

```text
                     Uniswap V2 Pair
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
          ▼                                   ▼
     AMM (Trading)                     Oracle (Pricing)
          │                                   │
Uses Current Reserves          Maintains Cumulative Prices
          │                                   │
Current Spot Price                     Computes TWAP
          │                                   │
Executes Swaps                 Used by External Protocols
```

Although both systems exist inside the same Pair contract,

they serve entirely different purposes.

The AMM determines how trades execute.

The Oracle records historical pricing information.

The TWAP is built **from** the Spot Price,

but it does not replace it.

---

# Final Conclusion

One of the biggest conceptual milestones in understanding the Uniswap V2 Oracle is realizing that the Pair contract serves two independent roles.

As an **Automated Market Maker**, it must execute trades using the current Spot Price implied by the reserves.

As an **Oracle**, it continuously records historical prices so that anyone can later compute a manipulation-resistant Time-Weighted Average Price.

These are not competing systems.

They complement one another.

The Spot Price provides efficient trading.

The TWAP provides reliable historical pricing.

Understanding this distinction completes the conceptual foundation required before reading the Solidity implementation.

With every major design decision now explained, we are finally ready to study the `_update()` function line by line and see how these ideas are translated into code.


