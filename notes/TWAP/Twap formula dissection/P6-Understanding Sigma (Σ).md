# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

## Part 6 — Understanding Sigma (Σ): Mathematics' Version of a `for` Loop

---

# Introduction

We've finally arrived at one of the most intimidating-looking parts of the documentation.

The documentation rewrites this:

```text
ΔTₖ × Pₖ
+
ΔTₖ₊₁ × Pₖ₊₁
+
ΔTₖ₊₂ × Pₖ₊₂
+
...
+
ΔTₙ₋₁ × Pₙ₋₁
──────────────────────────────
        Tₙ − Tₖ
```

into

```text
              Σ
           i = k
──────────────────────────────
ΔTᵢ × Pᵢ
──────────────────────────────
 Tₙ − Tₖ
        n−1
```

Most developers see

```text
Σ
```

and immediately think

> "This looks like advanced mathematics."

In reality, it is one of the simplest mathematical symbols you'll ever learn.

---

# Why Was Sigma Invented?

Imagine writing

```text
1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10
```

Not too bad.

Now imagine writing

```text
1 + 2 + 3 + ...

+ 1,000
```

Would anyone actually write all one thousand additions?

Of course not.

Mathematicians became tired of writing repetitive additions.

So they invented

```text
Σ
```

which simply means

> **Add everything.**

That's literally its entire purpose.

---

# Child Analogy

Imagine your mom says

> Add all the apples in the basket.

Would she say

```text
Apple1

+

Apple2

+

Apple3

+

...

+

Apple100
```

No.

She simply says

> Add all the apples.

Sigma means exactly that.

---

# Programmer Analogy

Suppose you have

```solidity
uint256 total;

for (uint256 i = 0; i < prices.length; i++) {
    total += prices[i];
}
```

Question:

What is this loop doing?

Answer:

It is simply

> Adding everything.

Mathematicians write

```text
      n−1
      Σ
i = 0
priceᵢ
```

Programmers write

```solidity
uint256 total;

for (uint256 i = 0; i < prices.length; i++) {
    total += prices[i];
}
```

They are doing **the exact same thing**.

This is one of the biggest mindset shifts when reading mathematical papers.

---

# Sigma Is Basically A `for` Loop

Whenever you see

```text
Σ
```

think

```solidity
for (...)
```

Whenever you see

```text
+
+
+
+
+
```

think

```solidity
total += ...
```

They're expressing exactly the same idea.

---

# Breaking Down Every Symbol

The documentation writes

```text
      n−1
      Σ
i = k
```

Let's decode every symbol.

---

## Σ

Means

> Add everything.

Nothing more.

---

## i

Means

> Current index.

Exactly like

```solidity
for (uint256 i = ...)
```

---

## k

Means

> Starting index.

Suppose

```text
k = 5
```

Then Sigma begins at

```text
P₅.
```

---

## n−1

Means

> Last index.

Suppose

```text
n = 10
```

Then

```text
n − 1 = 9
```

The summation stops at

```text
P₉.
```

---

# Example

Suppose

```text
k = 2

n = 6
```

Then

```text
      5
      Σ
i = 2
```

means

```text
Start at

2

↓

Then

3

↓

Then

4

↓

Then

5

↓

Stop.
```

Nothing mysterious.

---

# Expanding The Sigma

Suppose the documentation writes

```text
      5
      Σ
i = 2
xᵢ
```

Expand it.

Result

```text
x₂

+

x₃

+

x₄

+

x₅
```

Notice

We include

```text
2
```

and

```text
5.
```

---

# One Of Our Questions

During our discussion I asked

> Expand

```text
      6
      Σ
i = 3
xᵢ
```

You initially answered

```text
x₃ + x₄ + x₅
```

Almost.

The ending index is **included**.

The correct expansion is

```text
x₃

+

x₄

+

x₅

+

x₆
```

Exactly like

```solidity
for (uint256 i = 3; i <= 6; i++) {
    total += x[i];
}
```

Iterations become

```text
i = 3

↓

i = 4

↓

i = 5

↓

i = 6

↓

Stop.
```

---

