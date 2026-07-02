# 5. Burn Share Formula

## 🎯 Goal

Understand **how much liquidity (tokens)** a Liquidity Provider should receive when they burn their Pool Shares.

> **Important**
>
> We are still using a **single-asset pool (USDC only)**.
>
> This keeps the mathematics focused entirely on ownership. Later, we'll extend these ideas to Uniswap's two-token pools.

---

# 📌 The Question We Left Unanswered

In the previous section, we answered:

> **"If someone adds liquidity, how many Pool Shares should they receive?"**

Now we ask the opposite question.

Suppose Bob already owns Pool Shares.

He wants to leave the pool.

He burns some of his Pool Shares.

> **How many USDC should the pool return to Bob?**

---

# 📖 Example

Suppose the pool currently contains:

```text
Pool Value = 1,210 USDC

Total Pool Shares = 1,100
```

Bob owns:

```text
500 Pool Shares
```

Now Bob decides to burn:

```text
100 Pool Shares
```

A natural question arises.

> **How many USDC should Bob receive?**

---

# 🤔 A Naive Solution

Someone might immediately think:

> **"If Bob burns 100 Pool Shares, simply give him 100 USDC."**

At first glance, this seems reasonable.

But...

Is it always fair?

---

# 🚨 The Problem

Remember what we learned in the previous section.

Pool Shares are **not always worth one token.**

In this example:

```text
Pool Value

1,210 USDC

↓

Total Shares

1,100
```

Therefore:

```text
1 Pool Share

=

1,210 / 1,100

=

1.1 USDC
```

So:

```text
100 Pool Shares
```

are actually worth:

```text
110 USDC
```

Returning only:

```text
100 USDC
```

would unfairly reduce Bob's ownership.

---

# 💡 The Big Shift

Notice something interesting.

During minting we asked:

> **How many Pool Shares should correspond to newly added liquidity?**

Now we're asking the exact opposite question.

> **Given a certain number of Pool Shares, how much liquidity should those shares redeem?**

Minting converts:

```text
Liquidity

↓

Pool Shares
```

Burning converts:

```text
Pool Shares

↓

Liquidity
```

They are opposite operations.

---

# 🧠 First Major Realization

Minting answers:

> **"How much ownership should this deposit receive?"**

Burning answers:

> **"How much liquidity does this ownership represent?"**

They are simply two sides of the same idea.

---

# 🤔 What Should Be Fair?

Suppose the pool currently contains:

```text
Pool Value = 1,210 USDC

Total Shares = 1,100
```

Bob burns:

```text
100 Pool Shares
```

Forget formulas.

Ask yourself one question.

> **What percentage of the ownership is Bob giving back?**

Simply:

```text
100 / 1,100

=

9.09%
```

Bob is surrendering:

> **9.09% of the Pool Shares.**

Now ask the fairness question.

> **If Bob is giving back 9.09% of the ownership, shouldn't he receive 9.09% of the pool?**

Intuitively...

Yes.

Ownership decreases by 9.09%.

Therefore, the pool should also decrease by 9.09%.

---

# 📖 Thinking In Terms Of The Pool

Before burning:

```text
Pool Value

1,210 USDC

↓

Total Shares

1,100
```

Bob burns:

```text
100 Shares

=

9.09% of all Pool Shares
```

Therefore, the pool should decrease by:

```text
9.09%
```

How much is that?

```text
9.09%

×

1,210

=

110 USDC
```

Therefore Bob should receive:

```text
110 USDC
```

Notice something.

We still haven't used a formula.

Everything follows naturally from fairness.

---

# 🧠 Second Major Realization

During minting we said:

> **Increase in liquidity should equal the increase in ownership.**

Now we're saying:

> **Decrease in ownership should equal the decrease in liquidity.**

It's exactly the same fairness principle viewed in reverse.

---

# 📐 Defining Our Variables

We'll use nearly the same notation as before.

| Variable | Meaning |
|----------|---------|
| **T** | Total Pool Shares before burning |
| **S** | Pool Shares being burned |
| **L₀** | Pool value before burning |
| **L₁** | Pool value after burning |

