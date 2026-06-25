# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

## Part 2 — Understanding Time (`Tᵢ`), Time Intervals, and Why Uniswap Doesn't Continuously Update Prices

---

# Introduction

In Part 1, we learned that:

```text
Pᵢ
```

simply means

> **The price at observation `i`.**

Now another question naturally arises.

> **How long does that price remain valid?**

Does the price change every second?

Every millisecond?

Continuously?

The answer is **no**.

To understand why, we first need to understand the notation:

```text
T₀

T₁

T₂

...

Tₙ
```

---

# What Does `T` Mean?

Just like:

```text
P
```

means

```text
Price
```

the letter

```text
T
```

simply means

```text
Time
```

Nothing more.

---

## What Does The Small Number Mean?

Exactly like prices, timestamps also have indices.

```text
T₀
```

means

> The first recorded timestamp.

---

```text
T₁
```

means

> The second recorded timestamp.

---

```text
T₂
```

means

> The third recorded timestamp.

---

## Programmer Mental Model

Think of

```text
T₀

T₁

T₂
```

as

```solidity
timestamps[0]

timestamps[1]

timestamps[2]
```

Exactly the same concept.

---

# Combining Price And Time

Suppose we observe ETH.

| Time | Price |
| ---- | ----- |
| 5:00 | 2000  |
| 5:05 | 2050  |
| 5:10 | 1980  |

Mathematically we write:

```text
T₀ = 5:00
P₀ = 2000

T₁ = 5:05
P₁ = 2050

T₂ = 5:10
P₂ = 1980
```

Notice something.

Every price has a timestamp attached to it.

---

# Does A Price Last Forever?

No.

Suppose

```text
T₀ = 5:00
```

Price:

```text
P₀ = 2000
```

At

```text
5:05
```

someone swaps.

Price changes.

Now

```text
P₁ = 2050
```

Question:

> For how long was Price₀ valid?

Answer:

From

```text
5:00
```

until

```text
5:05
```

Not longer.

---

# This Is Why Documentation Says

```text
Pᵢ applies from Tᵢ

up to (but NOT including)

Tᵢ₊₁
```

Mathematically written as

```text
[Tᵢ, Tᵢ₊₁)
```

Many people find this notation scary.

It actually means something very simple.

---

# Understanding

```text
[Tᵢ, Tᵢ₊₁)
```

Read it as

> **Starting at `Tᵢ` and ending just before `Tᵢ₊₁`.**

Example:

Suppose

```text
T₀ = 5:00
```

and

```text
T₁ = 5:05
```

Then

```text
[T₀, T₁)
```

means

```text
5:00 ≤ time < 5:05
```

Notice the symbols.

```text
≤
```

means

```text
Including 5:00
```

while

```text
<
```

means

```text
Not including 5:05.
```

---

# Why Not Include 5:05?

This was one of the most important questions we discussed.

Suppose:

```text
5:00

↓

Price = 10
```

Exactly at

```text
5:05
```

a swap occurs.

The reserves change instantly.

Immediately afterwards:

```text
Price = 20
```

Question:

At exactly

```text
5:05
```

which price should we use?

Price 10?

or

Price 20?

The answer is:

```text
Price 20.
```

Because the swap happened at that exact timestamp.

The old price is no longer valid.

---

# Timeline

```text
5:00 ----------------------- 5:05 ----------------------- 5:10

Price = 10                  Swap Happens                Price = 20
```

Notice.

Price 10 belongs to

```text
[5:00, 5:05)
```

Price 20 belongs to

```text
[5:05, 5:10)
```

There is **no overlap**.

There is **no ambiguity**.

---

# Question We Asked

> "Price 10 existed at 5:05 for a tiny moment, right?"

Answer:

No.

The swap executes atomically.

Before execution:

```text
Price = 10
```

After execution:

```text
Price = 20
```

There is never a moment where the blockchain stores

```text
Price = 15
```

or

```text
Price = 18
```

or any intermediate value.

Everything changes within one atomic state transition.

---

# Child Analogy

Imagine a classroom.

Bell rings.

