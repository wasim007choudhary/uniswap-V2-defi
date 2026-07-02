# 3. Pool Shares (Single Asset)

## 🎯 Goal

Understand **why Pool Shares exist**, **what they represent**, and **why they are necessary** before deriving any mathematical formulas.

> **Important**
>
> In this section, we'll intentionally use a **single-asset pool (USDC only)** because it is much easier to understand the concept of ownership.
>
> We'll introduce two-token pools and Uniswap-specific mathematics later.

---

# 📌 The Question We Left Unanswered

In the previous section, we learned that anyone can become a Liquidity Provider by depositing assets into a liquidity pool.

Now imagine the following happens.

```
Alice deposits   300 USDC

Bob deposits     500 USDC

Charlie deposits 200 USDC
```

The pool now contains:

```
1,000 USDC
```

This immediately raises an important question.

> **How does the protocol remember who owns what?**

Suppose six months later Bob wants to withdraw his liquidity.

How does the protocol know that part of the pool belongs to Bob?

The pool only stores one balance:

```
Pool Balance = 1,000 USDC
```

It does **not** physically separate:

```
Alice's USDC

Bob's USDC

Charlie's USDC
```

Once deposited, every token is mixed together.

So...

> **How is ownership tracked?**

---

# 🤔 A Naive Solution

One possible solution would be to simply remember everyone's deposits.

For example, the protocol could store something similar to:

```solidity
Alice   => 300 USDC
Bob     => 500 USDC
Charlie => 200 USDC
```

At first glance, this seems reasonable.

If Bob later wants to withdraw, the protocol simply returns:

```
500 USDC
```

Problem solved...

Or is it?

---

# ❓Let's Test That Idea

Imagine the pool initially contains:

```
Alice   = 300 USDC

Bob     = 500 USDC

Charlie = 200 USDC

----------------------

Pool = 1,000 USDC
```

Now suppose the pool earns yield.

Perhaps it lends assets, earns interest, or generates profits.

After some time, the pool balance becomes:

```
1,100 USDC
```

Notice something important.

Nobody deposited another 100 USDC.

The pool itself became more valuable.

Now Bob decides to withdraw.

Should Bob receive:

```
500 USDC
```

because that's what he originally deposited?

Or should he receive **more**, since the entire pool has grown?

---

# 🚨 Why Remembering Deposits Doesn't Work

If the protocol only remembers:

```
Bob deposited:

500 USDC
```

then Bob will always receive:

```
500 USDC
```

That is unfair.

Why?

Because Bob doesn't simply own his original deposit anymore.

He owns **part of the pool**.

If the pool grows, Bob's ownership should benefit from that growth.

Likewise, if the pool shrinks, Bob should bear his share of the loss.

---

# 💡 The Big Shift In Thinking

At this point, our thinking changes completely.

Instead of asking:

> **"How many tokens did Bob deposit?"**

the protocol asks:

> **"What percentage of the pool does Bob own?"**

Those are two completely different questions.

For example,

Initially:

```
Pool = 1,000 USDC

Bob deposited = 500 USDC
```

Bob owns:

```
50% of the pool
```

Later, the pool grows to:

```
1,100 USDC
```

Bob still owns:

```
50% of the pool
```

Notice what remained constant.

Not the number of USDC.

The **ownership percentage**.

---

# 💡 What Are Pool Shares?

We've now established that remembering deposits is not enough.

The protocol must remember **ownership** instead.

So how does it do that?

The answer is **Pool Shares**.

> **Pool Shares are tokens that represent a Liquidity Provider's proportional ownership of the liquidity pool.**

Notice the wording carefully.

Pool Shares do **not** represent:

> "How many tokens you deposited."

Instead, they represent:

> **"What fraction of the pool you own."**

That distinction is one of the most important concepts in liquidity provisioning.

---

# 📖 Example

Suppose the pool contains:

```
1,000 USDC
```

Three users provide liquidity.

```
Alice deposits   300 USDC

Bob deposits     500 USDC

Charlie deposits 200 USDC
```

Ownership now looks like this.

| Liquidity Provider | Deposit | Ownership |
|--------------------|--------:|----------:|
| Alice | 300 USDC | 30% |
| Bob | 500 USDC | 50% |
| Charlie | 200 USDC | 20% |

Instead of remembering:

```
Alice → 300

Bob → 500

Charlie → 200
```

the protocol is really interested in remembering:

```
Alice → 30%

Bob → 50%

Charlie → 20%
```

Pool Shares are simply the representation of those ownership percentages.

---

# ❓Why Not Just Store Percentages?

This raises another natural question.

> **If ownership is all that matters, why not simply store everyone's percentage?**

For example,

```
Alice → 30%

Bob → 50%

Charlie → 20%
```

instead of issuing Pool Shares?

Conceptually, this might work.

However, ownership itself needs to be something that can move from one person to another.

Suppose Bob decides he no longer wants to provide liquidity.

Or suppose Bob wants to transfer his ownership to David.

If ownership were stored only as percentages, the protocol would need to manually update those percentages every time ownership changed.

Instead, Uniswap represents ownership using **Pool Shares (LP Tokens).**

Owning the shares means owning that percentage of the pool.

Transfer the shares.

↓

Transfer the ownership.

This makes ownership portable and much easier to manage.

We'll study the implementation of these tokens later during the Solidity section.

For now, simply understand the idea.

---

# ⚠️ Common Misconceptions

### ❌ Pool Shares represent the amount originally deposited.

No.

They represent **ownership**, not deposits.

---

### ❌ If the pool grows, LPs still only own their original deposit.

No.

LPs own a percentage of the pool.

As the pool grows, the value represented by their shares also grows.

---

### ❌ The protocol remembers everyone's deposits forever.

No.

The protocol ultimately cares about **ownership**, not historical deposits.

---

# 🧠 Biggest Realizations

- Deposits are only the starting point.
- Ownership is what actually matters.
- Pool Shares represent ownership of the liquidity pool—not the original deposit.
- If the pool grows or shrinks, the value represented by each share changes.
- Your ownership percentage remains the same unless liquidity is added or removed.

---

# 🔗 Bridge To The Next Section

We now understand what Pool Shares are.

A new question naturally arises.

Suppose the pool currently contains:

```
Pool Value = 1,000 USDC

Total Pool Shares = 1,000
```

A new Liquidity Provider deposits:

```
100 USDC
```

How many Pool Shares should they receive?

Should it always be:

```
100 Shares?
```

What if the pool has already earned profits?

What if the pool value has increased?

How do we calculate the correct number of shares while keeping ownership fair for everyone?

Answering that question leads us directly into the **Mint Share Formula**, where the mathematics of liquidity begins.