# Applying Sigma To TWAP

Instead of adding

```text
x₁

+

x₂

+

x₃
```

TWAP adds

```text
ΔTₖ × Pₖ

+

ΔTₖ₊₁ × Pₖ₊₁

+

ΔTₖ₊₂ × Pₖ₊₂

+

...
```

Sigma simply saves us from writing all those repeated additions.

---

# Programmer Translation

Suppose you wanted to implement the numerator in Solidity.

You would naturally write

```solidity
uint256 total;

for (uint256 i = k; i < n; i++) {
    total += durations[i] * prices[i];
}
```

Congratulations.

You just implemented

```text
          n−1
          Σ
i = k
ΔTᵢ × Pᵢ
```

without realizing it.

---

# Why Does Every Term Look The Same?

Notice

```text
ΔT₀ × P₀

+

ΔT₁ × P₁

+

ΔT₂ × P₂

+

ΔT₃ × P₃
```

What changes?

Only the index.

Everything else stays identical.

Whenever you see repeated patterns like this,

programmers immediately think

```solidity
for (...)
```

Mathematicians immediately think

```text
Σ
```

Same idea.

Different notation.

---

# Why Doesn't The Summation End At `n`?

The documentation ends at

```text
n − 1
```

not

```text
n.
```

Why?

Remember

```text
ΔTᵢ

=

Tᵢ₊₁

−

Tᵢ
```

Suppose

```text
P₅
```

Its duration is

```text
ΔT₅

=

T₆

−

T₅
```

Notice something.

Every price requires **the next timestamp** in order to know how long it lasted.

If your observation period ends at

```text
Tₙ
```

then the final complete price interval is

```text
Pₙ₋₁.
```

Its duration is

```text
ΔTₙ₋₁

=

Tₙ

−

Tₙ₋₁.
```

Now think about

```text
Pₙ.
```

Its duration would require

```text
ΔTₙ

=

Tₙ₊₁

−

Tₙ.
```

But

```text
Tₙ₊₁
```

doesn't exist.

You've already stopped observing.

Therefore

```text
Pₙ
```

has no complete time interval yet.

That's why the summation naturally stops at

```text
n − 1.
```

---

# One Of Our Questions

During our discussion I asked

> Explain this formula without saying the word Sigma.

Your answer was

> Start at **k** (starting index) and continue until **n−1** (ending index). It is basically saying to add the time-weighted prices of each interval together.

That intuition is exactly correct.

A slightly more precise wording would be

> Start from observation **k** and continue until observation **n−1**. For every observation, multiply the price by how long that price remained valid (`ΔT × P`), then add all of those contributions together.

That is exactly what the summation is doing.

---

# Mental Model

Whenever you see

```text
Σ
```

don't read

> Sigma.

Instead read

> **For every item...**

So

```text
          n−1
          Σ
i = k
ΔTᵢ × Pᵢ
```

becomes

> Start at observation **k**. For every observation until **n−1**, multiply the price by how long that price remained valid, then keep adding those contributions together.

Notice how the scary-looking equation has now become an ordinary sentence.

---

# Programmer Mental Model

Mathematicians

```text
Σ
```

↓

Programmers

```solidity
for (...)
```

---

Mathematicians

```text
ΔTᵢ × Pᵢ
```

↓

Programmers

```solidity
durations[i] * prices[i]
```

---

Mathematicians

```text
Σ(...)
```

↓

Programmers

```solidity
total += ...
```

---

# Key Takeaways

- `Σ` simply means **add everything**.
- Sigma is mathematics' version of a **for loop**.
- `i` is the current index.
- `k` is the starting index.
- `n−1` is the last complete observation.
- The summation ends at `n−1` because `Pₙ` does not yet have a complete duration (`ΔTₙ` would require `Tₙ₊₁`).
- The TWAP numerator is simply the sum of every:

```text
Price × Duration
```

across the observation period.

---

> **Next Part:** The Genius of Uniswap — Why the protocol **doesn't store every historical price**, how this leads to the invention of **cumulative prices**, and why `price0CumulativeLast` is one of the smartest design decisions in Uniswap V2.