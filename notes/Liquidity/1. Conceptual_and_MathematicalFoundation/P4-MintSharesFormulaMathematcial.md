# 4. Mint Share Formula

## 🎯 Goal

Understand **how many Pool Shares should be minted** when a new Liquidity Provider deposits assets into the pool.

> **Important**
>
> We will intentionally use a **single-asset pool (USDC only)** because it allows us to focus entirely on the mathematics of ownership.
>
> Later, we'll extend these ideas to Uniswap's two-token liquidity pools.

---

# 📌 The Question We Left Unanswered

In the previous section, we learned that:

- Pool Shares represent ownership.
- Ownership matters more than deposits.

Now suppose the pool currently looks like this.

```text
Pool Value = 1,100 USDC

Total Pool Shares = 1,000
```

A new Liquidity Provider, David, deposits:

```text
110 USDC
```

A natural question arises.

> **How many Pool Shares should David receive?**

---

# 🤔 A Naive Solution

The first idea most people have is:

> **"If David deposited 110 USDC, simply mint 110 Pool Shares."**

At first glance, that seems perfectly reasonable.

But...

Is it always correct?

Let's investigate.

---

# 📖 Example 1 — A Brand New Pool

Suppose the pool has just been created.

Alice deposits:

```text
1,000 USDC
```

Since she is the very first Liquidity Provider, the protocol mints:

```text
1,000 Pool Shares
```

The system now looks like this.

| Pool Value | Total Shares |
|-----------:|-------------:|
| 1,000 USDC | 1,000 Shares |

Each share represents:

```text
1 USDC
```

Now Bob deposits:

```text
100 USDC
```

If we mint:

```text
100 Shares
```

everything still looks fair.

The pool becomes:

```text
1,100 USDC
```

The total shares become:

```text
1,100 Shares
```

Each share is still worth:

```text
1 USDC
```

So far, everything works perfectly.

---

# 🤔 Let's Make Things More Interesting

Now suppose the pool earns profits.

Nobody deposits any additional USDC.

Instead, the pool itself grows.

The pool now contains:

```text
1,210 USDC
```

However, notice something important.

The total Pool Shares are still:

```text
1,100 Shares
```

Nothing happened to the shares.

Only the pool value changed.

Now David deposits:

```text
110 USDC
```

Should we still mint:

```text
110 Shares?
```

---

# 🚨 The Problem

Let's examine the situation.

Before David joined:

```text
Pool Value = 1,210 USDC

Total Shares = 1,100
```

Each share is no longer worth:

```text
1 USDC
```

Instead:

```text
1,210 / 1,100

=

1.1 USDC per Share
```

Every existing Pool Share has become more valuable because the pool itself became more valuable.

If we simply mint David:

```text
110 Shares
```

we would be pretending that every share is still worth:

```text
1 USDC
```

But that is no longer true.

David would receive more ownership than he actually paid for.

Existing Liquidity Providers would unfairly lose part of their ownership.

---

# 💡 The Big Realization

Pool Shares have a changing value.

They are **not permanently equal to the number of deposited tokens.**

As the pool grows:

- Every existing Pool Share becomes more valuable.

As the pool shrinks:

- Every existing Pool Share becomes less valuable.

Therefore:

> **The number of shares minted cannot simply equal the number of deposited tokens.**

It must depend on:

- The current pool value.
- The current total number of Pool Shares.
- The amount of liquidity being added.

---

# 🤔 What Should Be Fair?

Forget formulas for a moment.

Suppose the pool currently looks like this.

```text
Pool Value = 1,100 USDC

Total Shares = 1,000
```

David deposits:

```text
110 USDC
```

David contributed:

```text
110
```

to a pool that previously contained:

```text
1,100
```

Therefore:

```text
110 / 1,100

=

10%
```

David increased the existing pool by:

> **10%**

Intuitively, fairness suggests:

> **If David increased the pool by 10%, then the total Pool Share supply should also increase by 10%.**

---

# 📖 Thinking In Terms Of Shares

Before David joined:

```text
Pool Value

1,100 USDC

↓

Total Shares

1,000
```

David increases the pool by:

```text
10%
```

Therefore, the total share supply should also increase by:

