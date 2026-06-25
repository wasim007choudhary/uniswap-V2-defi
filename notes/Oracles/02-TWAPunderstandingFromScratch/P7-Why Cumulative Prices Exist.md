# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

## Part 7 — The Genius of Uniswap: Why Cumulative Prices Exist

---

# Introduction

So far we've mathematically derived the TWAP equation.

Our numerator is:

```text
          n−1
          Σ
i = k
ΔTᵢ × Pᵢ
```

which simply means

> Add together **Price × Time** for every observation.

At this point, another question naturally arises.

---

# The Question

Where does Uniswap get all these prices from?

We've been pretending that somewhere inside the Pair contract we have something like

```text
P₀

P₁

P₂

P₃

...

P₁₀₀₀
```

stored.

And also

```text
ΔT₀

ΔT₁

ΔT₂

...

ΔT₁₀₀₀
```

stored somewhere.

But...

Open the Pair contract.

Do you see

```solidity
uint256[] prices;
```

No.

---

Do you see

```solidity
mapping(uint256 => uint256) historicalPrices;
```

No.

---

Do you see

```solidity
Price[] history;
```

No.

---

Nothing exists.

So...

How can Uniswap possibly calculate

```text
Σ(ΔT × Price)
```

if it doesn't remember every historical price?

This question led to one of the smartest design decisions in Uniswap V2.

---

# Imagine If Uniswap Stored Every Price

Suppose a swap happens

```text
Every second.
```

One day contains

```text
86,400 seconds.
```

That means

```text
86,400

price updates.
```

Every single day.

---

Now think bigger.

One year contains approximately

```text
31,536,000

seconds.
```

Imagine storing

```text
Price #1

Price #2

Price #3

...

Price #31,536,000
```

inside Ethereum storage.

Question:

Would this be cheap?

Absolutely not.

---

# Why Is This A Problem?

Ethereum storage is one of the most expensive operations in the EVM.

Every new storage write costs gas.

Imagine every swap doing something like

```text
Swap

↓

Store Price

↓

Store Time

↓

Store Another Price

↓

Store Another Time
```

Forever.

The storage would continue growing.

Gas costs would become enormous.

---

# Child Analogy

Imagine your teacher asks

> How many pages have you read this year?

Method 1

Write down

```text
Day 1

↓

2 pages
```

---

```text
Day 2

↓

5 pages
```

---

```text
Day 3

↓

1 page
```

---

Continue doing this for

```text
365 days.
```

You now have a huge notebook.

---

Method 2

Keep only one running total.

Day 1

```text
Total = 2
```

---

Day 2

```text
Total = 7
```

---

Day 3

```text
Total = 8
```

---

Question:

Which method uses less storage?

Obviously

```text
Method 2.
```

---

# Programmer Analogy

Suppose you're keeping track of game scores.

Bad approach:

```solidity
uint256[] scores;

scores.push(score1);
scores.push(score2);
scores.push(score3);
```

The array keeps growing forever.

---

Better approach:

```solidity
uint256 totalScore;

totalScore += score;
```

Only one variable.

Storage never grows.

---

# Uniswap Thinks The Same Way

Instead of storing

```text
Price₀

Price₁

Price₂

Price₃

...

Priceₙ
```

Uniswap stores only

```text
One running total.
```

This running total is called

```text
Cumulative Price.
```

---

# Let's Look At Our Formula Again

Our numerator is

```text
ΔT₀ × P₀

+

ΔT₁ × P₁

+

ΔT₂ × P₂

+

ΔT₃ × P₃

+

...
```

Notice something.

After we compute

```text
ΔT₀ × P₀
```

do we ever need it separately again?

No.

Eventually it will simply be added to the total.

Once it's added,

its individual value is no longer important.

---

# A Better Idea

Instead of remembering

```text
50

300

120

700

...
```

Why not immediately do

```text
Running Total

+=

Price × Time
```

every time reserves change?

Then after one year,

our running total already equals

