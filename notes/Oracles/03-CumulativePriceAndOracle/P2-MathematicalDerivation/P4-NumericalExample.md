### Part 2.4 — Numerical Example (Putting Everything Together)

So far, everything we've done has been mathematical derivations.

We derived:

* The cumulative price equation.
* Why the summation starts at `i = 0`.
* Why it ends at `j − 1`.
* Why subtracting cumulative prices removes old history.
* The final TWAP equation.

Now it's time to verify that everything actually works using a real example.

This is the same example used throughout the Uniswap documentation.

---

# Given Price History

Suppose the price history looks like this.

| Time | Price |
| ---- | ----: |
| 1    |  1000 |
| 3    |  1100 |
| 4    |  1300 |
| 7    |  1200 |
| 11   |  1500 |

Our goal is to calculate the TWAP from

```text id="5k1tzd"
Time 4

↓

Time 11
```

---

# Common Beginner Mistake

When people first look at this table,

they often think

```text id="7vcp9q"
Time = 1

↓

Price = 1000
```

means

> "The price is 1000 only at time 1."

This is incorrect.

What it actually means is

> **The price becomes 1000 at time 1 and remains 1000 until the next timestamp (time 3).**

The same rule applies to every row.

---

# Determining How Long Each Price Lasts

During our discussion,

one of the first questions was:

> **"How long does the price 1000 last?"**

Your answer was

```text id="nyqjvq"
3 − 1
```

Correct.

The duration is

```text id="g6f0sz"
ΔT₀

=

3 − 1

=

2
```

Then we continued.

Price

```text id="x64yik"
1100
```

lasts

```text id="uqq3p3"
4 − 3

=

1
```

Price

```text id="i7j9pi"
1300
```

lasts

```text id="k2rjko"
7 − 4

=

3
```

Price

```text id="vb2q7u"
1200
```

lasts

```text id="0z2o9w"
11 − 7

=

4
```

---

# What About The Last Price?

During our discussion,

another important observation came up.

You correctly pointed out:

> **"1500 is ongoing."**

Exactly.

We do not know

* when it will change,
* or how long it will remain active.

Therefore,

we cannot calculate

```text id="xjlwm61"
ΔT₄
```

yet.

That is why the final row has no completed contribution.

---

# Completed Table

| Time | Price | Duration (`ΔT`) |
| ---- | ----: | --------------: |
| 1    |  1000 |               2 |
| 3    |  1100 |               1 |
| 4    |  1300 |               3 |
| 7    |  1200 |               4 |
| 11   |  1500 |         Ongoing |

---

# Calculating `ΔT × Price`

Now we calculate each contribution.

During our discussion,

you correctly answered

```text id="jlwm62"
2 × 1000 = 2000

1 × 1100 = 1100

3 × 1300 = 3900

4 × 1200 = 4800
```

Exactly right.

Our table now becomes

| Time | Price |      ΔT | ΔT × Price |
| ---- | ----: | ------: | ---------: |
| 1    |  1000 |       2 |       2000 |
| 3    |  1100 |       1 |       1100 |
| 4    |  1300 |       3 |       3900 |
| 7    |  1200 |       4 |       4800 |
| 11   |  1500 | Ongoing |          — |

---

# Building The Cumulative Price

Earlier,

you made an important observation.

You said:

> **"Cumulative will be Sigma all."**

Exactly.

Cumulative price is simply the running total.

Start with

```text id="jlwm63"
C₁ = 0
```

Then

```text id="jlwm64"
C₃

=

0 + 2000

=

2000
```

Next

```text id="jlwm65"
C₄

=

2000 + 1100

=

3100
```

Next

```text id="jlwm66"
C₇

=

3100 + 3900

=

7000
```

Finally

```text id="jlwm67"
C₁₁

=

7000 + 4800

=

11800
```

Our completed table becomes

| Time | Cumulative Price |
| ---- | ---------------: |
| 1    |                0 |
| 3    |             2000 |
| 4    |             3100 |
| 7    |             7000 |
| 11   |            11800 |

---

# Common Confusion — Why Isn't `C₄ = 7000`?

This was probably the biggest confusion during our discussion.

Initially,

it looked as if

```text id="jlwm68"
C₄
```

should equal

```text id="jlwm69"
7000
```

But after thinking carefully,

we realised this is incorrect.

Why?

Because

```text id="jlwm70"
4 → 7
```

has **not** finished yet when we are exactly at time

```text id="jlwm71"
4
```

Only these intervals have finished.

```text id="jlwm72"
1 → 3

3 → 4
```

Therefore,

```text id="jlwm73"
C₄

=

3100
```

The contribution

```text id="jlwm74"
3900
```

is only added when we actually reach

```text id="jlwm75"
Time 7.
```

---

# Child Analogy — Watching A Movie

Imagine watching a two-hour movie.

At exactly

```text id="jlwm76"
30 minutes
```

someone asks

> "How many minutes have you watched between minute 30 and minute 60?"

Answer.

```text id="jlwm77"
Zero.
```

You have only just reached minute 30.

You haven't watched the next 30 minutes yet.

Exactly the same thing happens with cumulative price.

At

```text id="jlwm78"
Time 4
```

the interval

```text id="jlwm79"
4 → 7
```

has only just begun.

It cannot be counted yet.

---

# Child Analogy — School Attendance

Suppose attendance is recorded only after each class finishes.

Classes are

```text id="jlwm80"
9–10

10–11

11–12
```

At exactly

```text id="jlwm81"
10:00
```

how many classes have you completed?

Only

```text id="jlwm82"
9–10
```

The

```text id="jlwm83"
10–11
```

class has only just started.

It cannot be counted.

Exactly the same rule applies to cumulative price.

---

# An Even Easier Rule

Near the end of our discussion,

another excellent question came up.

You asked whether

```text id="jlwm84"
C₃ = 2000

C₇ = 7000

C₁₁ = 11800
```

meant that we should always think about "minus one."

Instead of memorising

```text id="jlwm85"
j − 1
```

we found a much simpler rule.

> **`Cₓ` contains everything that has completely finished by the time the clock reaches timestamp `x`.**

For example,

```text id="jlwm86"
C₄
```

contains

```text id="jlwm87"
1 → 3

3 → 4
```

but not

```text id="jlwm88"
4 → 7
```

because that interval is still in progress.

This mental model is much easier than memorising indexing rules.

---

# Finally Computing TWAP

Now the question becomes

> **Calculate the TWAP from time 4 to time 11.**

The numerator is

```text id="jlwm89"
C₁₁ − C₄

=

11800 − 3100

=

8700
```

Notice why we subtract

```text id="jlwm90"
3100
```

and **not**

```text id="jlwm91"
7000.
```

Because

```text id="jlwm92"
7000
```

is

```text id="jlwm93"
C₇
```

not

```text id="jlwm94"
C₄.
```

The denominator is

```text id="jlwm95"
11 − 4

=

7
```

Therefore,

```text id="jlwm96"
TWAP

=

8700

÷

7

≈

1242.86
```

---

# Part 2.4 Summary

This numerical example demonstrates that every equation we derived earlier actually works in practice.

More importantly,

it removes one of the biggest sources of confusion in cumulative price:

> **A cumulative value at timestamp `Tₓ` only includes intervals that have completely finished by that timestamp.**

Once this idea clicks,

the entire cumulative price system becomes natural instead of something that must be memorised.