```text
10%
```

10% of:

```text
1,000 Shares
```

is:

```text
100 Shares
```

So David should receive:

```text
100 Pool Shares
```

Notice something remarkable.

We reached this conclusion without using a single formula.

We simply followed the idea of fairness.

---

# 🧠 First Major Realization

Pool Shares do **not** measure:

> **How many tokens someone deposited.**

They measure:

> **How much ownership someone added to the pool.**

Ownership should increase by exactly the same proportion that liquidity increased.

This is the core intuition behind the Mint Share Formula.

---

# 📐 Defining Our Variables

To make the derivation easier, we'll define four variables.

| Variable | Meaning |
|----------|---------|
| **T** | Total Pool Shares before the deposit |
| **S** | Pool Shares to mint |
| **L₀** | Pool value before the deposit |
| **L₁** | Pool value after the deposit |

---

# 📌 The Fairness Principle

We already established:

> **The percentage increase in Pool Shares should equal the percentage increase in the pool's value.**

That single sentence is all we need.

---

## Before The Deposit

```text
Pool Value = L₀

Total Shares = T
```

---

## After The Deposit

```text
Pool Value = L₁

Total Shares = T + S
```

Why **T + S**?

Because:

- **T** shares already existed.
- **S** new shares are being minted.

Therefore, after minting:

```text
Existing Shares

+

New Shares

=

Total Shares
```

or simply:

```text
T + S
```

---

# 📐 The Fairness Equation

We can now express our fairness principle mathematically.

```text
(T + S) / T = L₁ / L₀
```

The left side compares:

```text
New Total Shares

──────────────

Old Total Shares
```

The right side compares:

```text
New Pool Value

──────────────

Old Pool Value
```

We are simply saying:

> **If the pool grows by a certain percentage, the total Pool Share supply should grow by that exact same percentage.**

This equation wasn't invented.

It is simply fairness written mathematically.

---

# 📐 Solving For S

Our goal is to solve for:

```text
S
```

which represents the number of Pool Shares to mint.

---

## Step 1 — Cross Multiply

```text
T + S = (L₁ / L₀) × T
```

---

## Step 2 — Move T To The Right Side

```text
S = (L₁ / L₀) × T − T
```

---

## Step 3 — Factor Out T

```text
S = ((L₁ / L₀) − 1) × T
```

---

## Step 4 — Simplify

Notice:

```text
(L₁ / L₀) − 1
```

can be rewritten as:

```text
(L₁ − L₀) / L₀
```

Substituting this back gives:

---

# ✅ Final Mint Share Formula

```text
S = ((L₁ − L₀) / L₀) × T
```

---

# 📖 Understanding The Formula

| Symbol | Meaning |
|--------|---------|
| **S** | Pool Shares to mint. |
| **L₀** | Pool value before the deposit. |
| **L₁** | Pool value after the deposit. |
| **L₁ − L₀** | Liquidity contributed by the new Liquidity Provider. |
| **(L₁ − L₀) / L₀** | Percentage increase in the pool's value. |
| **T** | Existing total Pool Shares before minting. |

---

# 💡 Reading The Formula In Plain English

Instead of looking at symbols, simply read it like this:

> **Calculate how much the pool grew as a percentage, then mint the same percentage of the existing Pool Shares.**

Or even shorter:

> **The percentage increase in Pool Shares must equal the percentage increase in the pool's value.**

---

# 📊 Worked Example

Suppose:

```text
L₀ = 1,100

L₁ = 1,210

T = 1,000
```

Liquidity added:

```text
L₁ − L₀

=

110
```

Percentage increase:

```text
110 / 1,100

=

10%
```

Therefore:

```text
Shares To Mint

=

10%

×

1,000

=

100 Shares
```

Exactly what our intuition predicted before deriving the equation.

---

# 💡 Common Confusion — "If the Pool Grows by 10%, Doesn't the New LP Own 10%?"

This was one of the biggest conceptual questions we had while deriving the Mint Share Formula.

---

# ❓The Confusion

Suppose the pool initially contains:

```text
Pool Value = 1,100 USDC

Total Pool Shares = 1,000
```

A new Liquidity Provider (David) deposits:

