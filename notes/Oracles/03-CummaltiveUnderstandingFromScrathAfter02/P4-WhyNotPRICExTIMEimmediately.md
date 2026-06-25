### Part 1.4 — Why Can't Uniswap Immediately Add `Price × Time`?

Now we know:

* The first price is known immediately.
* The cumulative price starts at

```text
C₀ = 0
```

But this naturally raises another question.

> **If we already know the price, why doesn't Uniswap immediately add it to the cumulative price?**

This is one of the most important concepts in understanding the oracle.

---

# The Problem

Suppose the Pair is created at

```text
5:00
```

The current price becomes

```text
100
```

Question:

Can we immediately calculate

```text
100 × Time
```

No.

Why?

Because...

**What is the value of Time?**

We don't know yet.

The price has just started.

We have absolutely no idea whether it will remain at

```text
100
```

for

* 1 second
* 10 seconds
* 5 minutes
* 1 hour
* 3 days

Since we don't know how long the price will remain unchanged, we cannot calculate

```text
Price × Time
```

yet.

---

# Timeline

Suppose

```text
5:00

↓

Price becomes 100
```

At exactly

```text
5:00
```

how much time has passed?

```text
0 seconds
```

Therefore

```text
Price × Time

=

100 × 0

=

0
```

Nothing has accumulated.

So

```text
C₀ = 0
```

---

Now suppose nothing happens until

```text
5:10
```

At

```text
5:10
```

another swap occurs and changes the price.

Only now do we know

```text
Price = 100

Time = 10 minutes
```

Finally we can calculate

```text
100 × 10
```

and add it to the cumulative total.

```text
C₁

=

C₀

+

100 × 10
```

Only now has that price contributed to the cumulative price.

---

# Child Analogy — Filling A Bucket

Imagine turning on a water tap.

At

```text
12:00
```

you open the tap.

Question:

At the exact moment you open it,

how much water has entered the bucket?

```text
0 litres
```

The flow has started,

but nothing has accumulated yet.

Five minutes later,

now you know

```text
Flow Rate × Time
```

and therefore

how much water entered the bucket.

The cumulative price works exactly the same way.

The price begins immediately,

but its contribution is unknown until some time has actually passed.

---

# Another Analogy — Driving A Car

Suppose you start driving.

At exactly

```text
2:00 PM
```

your speed is

```text
60 km/h
```

Question:

At exactly

```text
2:00 PM
```

how far have you travelled?

```text
0 km
```

You know your speed.

You do **not** know the distance yet.

Distance is

```text
Speed × Time
```

Without elapsed time,

distance is zero.

TWAP follows the same principle.

Instead of

```text
Speed × Time
```

it uses

```text
Price × Time
```

---

# So Why Doesn't Uniswap Continuously Update?

Earlier we asked another question during our discussion.

> **Why doesn't Uniswap continuously update the cumulative price?**

Now we finally have the answer.

Imagine updating every second.

```text
5:00:01

↓

Add 100
```

```text
5:00:02

↓

Add another 100
```

```text
5:00:03

↓

Add another 100
```

...

For one hour,

this would require

```text
3600 updates
```

All of those updates would cost gas.

Completely unnecessary.

---

# What Does Uniswap Do Instead?

Suppose the price remains

```text
100
```

from

```text
5:00

↓

6:00
```

No swaps occur.

No reserve updates occur.

Question:

Does Uniswap need to perform

```text
3600
```

updates?

No.

Nothing changed.

The price remained exactly the same.

So Uniswap simply waits.

Then,

when the next reserve-changing transaction finally arrives at

```text
6:00
```

it looks back and says

> "The previous price remained active for one entire hour."

Now it performs **one** calculation.

```text
100 × 60 minutes
```

(or

```text
100 × 3600 seconds
```

depending on the chosen unit.)

One calculation.

One storage update.

Exactly the same mathematical result.

Much cheaper gas.

---

# A Very Important Realization

Notice how several concepts we've already learned now connect together.

Earlier we learned:

* Prices remain constant between reserve updates.
* Every price lasts for a duration `ΔT`.
* Uniswap does not continuously update reserves.
* The cumulative price stores `Price × Time`.

Now all of those ideas combine into one picture.

Since the price remains constant until reserves change,

there is absolutely no need to keep updating every second.

Uniswap simply waits until the next reserve update,

calculates how long the previous price lasted,

multiplies

```text
Price × Time
```

once,

and adds that contribution to the cumulative price.

This is one of the biggest reasons why the Uniswap V2 oracle is extremely gas efficient.
