### Part 1.3 — What Does "Cumulative" Actually Mean?

We now know that Uniswap stores a **running total**.

The next question is:

> **What exactly does the word "Cumulative" mean?**

Before looking at formulas, let's understand the word itself.

---

# What Does The Letter `C` Mean?

Earlier, while learning TWAP, we saw:

```text
P
```

meant

```text
Price
```

We also saw:

```text
T
```

meant

```text
Time
```

Now we introduce a new letter.

```text
C
```

Question:

**What does the letter `C` stand for?**

Answer:

```text
C

↓

Cumulative
```

The word **Cumulative** simply means:

> **A running total that keeps growing by adding new contributions.**

Think of words such as:

* Cumulative Marks
* Cumulative Distance
* Cumulative Score
* Cumulative Savings

All of them mean exactly the same thing.

They are **not today's value**.

They are the **total accumulated so far**.

---

# Child Analogy — Counting Candies

Imagine you collect candies every day.

Day 1

```text
5 candies
```

Day 2

```text
+3 candies
```

Day 3

```text
+7 candies
```

Your cumulative candies become

```text
Day 1

↓

5
```

↓

```text
Day 2

↓

8
```

↓

```text
Day 3

↓

15
```

Notice something.

```text
15
```

is **not** the number of candies you collected today.

It is

> **The total candies collected up to this point.**

That is exactly what the word **cumulative** means.

---

# Programmer Analogy

Imagine writing Solidity like this:

```solidity
uint256 total;

total += 50;
total += 20;
total += 30;
```

After these three statements,

```solidity
total == 100;
```

Notice what happened.

We did **not** store

```text
50

20

30
```

individually.

We only stored

```text
100
```

which is the accumulated result.

This variable is a **running cumulative total**.

---

# Apply This To Uniswap

Instead of accumulating candies,

or money,

or scores,

Uniswap accumulates

```text
Price × Time
```

Every completed price interval contributes

```text
Price × Time
```

to the running total.

---

# What Does `C₀` Mean?

When we write

```text
C₀
```

we simply mean

> **The cumulative total at time `T₀`.**

Likewise,

```text
C₁
```

means

> **The cumulative total at time `T₁`.**

And

```text
C₂
```

means

> **The cumulative total at time `T₂`.**

Notice something important.

The letter

```text
C
```

does **NOT** mean

```text
Current Price
```

It does **NOT** mean

```text
Spot Price
```

It means

> **The current cumulative total of all `Price × Time` contributions accumulated so far.**

This distinction is extremely important.

---

# A Common Misconception

Suppose someone tells you

```text
C₂ = 170
```

Does that mean

the current price is

```text
170
```

No.

It simply means

```text
170
```

is the running total built from all previous

```text
Price × Time
```

contributions.

It is **not a price anymore.**

It is an accumulated value.

---

# A Very Natural Question

At this point, a question naturally comes to mind.

Suppose nothing has happened yet.

No swaps.

No time has passed.

No price has lasted for any duration.

What should

```text
C₀
```

be?

Many people initially think:

> "It should be the first price."

This sounds reasonable at first.

In fact, during our discussion we also considered this possibility.

The reasoning was:

> "The first price sets the initial price, then later we multiply that price by time."

This idea is actually **partially correct**.

The first price **does** establish the initial price.

However,

it is **not** immediately added to the cumulative total.

Why?

Because we still don't know how long that price will last.

To calculate

```text
Price × Time
```

we need **both** the price

and

the amount of time that price remained unchanged.

At the exact moment the first price appears,

the elapsed time is

```text
0
```

Therefore

```text
Price × Time

=

First Price × 0

=

0
```

Nothing has accumulated yet.

Therefore,

```text
C₀ = 0
```

not

```text
C₀ = First Price
```

This is a subtle but extremely important idea.

The first price is known immediately.

The duration of that price is **not**.

The duration only becomes known **when the next price change occurs.**

This is exactly why Uniswap waits before adding anything to the cumulative price.
