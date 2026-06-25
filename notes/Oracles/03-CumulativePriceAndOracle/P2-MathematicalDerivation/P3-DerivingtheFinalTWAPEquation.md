### Part 2.3 — Deriving the Final TWAP Equation

In Part 2.2, we proved something extremely important.

We showed that

```text id="qw81nx"
             n−1
             Σ
            ΔTᵢPᵢ

=

Cₙ − Cₖ
           i=k
```

This means that the numerator of TWAP no longer needs to be calculated by replaying every historical price.

Instead,

one subtraction gives us exactly the same result.

Now we only have one question left.

> **What should we divide by?**

---

# Going Back To The Original TWAP Formula

Earlier,

when we learned TWAP from scratch,

we derived

```text id="jlwm31a"
             n−1
             Σ
            ΔTᵢPᵢ
TWAP = -----------------------
            Tₙ − Tₖ
           i=k
```

Notice something.

The denominator never changed.

The numerator changed.

Originally,

the numerator was

```text id="jlwm32b"
             n−1
             Σ
            ΔTᵢPᵢ
           i=k
```

Now,

we know this entire summation equals

```text id="jlwm33c"
Cₙ − Cₖ
```

Therefore,

we simply substitute it into the TWAP equation.

---

# The Final Equation

The final equation becomes

```text id="jlwm34d"
          Cₙ − Cₖ
TWAP = --------------
          Tₙ − Tₖ
```

This is the official TWAP equation used throughout the Uniswap V2 oracle.

Notice something interesting.

We didn't memorize this equation.

We **derived** it ourselves.

Every symbol has a meaning.

Nothing appears magically.

---

# Understanding Every Part

The numerator

```text id="jlwm35e"
Cₙ − Cₖ
```

answers the question:

> **How much `(Price × Time)` accumulated during our observation window?**

The denominator

```text id="jlwm36f"
Tₙ − Tₖ
```

answers the question:

> **How long was the observation window?**

Finally,

Average =

```text id="jlwm37g"
Total

÷

Time
```

Exactly the same way we calculate any other average.

---

# Child Analogy — Average Speed

Suppose you drove

```text id="jlwm38h"
300 km
```

in

```text id="jlwm39i"
6 hours.
```

Question.

How do we calculate your average speed?

Simple.

```text id="jlwm40j"
Average Speed

=

Total Distance

÷

Total Time
```

which is

```text id="jlwm41k"
300

÷

6

=

50 km/h
```

Notice something.

We are doing exactly the same thing with TWAP.

Instead of

```text id="jlwm42l"
Distance
```

our numerator is

```text id="jlwm43m"
Price × Time
```

Instead of

```text id="jlwm44n"
Hours
```

our denominator is

```text id="jlwm45o"
Elapsed Time
```

The mathematics is identical.

---

# Why Didn't We Ignore The Denominator?

During our discussion,

a very important question came up.

We noticed that while deriving cumulative price,

we seemed to ignore the denominator.

The natural question was:

> **"Where did the denominator go?"**

The answer is:

We didn't ignore it.

While deriving cumulative price,

our goal was only to simplify the **numerator**.

The denominator was already correct.

Nothing needed to change.

Originally,

TWAP was

```text id="jlwm46p"
          Σ(ΔT × Price)
----------------------------
          Tₙ − Tₖ
```

We simply replaced

```text id="jlwm47q"
Σ(ΔT × Price)
```

with

```text id="jlwm48r"
Cₙ − Cₖ
```

The denominator

```text id="jlwm49s"
Tₙ − Tₖ
```

remained exactly the same.

---

# Why Is The Denominator Still Correct?

Think about what

```text id="jlwm50t"
Tₙ − Tₖ
```

means.

It represents the total duration of the observation window.

For example,

suppose we calculate TWAP from

```text id="jlwm51u"
Time 4

↓

Time 11
```

The denominator becomes

```text id="jlwm52v"
11 − 4

=

7
```

Notice something.

This is **not**

the duration of one interval.

It is the duration of the **entire observation window**.

Earlier,

we also discussed the difference between

```text id="jlwm53w"
ΔTᵢ
```

and

```text id="jlwm54x"
Tₙ − Tₖ
```

These are different things.

---

# Don't Mix These Two

A single interval duration is

```text id="jlwm55y"
ΔT₂

=

T₃ − T₂
```

This tells us

> **How long one specific price remained active.**

The denominator is

```text id="jlwm56z"
Tₙ − Tₖ
```

This tells us

> **How long the entire TWAP observation window lasted.**

They are completely different concepts.

One belongs to a single interval.

The other belongs to the entire averaging period.

---

# The Journey We Just Completed

Think about everything we accomplished.

We started with

```text id="jlwm57a"
Σ(ΔT × Price)
```

Then we asked:

> **"How can Uniswap avoid storing every historical price?"**

That led us to invent the idea of cumulative price.

We then defined

```text id="jlwm58b"
Cⱼ
```

Next,

we proved

```text id="jlwm59c"
Cₙ − Cₖ
```

automatically removes old history.

Finally,

we divided by

```text id="jlwm60d"
Tₙ − Tₖ
```

to obtain the average.

Everything fits together naturally.

Nothing in the final TWAP equation needs to be memorized anymore.

Every symbol was derived step by step.

---

# Part 2.3 Summary

At this point,

we have completely derived the mathematical foundation of TWAP.

We now understand:

* Why cumulative price exists.
* Why cumulative price starts at `i = 0`.
* Why it ends at `j − 1`.
* Why subtracting two cumulative prices isolates a specific observation window.
* Why the denominator remains `Tₙ − Tₖ`.
* How all of these pieces combine to produce the final TWAP equation used by Uniswap V2.
