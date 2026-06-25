### Part 2.5 — TWAP Up To The Current Time (Counterfactual Cumulative Price)

Up until now, every TWAP calculation we've performed had something in common.

We always knew:

* The starting timestamp.
* The ending timestamp.

For example,

```text
Time 4

↓

Time 11
```

Since we knew both timestamps,

we also knew the duration of every completed interval.

This allowed us to calculate every

```text
ΔT × Price
```

contribution exactly.

However,

what happens if we want to calculate the TWAP **right now**, at the current block?

This introduces a new problem.

---

# The Problem

Suppose our last reserve update happened at

```text
Time = 11
```

At that moment,

the cumulative price stored inside the Pair contract is

```text
C₁₁ = 11800
```

Now suppose the blockchain reaches

```text
Time = 13
```

Question.

Has the Pair contract updated its cumulative price?

The answer is

> **No.**

Why?

Because no swap, mint, burn, or reserve update has happened.

Remember,

the Pair contract only updates its cumulative price when `_update()` executes.

If nothing interacts with the Pair,

storage remains unchanged.

---

# Two Different Perspectives

During our discussion,

we realised there are actually **two different perspectives**.

## Perspective 1 — Reality

In reality,

we know the price became

```text
1500
```

at

```text
Time = 11
```

The blockchain has now reached

```text
Time = 13.
```

Question.

How long has the price remained

```text
1500
```

so far?

Your answer was:

```text
13 − 11 = 2
```

Exactly.

We know with certainty that the current price has lasted **2 time units so far**.

We **do not** know how long it will continue in the future.

Maybe

* one more second,
* ten minutes,
* one hour.

We don't know.

But we do know it has lasted until the current block.

---

## Perspective 2 — Storage

Storage tells a different story.

Storage still contains

```text
C₁₁ = 11800
```

because `_update()` has not been called again.

This means

the stored cumulative price is now **behind reality**.

---

# The Missing Contribution

Now we asked an important question.

Between

```text
11

↓

13
```

what contribution has been missed?

The answer is

```text
(13 − 11) × 1500
```

which equals

```text
2 × 1500

=

3000
```

This contribution exists in reality,

but it has **not yet been written into storage**.

---

# Updating The Cumulative Price Manually

Since we know

* the previous cumulative price,
* the current price,
* and how much time has passed,

we can calculate what the cumulative price **would be** if `_update()` executed right now.

Simply add the missing contribution.

```text
Current Cumulative

=

11800

+

3000

=

14800
```

Notice something.

We never modified storage.

We simply calculated what storage **would contain** if the Pair contract updated itself at this exact moment.

---

# The General Equation

Instead of writing numbers,

we can write the equation symbolically.

```text
Current Cumulative

=

Stored Cumulative

+

(Time Since Last Update × Current Price)
```

Mathematically,

this becomes

```text
Current Cumulative

=

Cₙ

+

(T − Tₙ) × P
```

where

* `Cₙ` = cumulative price stored during the last reserve update.
* `Tₙ` = timestamp of the last reserve update.
* `T` = current block timestamp.
* `P` = current spot price.

This equation appears throughout the Uniswap documentation and Oracle libraries.

---

# A Common Misunderstanding

During our discussion,

a very natural question came up.

You asked whether this equation was trying to

> **Predict where the price is going.**

The answer is

> **No.**

This equation is **not predicting the future.**

It is only calculating

> **What the cumulative price would be right now if `_update()` were executed immediately.**

Nothing more.

---

# Why Is It Called "Counterfactual"?

The word

```text
Counterfactual
```

sounds complicated,

but the idea is actually simple.

Storage currently says

```text
11800
```

Reality says

```text
14800
```

because another

```text
3000
```

has accumulated since the last update.

Instead of writing

```text
14800
```

into storage,

we simply calculate it in memory.

This is why it's called a

> **Counterfactual Cumulative Price.**

It represents the value that **would exist** if `_update()` were called right now.

---

# Child Analogy — Step Counter

Imagine your phone's fitness app.

At

```text
8:00 AM
```

it shows

```text
5000 steps.
```

You continue walking until

```text
9:00 AM.
```

The app hasn't refreshed yet.

However,

you know you've walked another

```text
1000 steps.
```

Question.

Can you estimate what the app would display if it refreshed right now?

Of course.

```text
5000

+

1000

=

6000
```

Did the app actually update?

No.

Did you predict the future?

No.

You simply calculated what the displayed value **would be** after the refresh.

That is exactly what Uniswap is doing.

---

# What If Someone Manipulates The Price?

Another excellent question came up during our discussion.

You wondered whether someone could manipulate the spot price and break this calculation.

The answer is

**No**, and here's why.

This equation only works if **no swap has happened since the last update.**

If someone performs a swap,

the Pair contract immediately calls

```text
_update()
```

At that moment,

the cumulative price is first updated using the **old** price.

Only after that does the new spot price become active.

This means we never incorrectly assume that one price lasted longer than it actually did.

Every price contributes only for the exact duration during which it existed.

---

# The Bridge To Solidity

This equation is extremely important because it is exactly what Uniswap's helper function

```text
currentCumulativePrices()
```

calculates.

Notice something interesting.

The Pair contract **does not write** the new cumulative value to storage.

Instead,

the helper function computes the missing contribution **on demand** using the equation we just derived.

When we begin reading the Solidity implementation,

you'll immediately recognise this exact formula.

---

# Part 2.5 Summary

At this point,

we have completed the entire mathematical foundation of the Uniswap V2 oracle.

We now understand:

* Why cumulative price exists.
* How cumulative price is calculated.
* Why subtracting cumulative prices gives the TWAP numerator.
* Why the denominator remains unchanged.
* How to compute TWAP using cumulative prices.
* How to estimate the cumulative price up to the current block without modifying storage.

This concludes the mathematical portion of cumulative price and prepares us to study the actual Uniswap V2 Solidity implementation.
