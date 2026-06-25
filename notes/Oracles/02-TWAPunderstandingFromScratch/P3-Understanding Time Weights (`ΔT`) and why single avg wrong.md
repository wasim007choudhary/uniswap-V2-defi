# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

## Part 3 — Why a Simple Average Is Wrong & Understanding Time Weights (`ΔT`)

---

# Introduction

So far we've learned:

- `Pᵢ` means the price at observation `i`.
- `Tᵢ` means the timestamp at observation `i`.
- Every price remains valid during its own time interval:

```text
[Tᵢ, Tᵢ₊₁)
```

Now comes the most important question.

> **How do we calculate the average price?**

Most people immediately think:

```text
Average =
(P₀ + P₁ + P₂ + ...)/n
```

Unfortunately...

This is **wrong**.

---

# Why A Simple Average Doesn't Work

Suppose the following prices occurred.

| Price | Lasted For |
|--------|------------|
|10|1 hour|
|100|1 second|

A simple average says:

```text
(10 + 100) / 2

=

55
```

Question:

> Was the market actually around **55**?

No.

The market spent:

```text
1 hour

↓

Price = 10
```

and only

```text
1 second

↓

Price = 100
```

The price

```text
100
```

should barely influence the average.

---

# Child Analogy

Imagine your teacher asks:

> "How long did you spend studying today?"

Suppose your day looked like this.

| Activity | Time |
|-----------|------|
|Study|6 hours|
|Gaming|2 hours|

Would it make sense to say:

```text
(6 + 2)/2

=

4 hours
```

No.

You weren't trying to average activities.

You were trying to understand **how much of your day each activity occupied.**

Time matters.

---

# The Same Idea Applies To Prices

Suppose

```text
Price = 10
```

lasted

```text
60 minutes.
```

and

```text
Price = 100
```

lasted

```text
1 second.
```

Question:

Which price better represents the market?

Obviously

```text
10.
```

Why?

Because it existed much longer.

---

# TWAP Thinks Differently

A simple average says:

> Every price is equally important.

TWAP says:

> No.

Instead:

> Prices that existed longer should influence the average more.

---

# Introducing Time Difference (`ΔT`)

To know **how long** each price existed, we calculate the time difference between consecutive timestamps.

The documentation introduces:

```text
ΔT
```

Read it as:

> **Delta Time**

or more intuitively:

> **Elapsed Time**

or

> **How long this price remained valid.**

---

# What Does The Symbol `Δ` Mean?

The Greek letter

```text
Δ
```

(pronounced **Delta**)

simply means

> **Difference** or **Change**

You'll see it everywhere in mathematics and physics.

Examples:

```text
ΔPrice

↓

Change in price
```

```text
ΔBalance

↓

Change in balance
```

```text
ΔTime

↓

Change in time
```

Nothing scary.

It simply means:

> Difference.

---

# The Formula

The documentation defines

```text
ΔTᵢ = Tᵢ₊₁ − Tᵢ
```

Let's decode every symbol.

---

## Left Side

```text
ΔTᵢ
```

means

> How long Priceᵢ lasted.

---

## Right Side

```text
Tᵢ₊₁
```

means

> The next timestamp.

---

```text
Tᵢ
```

means

> The current timestamp.

Subtracting them gives:

```text
Next Time

-

Current Time

=

Elapsed Time
```

---

# Example

Suppose

```text
T₀ = 5:00
```

```text
T₁ = 5:05
```

Then

```text
ΔT₀

=

T₁ - T₀

=

5 minutes
```

Meaning:

```text
Price₀

↓

Lasted

↓

5 minutes.
```

---

Another example.

```text
T₁ = 5:05
```

```text
T₂ = 5:20
```

Then

```text
ΔT₁

=

T₂ - T₁

=

15 minutes.
```

Meaning

```text
Price₁

↓

Stayed valid

↓

15 minutes.
```

---

# The Pattern

Notice the relationship.

| Price | Duration |
|--------|----------|
|P₀|ΔT₀ = T₁ − T₀|
|P₁|ΔT₁ = T₂ − T₁|
|P₂|ΔT₂ = T₃ − T₂|
|P₃|ΔT₃ = T₄ − T₃|

Every price has **its own lifetime.**

That lifetime is exactly what

```text
ΔT
```

measures.

---

# One Of Our Questions

During our discussion we asked:

> **"Does the small 2 in ΔT₂ mean the time difference between T₂ and T₃?"**

Answer:

**Yes. Exactly.**

Because

```text
ΔT₂

=

T₃ - T₂
```

The small index simply tells us:

> Which price interval are we talking about?

---

# Easy Way To Remember

Instead of reading

```text
ΔT₂
```

as

> Delta T Two

read it as

> **The lifetime of Price₂.**

For example:

```text
P₂ = 2,500 DAI/ETH
```

Then

```text
ΔT₂
```

answers:

> **How long did the market remain at 2,500 DAI/ETH before another swap changed it?**

This mental model is much easier than thinking about mathematical notation.

---

# Timeline Example

Suppose

```text
5:00

↓

Price = 10
```

At

```text
5:05

↓

Swap
```

Price becomes

```text
20
```

At

```text
5:20

↓

Swap
```

Price becomes

```text
30
```

Timeline:

```text
5:00 ----------- 5:05 -------------------- 5:20

Price 10         Price 20                  Price 30
```

Durations become

```text
ΔT₀

=

5 minutes
```

```text
ΔT₁

=

15 minutes
```

Notice

Price

```text
20
```

remained valid **three times longer** than

Price

```text
10.
```

Therefore

Price

```text
20
```

should influence the average much more.

---

# Another Question We Asked

Question:

> If the price changed from **10** to **20** exactly at **5:05**, doesn't Price 10 also exist for a tiny fraction of 5:05?

Answer:

No.

Price

```text
10
```

belongs to

```text
[5:00, 5:05)
```

Price

```text
20
```

belongs to

```text
[5:05, 5:20)
```

Exactly at

```text
5:05
```

the swap executes atomically.

The new reserves immediately replace the old reserves.

Therefore

```text
5:05
```

belongs to the **new interval**, not the old one.

---

# Child Analogy

Imagine two runners.

Runner A runs from

```text
5:00

↓

5:05
```

Exactly at

```text
5:05
```

he passes the baton.

Runner B immediately starts.

Who owns the race at

```text
5:05?
```

Runner B.

Runner A's interval has already ended.

This is exactly how TWAP intervals work.

---

# Mental Model

Whenever you see

```text
ΔTᵢ
```

don't think

> Delta.

Think

> **How long Priceᵢ stayed alive.**

That is the intuition behind the notation.

---

# Key Takeaways

- A simple average treats every price equally.
- TWAP does **not**.
- Prices that remain valid longer deserve more influence.
- `Δ` simply means **difference**.
- `ΔTᵢ` measures **how long Priceᵢ remained valid**.
- Every price has its own duration.
- Those durations are what make TWAP different from an ordinary average.

---

> **Next Part:** We'll learn **why we divide each duration by the total observation time**, how this creates a **weight**, and why TWAP is called a **Time-Weighted Average Price** rather than just an average.