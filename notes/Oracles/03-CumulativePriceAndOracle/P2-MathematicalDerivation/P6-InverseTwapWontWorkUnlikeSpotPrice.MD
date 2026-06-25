### Part 2.6 — Why `TWAP(token1) ≠ 1 / TWAP(token0)`

This is the final mathematical concept before we begin reading the Uniswap V2 Solidity implementation.

Although it looks like a small topic, it answers one of the most important design decisions in the Pair contract.

Earlier, we learned that the Pair contract stores two cumulative prices.

```solidity
price0CumulativeLast
price1CumulativeLast
```

At first, this seems unnecessary.

A natural question is:

> **"If we already know one cumulative price, can't we simply calculate the other one by taking its inverse?"**

Before answering that question, let's first understand why this works perfectly for **spot price**.

---

# Spot Price Works Differently

Suppose our Pair contains

```text
token0 = ETH

token1 = USDC
```

Assume the reserves are

```text
100 ETH

200,000 USDC
```

The spot price of ETH is

```text
USDC
────────
 ETH
```

which is

```text
200,000

────────

100

=

2000
```

This means

> **1 ETH = 2000 USDC**

Now suppose another user asks

> **"I don't want the price of ETH. I want the price of USDC."**

Notice something.

The question has simply been reversed.

Instead of asking

> **How many USDC for one ETH?**

we are now asking

> **How many ETH for one USDC?**

Mathematically,

this becomes

```text
ETH
────────
USDC
```

which equals

```text
100

────────

200,000

=

0.0005
```

Notice something beautiful.

```text
1

──────

2000

=

0.0005
```

Therefore,

for **spot price**,

the following equation is completely correct.

```text
Spot Price(token1)

=

1
────────────────────
Spot Price(token0)
```

---

# Why Does This Work?

During our discussion,

a very important realization happened.

We asked ourselves,

> **"Why does taking the inverse work here?"**

The answer is surprisingly simple.

Because **spot price is only one number.**

There is

* no averaging,
* no summation,
* no time weighting.

There is simply one price.

If

```text
P = 2000
```

then

```text
1
──
P
```

is automatically the price in the opposite direction.

Nothing else is happening.

---

# Child Analogy — Chocolates

Suppose

```text
1 Chocolate = ₹20
```

Question.

How many rupees are needed for one chocolate?

Answer.

```text
₹20
```

Now reverse the question.

> **With ₹1, how many chocolates can I buy?**

The answer is

```text
1

────

20

=

0.05 chocolates
```

Notice what happened.

We simply reversed the units.

Instead of

```text
Money

────────

Chocolate
```

we now have

```text
Chocolate

────────

Money
```

Reversing the units automatically means taking the reciprocal.

This is exactly what happens with spot prices.

---

# A Natural Assumption

Since taking the inverse works perfectly for spot price,

many people naturally assume

it must also work for TWAP.

They think

```text
TWAP(token1)

=

1
──────────────────
TWAP(token0)
```

At first glance,

this looks completely reasonable.

Unfortunately,

it is **incorrect**.

---

# Let's Go Back To TWAP

Earlier,

we derived the TWAP equation from scratch.

We proved that

```text
             n−1
             Σ
            ΔTᵢPᵢ
TWAP = --------------------
            Tₙ − Tₖ
```

Notice something.

TWAP is **not one spot price.**

TWAP is

> **Many spot prices, each valid during its own time interval, averaged over the total observation period.**

This realization came directly from our discussion.

You said:

> **"TWAP is basically spot prices in their respective intervals added together and divided by the total time."**

Exactly.

That is one of the best ways to think about TWAP.

Every interval has its own spot price.

---

# Looking At One Interval

Suppose during one interval,

```text
Time 0 → 10
```

the spot price is

```text
2000
```

Question.

Can we calculate the spot price in the opposite direction?

Of course.

Simply take

```text
1

────

2000
```

This is perfectly valid.

Therefore,

during this interval,

instead of contributing

```text
ΔT₀ × 2000
```