The teacher says:

> Everyone leave.

The classroom changes from

```text
30 Students
```

to

```text
0 Students
```

Did it gradually become

```text
29

28

27

...

15
```

No.

From the system's point of view, once attendance is updated, the new state immediately replaces the old state.

Blockchain state works the same way.

---

# Why Doesn't Uniswap Continuously Update Prices?

This was another excellent question.

You asked:

> **"Why doesn't Uniswap continuously update?"**

Answer:

Because smart contracts **do not run continuously**.

They only execute when someone sends a transaction.

No transaction means:

```text
No execution.

No reserve update.

No price update.
```

---

Imagine nobody trades for three hours.

Timeline:

```text
5:00

Swap

↓

Price = 2000
```

---

Nothing happens.

No swaps.

No mint.

No burn.

---

At

```text
8:00
```

someone finally swaps.

Only then does Uniswap execute code again.

---

# Important Realization

Uniswap does **not** wake up every second and ask:

```text
"Has the price changed?"
```

It cannot.

Ethereum smart contracts are passive.

They execute only when called.

---

# Child Analogy

Imagine a calculator.

Does a calculator constantly perform calculations by itself?

No.

It waits.

Only when someone presses a button does it execute.

A smart contract behaves exactly the same way.

---

# Why This Matters For TWAP

Suppose

```text
Price = 2000
```

at

```text
5:00
```

Nobody swaps until

```text
6:00
```

Question:

What was the price during

```text
5:15

5:30

5:45
```

Answer:

Still

```text
2000.
```

Nothing happened.

The reserves never changed.

Therefore the price never changed.

This is exactly why the **time** for which a price remains valid matters so much.

---

# Understanding `Tᵢ₊₁`

This notation often scares people.

It simply means

> **The next timestamp after `Tᵢ`.**

Example:

```text
T₀ = 5:00

T₁ = 5:05

T₂ = 5:20

T₃ = 5:40
```

Notice

```text
T₁
```

is simply

> the timestamp after

```text
T₀
```

Similarly

```text
T₂
```

is simply

> the timestamp after

```text
T₁
```

Nothing magical.

---

# Questions We Asked During Learning

## Question

> **"Tᵢ₊₁ means?"**

Answer:

The next timestamp after `Tᵢ`.

Example:

```text
T₂ = 5:20

T₃ = 5:40
```

Then

```text
T₂₊₁
```

means

```text
T₃
```

which is

```text
5:40.
```

---

## Question

> **"`5:05 ≤ time < 5:10` means?"**

Answer:

Time can be

```text
5:05

5:06

5:07

5:08

5:09:59
```

But **not**

```text
5:10.
```

At exactly

```text
5:10
```

the next interval begins.

---

## Question

> **"Why not include 5:10?"**

Because exactly at

```text
5:10
```

a new observation starts.

If both intervals included

```text
5:10
```

the same instant would belong to two different prices.

Using

```text
[Tᵢ, Tᵢ₊₁)
```

avoids this ambiguity.

---

# Mental Model

Whenever you see

```text
Tᵢ
```

read

> Current timestamp.

Whenever you see

```text
Tᵢ₊₁
```

read

> Next timestamp.

Whenever you see

```text
[Tᵢ, Tᵢ₊₁)
```

read

> This price starts at `Tᵢ` and remains valid until just before the next recorded timestamp.

---

# Key Takeaways

* `T` simply means **Time**.
* `Tᵢ` is the current timestamp.
* `Tᵢ₊₁` is the next timestamp.
* Prices are valid over **time intervals**, not just at a single instant.
* `[Tᵢ, Tᵢ₊₁)` means **include the start, exclude the end**.
* Price changes happen **atomically**, never gradually.
* Smart contracts do **not** execute continuously.
* Uniswap updates prices **only when a transaction interacts with the Pair contract**.
* If no swaps occur, the last recorded price remains valid for the entire interval.

---

> **Next Part:** Understanding `ΔT`, why simple averages are wrong, why prices that exist longer should influence the average more, and how Time-Weighted Average Price begins to take shape.
