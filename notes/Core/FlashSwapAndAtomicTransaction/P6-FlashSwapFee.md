# Topic 6 - Flash Swap Fee

One of the first questions that comes to mind is:

> **Why is there a flash swap fee at all?**

The answer is simple.

Flash swaps are borrowing **other people's liquidity**.

That liquidity belongs to the liquidity providers (LPs).

Whenever someone uses that liquidity—whether through a normal swap or a flash swap—they pay the standard Uniswap V2 liquidity provider fee.

**Flash swaps do not have a special fee.**

They simply pay the **same 0.3% LP fee** that every normal swap pays.

---

# Why Charge A Fee?

Imagine flash swaps were free.

```text
Borrow LP Liquidity

↓

Pay Nothing

↓

Return Liquidity
```

Liquidity providers would earn nothing while others continuously used their capital.

Instead, Uniswap says:

> **"If you use liquidity supplied by LPs, you must compensate them."**

That compensation is the standard **0.3% liquidity provider fee**.

---

# Is The Fee For Gas?

No.

Gas and swap fees are completely different things.

Gas is paid to Ethereum validators (or block builders).

The flash swap fee stays inside the liquidity pool and benefits the liquidity providers.

---

# Is The Flash Swap Fee Different From The Normal Swap Fee?

No.

This is one of the biggest misconceptions.

There are **not** two separate fees.

```text
Normal Swap Fee

0.3%

Flash Swap Fee

0.3%
```

These are the **same fee**.

The only difference is **when** the payment happens.

---

# Normal Swap

In a normal swap:

```text
Pay Tokens

↓

Fee Applied

↓

Receive Output Tokens
```

The fee is taken before the output tokens are received.

---

# Flash Swap

In a flash swap:

```text
Borrow Tokens

↓

Execute Custom Logic

↓

Repay Borrowed Tokens + LP Fee
```

The fee is paid at the end instead of the beginning.

Economically, however, both operations pay exactly the same liquidity provider fee.

---

# Flash Swap Fee Equation

The flash swap fee equation is:

```text
x₀ − dx₀ + 0.997dx₁ ≥ x₀
```

We have already discussed:

* `x × y = k`
* `dx`
* `dy`
* `997 / 1000`
* `getAmountOut()`
* `getAmountIn()`

in previous notes.

Visit: **notes/Periphery/Library/getAmountOut & getAmountsOut** also see their natspecs, and also visit notes of **getAmountIn** and **getAmountsIn** to fully understand all these derivations and **x * y = k** !Recommended by me before learning about flash swap fee!

Here, we will focus only on what each variable means in the context of a flash swap.

---

# Variable Definitions

### `x₀`

The amount of **Token X** inside the Pair **before** the flash swap begins.

---

### `dx₀`

The amount of **Token X** borrowed from the Pair.

Since these tokens leave the Pair, they are subtracted.

```text
Pair Balance

1000 DAI

↓

Borrow 100 DAI

↓

900 DAI
```

This is represented by:

```text
x₀ − dx₀
```

---

### `dx₁`

The amount of **Token X** returned to the Pair.

Remember:

```text
dx₁

=

Borrowed Amount

+

LP Fee
```

Therefore:

```text
dx₁ > dx₀
```

because we always repay more than we borrowed.

---

### `0.997 × dx₁`

Just like a normal swap, only **99.7%** of the repayment contributes toward satisfying the invariant.

The remaining **0.3%** is the liquidity provider fee.

This is exactly the same fee mechanism used by normal swaps.

There is no special flash swap fee.

---

# Understanding The Entire Equation

```text
x₀ − dx₀ + 0.997dx₁ ≥ x₀
```

can be read in plain English as:

> **Start with the Pair's original balance, subtract the borrowed tokens because they left the pool, then add back the effective repayment (after accounting for the standard 0.3% LP fee). The Pair's effective balance must be at least as large as it was before the flash swap started.**

If this condition is true:

```text
Flash Swap Succeeds ✅
```

Otherwise:

```text
Flash Swap Reverts ❌
```

---

# Why Isn't The Equation Simply `+ dx₁`?

A common question is:

> **If we're returning `dx₁`, why doesn't the equation simply add `dx₁`?**

Because Uniswap always applies the standard liquidity provider fee.

Only **99.7%** of the repayment contributes toward satisfying the protocol's invariant.

Therefore:

```text
0.997 × dx₁
```

is used instead of:

```text
dx₁
```

This makes flash swaps follow the exact same fee model as ordinary swaps.

---

# Final Mental Model

Flash swaps do **not** introduce a brand-new fee model.

They simply reuse the exact same **0.3% liquidity provider fee** that exists for every normal swap.

The only difference is the execution order.

```text
Normal Swap

Pay

↓

Receive Tokens
```

```text
Flash Swap

Borrow

↓

Use Tokens

↓

Repay + LP Fee
```

The economics remain exactly the same.

Only the timing of the payment changes.
-----
-----
----
#CURIOSITY_QUESTION
# 🎯 WHY MULTIPLICATION, NOT ADDITION?

## The Short Answer

**The fee is multiplied because it's a PERCENTAGE of what you borrow, not a flat fee. This keeps it FAIR for everyone.**

---

## 🧒 Simple Example

### Flat Fee (Addition) = UNFAIR:
- Borrow $1 → Pay $1 fee (100%!)
- Borrow $100 → Pay $1 fee (1%)
- Borrow $1000 → Pay $1 fee (0.1%)

**Rich people pay almost nothing, poor people get crushed!**

---

### Percentage Fee (Multiplication) = FAIR:
- Borrow $1 → Pay $0.003 fee (0.3%)
- Borrow $100 → Pay $0.30 fee (0.3%)
- Borrow $1000 → Pay $3.00 fee (0.3%)

**Everyone pays the SAME percentage!**

---

## 📖 Analogy

**Flat Fee:** Everyone pays $1 to enter a store, whether you buy 1 candy or 100.

**Percentage Fee:** You pay 3 cents for every $10 you spend. Fair for everyone.

---

## 💰 The Math

```solidity
// Addition (Flat) - BAD
fee = 1; // Always $1
repay = borrowed + 1;

// Multiplication (Percentage) - GOOD
fee = (borrowed * 3) / 1000; // 0.3%
repay = borrowed + fee;
```
## 🎯 Why Multiplication Wins

| Reason | Why |
|--------|-----|
| **Fairness** | Everyone pays the same percentage, regardless of loan size |
| **Risk** | Bigger loans = bigger risk = bigger fee (scales proportionally) |
| **Efficiency** | No incentive to borrow excessively just to minimize fee impact |
| **Industry Standard** | All major DeFi protocols use percentage-based fees |

---

## 🎓 Bottom Line

**Multiplication = Fairness for ALL!** 🎯