the opposite direction contributes

```text
ΔT₀ × (1/2000)
```

Nothing strange happened.

We simply inverted the spot price for **that interval.**

---

# Looking At Another Interval

Now suppose the next interval becomes

```text
Time 10 → 20
```

with spot price

```text
1000
```

Again,

for this interval,

the opposite direction is simply

```text
1

────

1000
```

Therefore,

its contribution becomes

```text
ΔT₁ × (1/1000)
```

Again,

perfectly valid.

---

# What Is Sigma Actually Doing?

During our discussion,

you asked one of the best questions.

> **"Why doesn't the inverse work outside Sigma, but it works inside Sigma?"**

This is the key insight.

The answer is

> **Because Sigma is simply adding together whatever values we give it.**

If we give Sigma

```text
P₀

P₁

P₂
```

it calculates

```text
ΣP
```

If we instead give Sigma

```text
1/P₀

1/P₁

1/P₂
```

it calculates

```text
Σ(1/P)
```

Sigma doesn't care.

It simply adds the numbers it receives.

Nothing magical is happening.

---

# The Mistake People Make

The mistake happens **after** the averaging.

People calculate

```text
TWAP(token0)
```

and then try to do

```text
1

──────────────

TWAP(token0)
```

But this is completely different from

```text
TWAP(token1)
```

because

the reciprocal is now being applied

**after**

all the averaging has already finished.

---

# A Numerical Example

Suppose prices during three intervals are

```text
1000

2000

3000
```

The average price is

```text
(1000 + 2000 + 3000)

────────────────────

3

=

2000
```

Now invert it.

```text
1

────

2000

=

0.0005
```

Now let's calculate the opposite direction correctly.

Invert **each individual spot price first.**

```text
1/1000

1/2000

1/3000
```

Now average them.

Question.

Do we get

```text
1

────

2000 ?
```

No.

The answers are different.

---

# The Mathematical Rule

One of the most important mathematical rules is

> **The average of reciprocals is generally NOT equal to the reciprocal of the average.**

In mathematical notation,

```text
Average(1/P)

≠

1
────────────────
Average(P)
```

This single equation explains the entire misconception.

---

# Our Biggest Realization

During our discussion,

you reached an important intuition.

You said:

> **"Because it will be like spot price for the other for that time interval, and TWAP is basically spot prices in their respective intervals added together divided by the total time."**

Exactly.

This is the correct way to think about it.

Each interval has **its own spot price.**

Since each interval has one spot price,

each interval can individually be inverted.

Therefore,

inside the summation,

we naturally write

```text
ΣΔTᵢ(1/Pᵢ)
```

instead of

```text
ΣΔTᵢPᵢ
```

However,

once all those interval prices have already been averaged into one TWAP,

we can no longer recover the opposite TWAP simply by taking one reciprocal.

The individual interval prices have already been combined.

The information has been averaged.

---

# Why Does This Matter For Solidity?

Now everything suddenly makes sense.

Earlier,

we wondered why the Pair contract stores

```solidity
price0CumulativeLast
```

and

```solidity
price1CumulativeLast
```

instead of storing only one cumulative price.

Now we know why.

If Uniswap stored only

```solidity
price0CumulativeLast
```

it could **not** correctly calculate

```solidity
price1CumulativeLast
```

simply by taking the inverse.

That would produce an incorrect TWAP.

Therefore,

both cumulative prices must be maintained independently.

One continuously accumulates

```text
token1
────────
token0
```

while the other continuously accumulates

```text
token0
────────
token1
```

Both are valid.

Both are necessary.

Neither can be derived from the other.

---

# Bridge To Part 3

This completes the mathematical foundation of the Uniswap V2 oracle.

Everything we learned now directly explains the Solidity implementation.

When we open the Pair contract and see

```solidity
uint public price0CumulativeLast;
uint public price1CumulativeLast;
```

these variables will no longer feel mysterious.

We now understand **exactly why they both exist**, **what they represent**, and **why one can never be calculated from the other using a simple inverse.**
