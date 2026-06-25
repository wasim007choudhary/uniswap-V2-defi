# 02 - Understanding TWAP (Time-Weighted Average Price) From Scratch

## Part 4 — Why We Divide by Total Time (Understanding Time Weights)

---

# Introduction

In Part 3, we learned that every price has a **lifetime**.

Example:

| Price | Lasted |
|--------|---------|
|10|5 minutes|
|20|15 minutes|
|30|10 minutes|

We also learned that TWAP says:

> Prices that existed longer should influence the average more.

The next question naturally becomes:

> **How much more?**

How do we mathematically decide that one price should contribute more than another?

This is where **weights** come in.

---

# What Is A Weight?

A **weight** simply tells us:

> **How much influence something should have.**

Nothing more.

For TWAP, the weight is determined entirely by **time**.

Longer time

↓

Bigger weight

↓

More influence.

---

# Child Analogy

Imagine your day looked like this.

| Activity | Time |
|-----------|------|
|Study|6 hours|
|Gaming|2 hours|
|Sleep|8 hours|
|Gym|2 hours|
|Eating|6 hours|

Total:

```text
24 hours
```

Now someone asks:

> What fraction of your day did you spend studying?

Easy.

```text
6

/

24
```

or

```text
25%
```

That means

Study occupied

```text
25%
```

of your day.

---

# Replace Activities With Prices

Now imagine instead of activities, we have prices.

| Price | Duration |
|--------|----------|
|10|5 minutes|
|20|15 minutes|
|30|10 minutes|

Total observation time:

```text
30 minutes
```

Question:

What fraction of the observation period did

Price

```text
10
```

exist?

Answer:

```text
5

/

30
```

---

Price

```text
20
```

?

```text
15

/

30
```

---

Price

```text
30
```

?

```text
10

/

30
```

Notice something interesting.

The fractions add up to

```text
5/30

+

15/30

+

10/30

=

30/30

=

1
```

or

```text
100%
```

Exactly like percentages of your day.

---

# This Is Exactly What The Formula Means

The documentation writes

```text
ΔT₀
──────
Tₙ−T₀
```

Most people immediately panic.

Don't.

Let's translate it.

---

## Top

```text
ΔT₀
```

means

> How long Price₀ lasted.

Suppose

```text
5 minutes.
```

---

## Bottom

```text
Tₙ−T₀
```

means

> Total observation period.

Suppose

```text
T₀

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
Tₙ−T₀

=

30 minutes.
```

---

Putting them together gives

```text
5

/

30
```

Nothing scary.

It's simply asking:

> **What percentage of the total observation period did this price exist?**

---

# Why Divide By Total Time?

Suppose

Price

```text
10
```

lasted

```text
5 minutes.
```

Suppose the total observation period was

```text
30 minutes.
```

Question:

Is saying

```text
5 minutes
```

alone enough?

No.

Five minutes compared to what?

Five minutes out of

```text
10
```

?

```text
30
```

?

```text
2 hours
```

?

Without knowing the total observation period, the duration doesn't tell us much.

That's why we divide by the total time.

---

# Child Analogy

Suppose someone says:

> I studied for

```text
2 hours.
```

Is that impressive?

You don't know.

If the whole day was

```text
24 hours
```

that's only

```text
2/24
```

If the study session itself lasted

```text
3 hours
```

then

```text
2/3
```

is a lot.

Context matters.

TWAP works exactly the same way.

---

# Another Way To Think About It

Instead of saying

```text
5 minutes
```

TWAP converts it into

```text
16.7%
```

Instead of saying

```text
15 minutes
```

TWAP converts it into

```text
50%
```

Instead of saying

```text
10 minutes
```

TWAP converts it into

```text
33.3%
```

Now every price has a percentage.

Those percentages become the **weights**.

---

# This Is Why It's Called A Weight

Imagine voting.

Candidate A receives

```text
90 votes.
```

Candidate B receives

```text
10 votes.
```

Should both influence the result equally?

Obviously not.

The votes determine their influence.

TWAP simply replaces

```text
Votes
```

with

```text
Time.
```

The longer a price exists,

the more voting power it gets.

---

# One Of Our Questions

During our discussion we asked:

> **Which price influences TWAP more?**

Suppose

```text
Price = 10
```

lasted

```text
1 hour.
```

Suppose

```text
Price = 100
```

lasted

```text
1 second.
```

Answer:

The price

```text
10
```

influences TWAP much more.

TWAP doesn't care that

```text
100
```

is numerically larger.

It cares that

```text
10
```

represented the market for much longer.

---

# Another Question

Question:

> Does the lower number in

```text
ΔT₂
```

mean the time difference between

```text
T₂

and

T₃
```

Answer:

**Yes.**

By definition,

```text
ΔT₂

=

T₃−T₂
```

It measures how long

```text
Price₂
```

remained valid before another swap changed the reserves.

---

# Mental Model

Whenever you see

```text
ΔTᵢ
────────
Tₙ−T₀
```

don't think

> Fraction.

Think

> **What percentage of the total observation time did Priceᵢ exist?**

That's literally what the formula means.

---

# Summary

Suppose

| Price | Lasted |
|--------|---------|
|10|5 min|
|20|15 min|
|30|10 min|

Observation period:

```text
30 minutes
```

Weights become

| Price | Weight |
|--------|---------|
|10|5/30|
|20|15/30|
|30|10/30|

These weights tell TWAP exactly how much influence each price should have.

Prices that remain valid longer naturally receive larger weights.

---

# Key Takeaways

- A **weight** determines how much influence a value should have.
- In TWAP, weights are determined **only by time**.
- Weight = Duration ÷ Total Observation Time.
- Dividing by the total observation time converts durations into percentages.
- All weights always add up to **1 (100%)**.
- Longer-lived prices receive larger weights and therefore influence the final average more.

---

> **Next Part:** We'll learn why TWAP multiplies **Weight × Price**, why this gives each price its proper contribution to the final average, and finally derive the weighted-average equation step by step.