Notice:

Here **S** represents the number of Pool Shares being burned.

---

# 📌 The Fairness Principle

We concluded:

> **The percentage decrease in Pool Shares should equal the percentage decrease in the pool's value.**

That immediately gives us:

```text
(T − S) / T = L₁ / L₀
```

Notice how beautifully this mirrors the Mint equation.

Mint:

```text
(T + S) / T = L₁ / L₀
```

Burn:

```text
(T − S) / T = L₁ / L₀
```

One creates ownership.

The other removes ownership.

---

# 📐 Solving The Equation

Our goal is **not** to solve for `S`.

We already know how many Pool Shares are being burned.

Instead, we want to determine:

```text
L₀ − L₁
```

which represents the amount of liquidity leaving the pool.

---

## Step 1 — Cross Multiply

Starting from:

```text
(T − S) / T = L₁ / L₀
```

Multiply both sides by `L₀`.

```text
L₁ = ((T − S) / T) × L₀
```

---

## Step 2 — Rearrange

Subtract `L₁` from both sides.

```text
L₀ − L₁ = L₀ − ((T − S) / T) × L₀
```

Factor out `L₀`.

```text
L₀ − L₁ = (1 − (T − S) / T) × L₀
```

---

## Step 3 — Simplify

Rewrite:

```text
1
```

as:

```text
T / T
```

Now:

```text
(T / T) − ((T − S) / T)
```

becomes:

```text
(T − (T − S)) / T
```

Distribute the negative sign.

```text
(T − T + S) / T
```

The `T`s cancel.

Leaving:

```text
S / T
```

---

# ✅ Final Burn Formula

```text
L₀ − L₁ = (S / T) × L₀
```

---

# 📖 Understanding The Formula

| Symbol | Meaning |
|--------|---------|
| **L₀** | Pool value before burning Pool Shares. |
| **L₁** | Pool value after burning Pool Shares. |
| **L₀ − L₁** | Liquidity returned to the Liquidity Provider. |
| **S** | Pool Shares being burned. |
| **T** | Total Pool Shares before burning. |
| **S / T** | Percentage of ownership being surrendered. |

---

# 💡 Reading The Formula In Plain English

Instead of looking at symbols, simply read it like this:

> **Calculate what percentage of the Pool Shares are being burned, then return that same percentage of the pool's liquidity.**

Or even shorter:

> **Burn X% of the ownership → Receive X% of the pool.**

---

# 📊 Worked Example

Suppose:

```text
Pool Value (L₀) = 1,210 USDC

Total Shares (T) = 1,100

Shares Burned (S) = 100
```

Percentage burned:

```text
100 / 1,100

=

9.09%
```

Liquidity returned:

```text
9.09%

×

1,210

=

110 USDC
```

Exactly what our intuition predicted before deriving the equation.

---

# 💡 Common Confusion — "Why Is There a Twist in Minting but Not in Burning?"

While deriving the Mint and Burn formulas, an important conceptual difference appeared.

At first, both operations seem perfectly symmetric.

However, there is a subtle twist during **minting** that does **not** exist during **burning**.

Understanding why is one of the biggest "aha!" moments when learning LP shares.

---

# 🤔 The Confusion

During minting we said:

> **If the pool grows by 10%, mint 10% more Pool Shares.**

However...

That **does not** mean the new Liquidity Provider owns **10%** of the pool.

Why?

But during burning we say:

> **Burn 10% of the Pool Shares and receive 10% of the pool.**

That statement **is** correct.

So why is one different from the other?

---

# 🌱 Minting

Suppose the pool currently contains:

```text
Pool Value = 1,100 USDC

Total Shares = 1,000
```

David deposits:

```text
110 USDC
```

The pool increased by:

```text
110 / 1,100

=

10%
```

Therefore, the **total share supply** should also increase by:

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

Those **100 newly created shares** are given entirely to David.

Now David owns:

```text
100 / 1,100

=

9.09%
```

Notice something.

Although the pool increased by **10%**, David does **not** own **10%** of the enlarged pool.

