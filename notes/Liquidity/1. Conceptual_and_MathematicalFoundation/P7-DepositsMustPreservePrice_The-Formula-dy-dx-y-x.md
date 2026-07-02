# 7. Why Deposits Must Preserve Price (`dy/dx = y/x`)

## 🎯 Goal

Derive the equation that determines **exactly how much of the second token must be deposited** when adding liquidity.

By the end of this section, you'll understand why

```text
dy / dx = y / x
```

is not an arbitrary Uniswap equation.

It is simply the mathematical expression of one rule:

> **Adding liquidity must not change the current exchange rate.**

> **Important**
>
> This chapter is **not** about LP Shares.
>
> It is purely about preserving the current price while increasing the pool's liquidity.

---

# 📌 The Question We Left Unanswered

In the previous chapter, we learned that:

- Depositing only Token X changes the price.
- Depositing only Token Y also changes the price.
- Therefore, liquidity providers must deposit **both assets**.

This naturally raises another question.

Suppose the current pool contains:

```text
100 ETH

100,000 USDC
```

Alice wants to deposit:

```text
10 ETH
```

> **Exactly how much USDC must she also deposit?**

Not approximately.

Not "around 10,000."

Exactly.

---

# 🤔 What Are We Trying To Preserve?

Before deriving any equation, ask a simple question.

> **What property of the pool should remain unchanged?**

The answer is:

> **The exchange rate.**

Before adding liquidity:

```text
100 ETH

100,000 USDC
```

Price:

```text
100,000 / 100

=

1,000 USDC per ETH
```

After adding liquidity, we still want:

```text
1 ETH = 1,000 USDC
```

The pool can become larger.

The reserves can increase.

But the exchange rate must remain identical.

---

# 📐 Generalizing The Pool

Instead of using concrete numbers, let's define variables.

Current reserves:

```text
x = Amount of Token X

y = Amount of Token Y
```

Alice wants to deposit:

```text
dx = Additional Token X

dy = Additional Token Y
```

After adding liquidity, the pool becomes:

```text
x + dx

y + dy
```

---

# 📌 Writing The Price Equation

Before adding liquidity:

```text
Price = y / x
```

After adding liquidity:

```text
Price = (y + dy) / (x + dx)
```

Since the price must remain unchanged:

```text
(y + dy) / (x + dx)

=

y / x
```

---

# 🧠 Biggest Realization

This equation is **not** a Uniswap formula.

It is simply the mathematical translation of one sentence:

> **The price before adding liquidity must equal the price after adding liquidity.**

Everything that follows is just algebra.

---

# 📐 Step 1 — Cross Multiply

Starting from:

```text
(y + dy) / (x + dx)

=

y / x
```

Cross multiply.

```text
x(y + dy)

=

y(x + dx)
```

---

# 📐 Step 2 — Expand Both Sides

Expand both expressions.

Left side:

```text
xy + xdy
```

Right side:

```text
yx + ydx
```

Therefore:

```text
xy + xdy

=

yx + ydx
```

---

# 📐 Step 3 — Cancel Common Terms

Notice that:

```text
xy = yx
```

These terms appear on both sides.

Cancel them.

Leaving:

```text
xdy

=

ydx
```

---

# 📐 Step 4 — Rearrange

Divide both sides by:

```text
x × dx
```

Giving:

```text
dy / dx

=

y / x
```

---

# ✅ Final Equation

```text
dy / dx = y / x
```

This is one of the most fundamental equations in Uniswap V2.

---

# 📖 Understanding The Variables

| Symbol | Meaning |
|---------|----------|
| **x** | Current reserve of Token X. |
| **y** | Current reserve of Token Y. |
| **dx** | Amount of Token X being added. |
| **dy** | Amount of Token Y being added. |
| **y / x** | Current reserve ratio (current exchange rate). |
| **dy / dx** | Ratio of tokens being deposited. |

---

# 💡 Reading The Equation In Plain English

Instead of looking at symbols, simply read it like this:

> **The ratio of the deposited tokens must equal the ratio of the existing reserves.**

Or even simpler:

> **Deposit tokens in the same proportion that already exists in the pool.**

---

# 📊 Example 1 — Starting With Token X

Current pool:

```text
100 ETH

100,000 USDC
```

Current ratio:

```text
100,000 / 100

=

1,000
```

Alice wants to deposit:

```text
10 ETH
```

Using the equation:

```text
dy / 10

=

100,000 / 100
```

Simplify:

```text
dy / 10

=

1,000
```

Multiply both sides by 10.

```text
dy

=

10 × 1,000

=

10,000 USDC
```

After depositing:

```text
110 ETH

110,000 USDC
```

Price before:

```text
100,000 / 100

=

1,000
```

Price after:

```text
110,000 / 110

=

1,000
```

The price remains unchanged.

---

# 📊 Example 2 — Starting With Token Y

The same equation also works in reverse.

Suppose Alice instead says:

> **"I want to deposit 20,000 USDC."**

How much ETH must she also deposit?

Current pool:

```text
100 ETH

100,000 USDC
```

Known values:

```text
dy = 20,000

y = 100,000

x = 100
```

Using:

```text
dy / dx

=

y / x
```

Substitute:

```text
20,000 / dx

=

100,000 / 100
```

Simplify:

```text
20,000 / dx

=

1,000
```

Multiply both sides by `dx`.

```text
20,000

=

1,000 × dx
```

Divide by 1,000.

```text
dx

=

20 ETH
```

After depositing:

```text
120 ETH

120,000 USDC
```

Price before:

```text
100,000 / 100

=

1,000
```

Price after:

```text
120,000 / 120

=

1,000
```

Again, the exchange rate remains exactly the same.

---

# 🧠 Another Huge Realization

The equation is completely symmetric.

You can start by choosing either token.

```text
Choose dx

↓

Calculate dy
```

or

```text
Choose dy

↓

Calculate dx
```

The second token amount is **not** an independent choice.

Once you decide the amount of one token, the amount of the other token is completely determined by the pool's current reserve ratio.

---

# 🔍 How Uniswap Uses This

This is exactly what the Router's `quote()` function does.

It takes:

- One desired token amount.
- The current reserves.

Then calculates the exact amount of the second token required to preserve the current exchange rate.

The Router is simply implementing this equation.

---

# ⚠️ Common Misconceptions

### ❌ I can freely choose both deposit amounts.

No.

You may freely choose **one** token amount.

The second amount is dictated by the current reserve ratio.

---

### ❌ This equation changes the price.

No.

Its entire purpose is to **prevent** the price from changing.

---

### ❌ This equation is unique to Uniswap.

No.

It follows naturally from one requirement:

> **The exchange rate before and after adding liquidity must remain identical.**

---

# 🧠 Biggest Realizations

- Liquidity providers must preserve the current reserve ratio.
- The exchange rate before and after adding liquidity must remain identical.
- `dy / dx = y / x` is simply the mathematical expression of preserving the price.
- Once one deposit amount is chosen, the other is automatically determined.
- The Router's `quote()` function is a direct implementation of this equation.

---

# 🔗 Bridge To The Next Section

We now know **how** liquidity must be added:

- Both assets must be deposited.
- They must be deposited in the current reserve ratio.

However, another important question remains.

> **If a pool contains two different assets, how do we represent its total liquidity using a single value?**

To answer that, we need to define a **Liquidity Function**.

In the next section, we'll introduce:

```text
F(x, y) = L
```

and explore different ways to measure the liquidity of a two-token pool before arriving at Uniswap V2's elegant choice:

```text
L = √(xy)
```