```text
110 USDC
```

The pool has increased by:

```text
110 / 1,100

=

10%
```

Since the pool increased by **10%**, we said:

> **"Mint 10% more Pool Shares."**

At first, this sounds like:

> **"David should own 10% of the pool."**

This is **not** what it means.

---

# ✅ What It Actually Means

When we say:

> **"Mint 10% more Pool Shares."**

we are talking about the **total share supply**, not David's final ownership.

Before David joined:

```text
Pool Value

1,100 USDC

↓

Total Shares

1,000
```

The pool grew by:

```text
10%
```

Therefore, the **total share supply** must also grow by:

```text
10%
```

So:

```text
1,000 Shares

↓

Mint 100 New Shares

↓

1,100 Total Shares
```

Those **100 newly created shares** are minted entirely to David.

---

# 📖 After Minting

The ownership now becomes:

| LP | Shares | Ownership |
|----|-------:|----------:|
| Alice | 300 | 300 / 1100 = 27.27% |
| Bob | 500 | 500 / 1100 = 45.45% |
| Charlie | 200 | 200 / 1100 = 18.18% |
| David | 100 | 100 / 1100 = 9.09% |
| **Total** | **1100** | **100%** |

Notice something important.

David does **not** own **10%** of the pool.

He owns:

```text
100 / 1100

=

9.09%
```

---

# 🤔 Then Where Did The 10% Go?

The **10%** refers to the increase of the **existing system**, not David's final ownership.

Specifically:

```text
Pool Increase

=

Liquidity Added
───────────────
Old Pool Value

=

110 / 1100

=

10%
```

and therefore

```text
Share Supply Increase

=

Shares Minted
─────────────
Old Total Shares

=

100 / 1000

=

10%
```

These two percentages must always be equal.

That is exactly what the Mint Share Formula enforces.

---

# 🚨 Two Different Percentages

This confusion comes from mixing two completely different percentages.

### 1️⃣ Percentage Increase of the Existing Pool

This compares the new liquidity against the **old** pool.

```text
110 / 1100

=

10%
```

This is used to determine **how many new shares to mint**.

---

### 2️⃣ Ownership of the New Pool

This compares David's shares against the **new** total share supply.

```text
100 / 1100

=

9.09%
```

This is David's final ownership after the minting process.

These two percentages are **not supposed to be equal**.

---

# 🧠 Biggest Realization

The fairness principle is:

> **The percentage increase in the pool's value must equal the percentage increase in the total share supply.**

It is **not**:

> **The new Liquidity Provider should own that same percentage of the enlarged pool.**

Those are two completely different ideas.

---

# 🔑 One Sentence To Remember

> **If the pool grows by 10%, the total Pool Share supply must also grow by 10%. Those newly minted shares are given to the new Liquidity Provider, after which everyone's ownership percentage is recalculated using the new total share supply.**

This single sentence captures the entire intuition behind the Mint Share Formula.

---

# ⚠️ Common Misconceptions

### ❌ Deposited tokens determine minted shares.

No.

The current pool value and existing share supply must also be considered.

---

### ❌ Pool Shares always equal deposited tokens.

No.

Only when each share happens to be worth exactly one token.

That relationship changes as the pool's value changes.

---

### ❌ This formula is unique to Uniswap.

No.

It comes directly from the fairness principle of preserving proportional ownership.

---

# 🧠 Biggest Realizations

- Pool Shares represent ownership—not deposited tokens.
- The Mint Share Formula preserves fair ownership for every Liquidity Provider.
- The formula is not arbitrary; it is simply fairness expressed mathematically.
- Every step of the derivation follows naturally from the idea that ownership should increase in the same proportion as liquidity.

---

# 🔗 Bridge To The Next Section

Everything we derived assumed a **single-asset pool**, where measuring the pool's value was straightforward.

Uniswap V2 is different.

Each pool contains **two assets**, such as:

```text
ETH

+

USDC
```

This raises a new question.

> **If a pool contains two different assets, how do we measure its liquidity or value?**

Before applying the Mint Share Formula to Uniswap V2, we first need to understand how liquidity is measured in a two-token pool.

That journey begins in the next section.