He owns approximately **9.09%**.

---

# 🤯 Why?

Because **minting creates new ownership.**

When new shares are created, the **total share supply increases**.

The denominator changes.

Before minting:

```text
Total Shares

=

1,000
```

After minting:

```text
Total Shares

=

1,100
```

Since the denominator became larger, David's ownership is calculated using the new total share supply.

That is the "twist" in the Mint formula.

---

# 🌱 Burning

Now suppose the pool contains:

```text
Pool Value = 1,210 USDC

Total Shares = 1,100
```

Bob burns:

```text
110 Shares
```

The percentage of ownership Bob is giving back is:

```text
110 / 1,100

=

10%
```

Therefore Bob receives:

```text
10%

×

1,210

=

121 USDC
```

This time, there is **no twist**.

Bob burns **10%** of the ownership.

Therefore, Bob receives **10%** of the pool.

Exactly as expected.

---

# 💡 Why Isn't There A Twist Here?

Because during burning, ownership already exists.

Bob is simply redeeming part of his ownership.

When calculating how much Bob should receive:

- The current Pool Shares already exist.
- The current pool already exists.
- We simply determine what percentage Bob owns.

Only **after** Bob receives his tokens do the Pool Shares and pool value decrease.

Unlike minting, no new ownership is being created.

---

# ⚖️ The Fundamental Difference

## Minting

Creates new ownership.

Therefore:

- The total Pool Share supply increases.
- The denominator changes.
- The new Liquidity Provider does **not** end up owning the same percentage by which the old pool increased.

---

## Burning

Redeems existing ownership.

Therefore:

- No new ownership is created.
- The ownership percentage is measured against the current pool.
- Burning **X%** of the Pool Shares returns **X%** of the current pool.

---

# 🧠 Biggest Realization

The asymmetry comes from **creating** ownership versus **redeeming** ownership.

Minting creates new Pool Shares.

Burning destroys existing Pool Shares.

Because minting changes the total share supply, there is a subtle ownership adjustment.

Because burning simply redeems existing ownership, there is no such adjustment.

---

# 🔑 One Sentence To Remember

> **Mint:** The pool may grow by 10%, but the new Liquidity Provider does not necessarily own 10% of the enlarged pool because new Pool Shares are created and the total share supply increases.

> **Burn:** Burning 10% of the current Pool Shares means receiving exactly 10% of the current pool because ownership is simply being redeemed, not created.

---

# ⚠️ Common Misconceptions

### ❌ Burning 100 Pool Shares always returns 100 tokens.

No.

The value of a Pool Share changes as the pool grows or shrinks.

The same number of Pool Shares may return more or fewer tokens depending on the current pool value.

---

### ❌ Pool Shares represent deposited tokens.

No.

Pool Shares represent ownership.

The amount of liquidity returned depends on the current value of that ownership—not on the amount originally deposited.

---

### ❌ The Burn Formula is unrelated to the Mint Formula.

No.

The Burn Formula is simply the reverse operation.

Minting converts:

```text
Liquidity

↓

Pool Shares
```

Burning converts:

```text
Pool Shares

↓

Liquidity
```

Both preserve proportional ownership.

---

# 🧠 Biggest Realizations

- Burning Pool Shares means surrendering ownership of the pool.
- The percentage of ownership burned determines the percentage of liquidity returned.
- Pool Shares represent ownership—not deposited tokens.
- The Burn Formula is the exact mirror image of the Mint Formula.
- Both formulas are built on the same fairness principle.

---

# 🔗 Bridge To The Next Section

So far, we've intentionally used a **single-asset pool** because it makes ownership and Pool Shares easy to understand.

However, Uniswap V2 pools are fundamentally different.

Every pool contains **two assets**, such as:

```text
ETH

+

USDC
```

This immediately raises a new question.

> **Why does Uniswap require Liquidity Providers to deposit two different tokens instead of just one?**

Understanding that answer is essential before we can adapt the Mint and Burn formulas to a real Uniswap V2 pool.

That is exactly what we'll explore next.

> **6. Why Liquidity Requires Two Assets**