# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

## Part 5 — Why TWAP Multiplies **Weight × Price**

---

# Introduction

In the previous part we learned how to calculate a **weight**.

Example:

| Price | Lasted | Weight |
|--------|---------|---------|
|10|10 min|10/30|
|20|20 min|20/30|

Now another question naturally arises.

> **Why don't we simply average the weights?**

Or

> **Why does the formula multiply the weight by the price?**

This is the final step before arriving at the TWAP equation.

---

# Let's Start With A Wrong Approach

Suppose we only added the weights.

```text
10/30

+

20/30

=

30/30

=

1
```

Question:

What does

```text
1
```

mean?

Nothing.

We only averaged **time**.

We completely ignored the prices.

---

# Child Analogy

Imagine your final school marks.

| Subject | Marks | Weight |
|----------|-------|---------|
|Math|90|50%|
|Science|60|50%|

Would you calculate:

```text
50%

+

50%

=

100%
```

Of course not.

That tells you absolutely nothing about your marks.

Instead, you multiply:

```text
Marks

×

Weight
```

Exactly the same idea applies to TWAP.

---

# Price Works Exactly The Same Way

Instead of

```text
Marks
```

we have

```text
Price.
```

Instead of

```text
Exam Weight
```

we have

```text
Time Weight.
```

Therefore

```text
Contribution

=

Price × Weight
```

---

# Example

Suppose

Price

```text
10
```

Weight

```text
10/30
```

Contribution

```text
10 × (10/30)

=

3.33
```

---

Second price

```text
20
```

Weight

```text
20/30
```

Contribution

```text
20 × (20/30)

=

13.33
```

---

Now add them.

```text
3.33

+

13.33

=

16.66
```

That

```text
16.66
```

is the Time-Weighted Average Price.

Notice something.

The average is much closer to

```text
20
```

because

Price

```text
20
```

existed much longer.

Exactly what we wanted.

---

# Why Multiply?

Think about voting.

Suppose

Candidate A

gets

```text
90 votes
```

Candidate B

gets

```text
10 votes
```

Should both candidates influence the election equally?

No.

The votes determine how much influence each candidate has.

TWAP does exactly the same thing.

Instead of

```text
Votes
```

it uses

```text
Time.
```

Longer time

↓

Bigger weight

↓

More influence.

---

# The Documentation Formula

The documentation now writes

```text
ΔTₖ
──────── × Pₖ
Tₙ−Tₖ
```

At first glance this looks complicated.

Let's decode every symbol.

---

## Bottom

```text
Tₙ−Tₖ
```

means

> Total observation period.

Suppose

```text
Tₖ

=

5:00
```

and

```text
Tₙ

=

5:30
```

Then

```text
Tₙ−Tₖ

=

30 minutes.
```

---

## Top

```text
ΔTₖ
```

means

> How long Priceₖ remained valid.

Suppose

```text
10 minutes.
```

Then

```text
ΔTₖ
────────
Tₙ−Tₖ
```

becomes

```text
10/30
```

which is simply the weight.

---

Now multiply by

```text
Pₖ
```

Suppose

```text
Pₖ = 100
```

Contribution becomes

```text
100 × (10/30)
```

Exactly what we've already been doing.

Nothing new has been introduced.

The documentation simply writes it more compactly.

---

# Why Does The Formula Suddenly Use `k` Instead Of `0`?

This confuses almost everyone.

Earlier the documentation used

```text
P₀

P₁

P₂
```

Suddenly it switches to

```text
Pₖ

Pₖ₊₁

Pₖ₊₂
```

Did anything change?

No.

The mathematics is simply becoming more general.

---

# What Does `k` Mean?

Think of

```text
k
```

as

> **The starting observation.**

Suppose

```text
k = 5
```

Then

```text
Pₖ
```

simply becomes

```text
P₅.
```

Likewise

```text
Pₖ₊₁
```

becomes

```text
P₆.
```

And

```text
Pₖ₊₂
```

becomes

```text
P₇.
```

Nothing magical happened.

The documentation simply says:

> Start from whatever observation you want.

---

# Programmer Mental Model

Think about a loop.

Instead of writing

```solidity
uint i = 0;
```

you could write

```solidity
uint i = startIndex;
```

The documentation is doing exactly the same thing.

Instead of hardcoding

```text
0
```

it uses

```text
k
```

which simply represents the starting observation.

---

# One Of Our Questions

During our discussion we asked:

> **If `k = 8`, what is `Pₖ₊₂`?**

Solution:

Substitute

```text
k = 8
```

Then

```text
Pₖ

↓

P₈
```

Next

```text
Pₖ₊₁

↓

P₉
```

Next

```text
Pₖ₊₂

↓

P₁₀
```

Exactly like array indexing.

---

# Programmer Comparison

Mathematics

```text
Pₖ

Pₖ₊₁

Pₖ₊₂
```

Programming

```solidity
prices[k]

prices[k + 1]

prices[k + 2]
```

They're expressing the exact same idea.

---

# Another Question We Asked

Question:

Suppose

```text
Price = 500
```

Lasted

```text
2 minutes
```

Observation period

```text
20 minutes
```

What is

1. The weight?
2. The contribution?

Answer

Weight

```text
2/20

=

0.1
```

Contribution

```text
500 × (2/20)

=

500 × 0.1

=

50
```

Notice

We always multiply

```text
Price × Weight
```

Never

```text
Time × Weight.
```

Because we're trying to calculate an **average price**, not an average duration.

---

# Mental Model

Always think in two separate steps.

Step 1

Compute the weight.

```text
Weight

=

Duration

/

Total Duration
```

---

Step 2

Apply the weight.

```text
Contribution

=

Price × Weight
```

Every price follows these exact two steps.

---

# Visual Memory Trick

```text
Price
 │
 ▼
100

Weight
 │
 ▼
10/30

Contribution
 │
 ▼
100 × (10/30)
```

The weight answers one question:

> **How much influence should this price have on the final average?**

---

# Key Takeaways

- Weights alone are meaningless.
- Prices alone ignore time.
- TWAP combines both by multiplying:

```text
Price × Weight
```

- Weight is simply:

```text
Duration / Total Observation Time
```

- `k` does **not** introduce a new concept.
- `k` simply means **the starting observation**.
- `Pₖ`, `Pₖ₊₁`, and `Pₖ₊₂` are mathematically identical to:

```solidity
prices[k]
prices[k + 1]
prices[k + 2]
```

---

> **Next Part:** We'll simplify the long weighted-average equation using the **Σ (Sigma)** notation and discover why **Σ is essentially mathematics' version of a `for` loop.**