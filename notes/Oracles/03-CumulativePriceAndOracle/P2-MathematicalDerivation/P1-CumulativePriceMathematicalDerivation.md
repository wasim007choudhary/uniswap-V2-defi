### Part 2.1 — Deriving the Mathematical Definition of Cumulative Price

In **Part 1**, we built an intuitive understanding of cumulative price.

We answered questions like:

* Why does Uniswap need cumulative price?
* Why not simply store every historical price?
* Why does cumulative price continuously increase?
* Why does subtracting two cumulative prices automatically isolate a specific time window?
* Why does `C₀` start at zero?
* Why does Uniswap wait until the next reserve update before adding `Price × Time`?

By the end of Part 1, we understood **what** cumulative price is and **why** Uniswap uses it.

Now, in **Part 2**, we move from intuition to mathematics.

Instead of saying,

> "Cumulative price is a running total."

we're going to derive the **official mathematical definition** used by Uniswap V2.

---

# Starting From What We Already Know

Earlier, we built cumulative prices manually.

For example,

```text
C₀ = 0

↓

C₁ = C₀ + (100 × 60)

↓

C₂ = C₁ + (200 × 30)

↓

C₃ = C₂ + (300 × 10)

↓

...
```

Every new completed interval simply adds another

```text
Price × Time
```

to the previous cumulative value.

This is exactly how a running total works.

---

# A Question

Suppose we continue doing this forever.

Would we really want to write

```text
C₁ = ...

C₂ = ...

C₃ = ...

C₄ = ...

C₅ = ...

...
```

for every cumulative value?

Of course not.

Mathematicians prefer writing **one equation** that works for every cumulative price.

This naturally leads us to Sigma notation.

---

# Where Should The Summation Begin?

Earlier, when we derived TWAP, our summation began at

```text
k
```

because TWAP only cared about one observation window.

```text
        n−1
        Σ
i = k
ΔTᵢPᵢ
```

At first glance, we might think cumulative price should also begin at

```text
k
```

However, this is incorrect.

Why?

Because cumulative price is **not** measuring a specific observation window.

It is measuring **everything that has happened since the Pair was created.**

Therefore,

the summation cannot begin at

```text
k
```

It must begin at

```text
i = 0
```

because cumulative price remembers every completed interval from the beginning of the Pair.

---

# Child Analogy — Bank Balance

Imagine opening your banking app.

Today's balance contains:

* Your first deposit.
* Your second deposit.
* Your third deposit.
* ...
* Your latest deposit.

It does **not** contain only last week's deposits.

Exactly the same thing happens with cumulative price.

Cumulative price contains every completed contribution since the Pair was created.

---

# What Does Each Interval Contribute?

Earlier, we learned something extremely important.

Every interval contributes

```text
Price × Time
```

But there is a small correction.

We are **not** multiplying by the timestamp.

We are multiplying by the **duration** that the price remained active.

Instead of writing

```text
Price × T
```

we write

```text
Price × ΔT
```

where

```text
ΔT
```

means

> **How long that price lasted.**

Not

> **What the current clock time is.**

Therefore,

every term inside the summation becomes

```text
ΔTᵢPᵢ
```

---

# Another Question

Now we know:

* The summation begins at

```text
i = 0
```

* Every term is

```text
ΔTᵢPᵢ
```

The next question is:

**Where should the summation end?**

Should it end at

```text
j
```

or

```text
j − 1
```

This is one of the most confusing parts of cumulative price.

Let's derive it instead of memorizing it.

---

# Why Doesn't The Summation End At `j`?

Suppose we want to calculate

```text
C₅
```

Many people naturally think the last term should be

```text
ΔT₅P₅
```

That was actually our first instinct during the discussion.

However, after carefully thinking about it, we realized something important.

Imagine the timeline.

```text
T₀ ---- T₁ ---- T₂ ---- T₃ ---- T₄ ---- T₅
```

The corresponding prices are

```text
P₀     P₁     P₂     P₃     P₄
```

Notice something.

The interval

```text
T₄ → T₅
```

has finished.

Therefore,

its contribution

```text
ΔT₄P₄
```

is known.

However,

the next interval

```text
T₅ → T₆
```

has not happened yet.

Question.

Do we know

```text
T₆
```

No.

Question.

Do we know

```text
ΔT₅
```

No.

Question.

Can we calculate

```text
ΔT₅P₅
```

No.

Because we do not know how long

```text
P₅
```

will remain active.

Maybe

* 1 second.
* 10 minutes.
* 3 hours.

We simply don't know yet.

Therefore,

the last completed contribution is

```text
ΔT₄P₄
```

not

```text
ΔT₅P₅.
```

---

# Building The Formula

Now we know everything.

The summation

* Starts at

```text
i = 0
```

* Ends at

```text
j − 1
```

* Adds

```text
ΔTᵢPᵢ
```

for every completed interval.

Therefore,

the mathematical definition of cumulative price becomes

```text
             j−1
             Σ
Cⱼ =        ΔTᵢPᵢ
           i=0
```

This is the official cumulative price equation used throughout the Uniswap documentation.

---

# Reading The Equation In Plain English

Although the equation initially looks intimidating,

it simply says:

> **The cumulative price at time `Tⱼ` equals the sum of every `(Price × Time)` contribution from the very first completed interval up to the last completed interval before `Tⱼ`.**

Nothing more.

---

# Child Analogy — Collecting Candies

Suppose you collect candies every day.

By the time Day 5 begins,

how many completed days have passed?

Only

```text
Day 1

Day 2

Day 3

Day 4
```

You cannot include Day 5's candies yet.

The day has only just started.

Exactly the same thing happens with cumulative price.

At

```text
T₅
```

the interval

```text
T₅ → T₆
```

has just begun.

Its contribution cannot yet be calculated.

Therefore,

```text
C₅
```

contains

```text
ΔT₀P₀

+

ΔT₁P₁

+

ΔT₂P₂

+

ΔT₃P₃

+

ΔT₄P₄
```

and **not**

```text
ΔT₅P₅.
```

---

# A Beautiful Observation

Earlier,

we built cumulative price recursively.

```text
C₁ = C₀ + ΔT₀P₀

C₂ = C₁ + ΔT₁P₁

C₃ = C₂ + ΔT₂P₂
```

Now compare this with the Sigma equation.

Nothing has changed.

The Sigma equation did **not** invent a new concept.

It simply provides a shorter mathematical way of writing exactly the same running total we've been building since Part 1.

This is why the formula feels much less intimidating once you understand where every part comes from.

We didn't memorize it.

We **derived it ourselves** from first principles.