```text
Σ(Price × Time)
```

We never need to calculate the summation later.

We've been calculating it continuously all along.

This is exactly what cumulative price is.

---

# Child Analogy

Imagine collecting candies.

Monday

```text
5 candies.
```

Tuesday

```text
3 candies.
```

Wednesday

```text
2 candies.
```

Method 1

Remember

```text
Monday = 5

Tuesday = 3

Wednesday = 2
```

---

Method 2

Remember only

```text
Monday

Total = 5
```

---

Tuesday

```text
Total = 8
```

---

Wednesday

```text
Total = 10
```

You no longer remember

```text
Monday = 5
```

individually.

But you know

```text
Total = 10.
```

That's all you need.

---

# The Big Realization

Our TWAP numerator is

```text
Σ(Price × Time)
```

Instead of calculating that sum later,

Uniswap keeps updating a running total every time reserves change.

Conceptually,

after every reserve update,

it does something like

```text
Running Total

+=

Current Price

×

Time Elapsed
```

Notice something incredible.

This running total is already

```text
Σ(Price × Time).
```

The protocol doesn't have to replay history.

History has already been accumulated.

---

# This Is What `price0CumulativeLast` Represents

Later, when we study the Pair contract, we'll see code similar to

```solidity
price0CumulativeLast += currentPrice * timeElapsed;
```

At first glance,

this looks mysterious.

But now we can translate it into plain English.

It simply means

```text
Running Total

+=

Price × Time
```

Exactly what we've been deriving mathematically.

---

# Why Is This Brilliant?

Instead of storing

```text
Price₁

Price₂

Price₃

...

Price₁₀₀₀₀₀₀
```

Uniswap stores

```text
One cumulative number.
```

Storage stays constant.

Gas remains efficient.

The protocol never needs giant arrays of historical prices.

---

# Another Huge Realization

Everything we've learned so far has secretly been preparing us for this moment.

Earlier,

we derived

```text
Σ(ΔT × Price)
```

using mathematics.

Uniswap simply computes that same value

incrementally,

one reserve update at a time.

Instead of

```text
Calculate later.
```

it says

```text
Keep updating continuously.
```

This is one of the smartest optimizations in the entire protocol.

---

# Our Discussion

During our learning session, we asked:

> **Where are all the historical prices stored?**

Answer:

They aren't.

Only the cumulative total is stored.

---

We also asked:

> **Wouldn't storing every historical price consume huge amounts of storage?**

Answer:

Yes.

Ethereum storage is expensive.

Storing every historical price forever would be extremely inefficient.

Keeping a single cumulative value avoids this problem completely.

---

# Important Clarification

Notice that

```text
price0CumulativeLast
```

does **NOT** store

```text
Current Price.
```

It also does **NOT** store

```text
Average Price.
```

Instead,

it stores

```text
The running sum of

Price × Time.
```

This distinction is extremely important.

We'll use this running sum in the next lesson to compute the average price between any two moments in time.

---

# Mental Model

Instead of thinking

```text
Historical Prices
```

think

```text
Running Total.
```

Instead of

```text
Store Every Price
```

think

```text
Accumulate Every Contribution.
```

---

# Key Takeaways

- Uniswap **does not** store every historical price.
- Storing every price would consume enormous storage and gas.
- Instead, Uniswap stores a **running cumulative total**.
- Conceptually, every reserve update performs:

```text
Running Total += Price × Time
```

- That running total is exactly the mathematical numerator we derived:

```text
Σ(ΔT × Price)
```

- This cumulative value is later used to calculate TWAP efficiently without replaying the entire price history.

---

> **Next Chapter:** Cumulative Price (`price0CumulativeLast`) — We'll dissect the actual Pair contract implementation line by line and derive why TWAP can be calculated using only **two cumulative snapshots**:

```text
TWAP

=

(Cumulative₂ − Cumulative₁)

/

(Time₂ − Time₁)
```

instead of replaying every historical price.