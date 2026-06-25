### Part 1.5 — Why Does A Running Total Work?

At this point we understand that the cumulative price is a **running total**.

Now let's see how it grows over time.

Suppose the price remains

```text id="nqv2m4"
100
```

for

```text id="vmq71d"
60 minutes.
```

Earlier we learned that Uniswap waits until the next reserve update before adding anything.

When the next update finally occurs, the contribution becomes

```text id="j3jp1z"
100 × 60
```

If

```text id="7jgzrj"
C₀ = 0
```

then

```text id="t0nkqs"
C₁

=

C₀

+

100 × 60

=

6000
```

Notice something.

The previous cumulative value wasn't replaced.

Instead,

the new contribution was simply **added**.

---

# The Price Changes Again

Now suppose the price changes.

The new price becomes

```text id="s1r3kn"
200
```

and remains unchanged for

```text id="e7vfgo"
30 minutes.
```

Question:

Do we start calculating everything again from scratch?

No.

Instead we simply continue from where we left off.

Our previous cumulative value already contains all earlier history.

So we write

```text id="5l4v8q"
C₂

=

C₁

+

(200 × 30)
```

If we calculate it,

```text id="i6h0t8"
C₁

=

6000
```

New contribution

```text id="izoklq"
200 × 30

=

6000
```

Therefore

```text id="i3vnl0"
C₂

=

6000

+

6000

=

12000
```

---

# Notice Something Beautiful

Did we need to calculate

```text id="zhmwsj"
100 × 60
```

again?

No.

Why?

Because all of that information is already inside

```text id="rm2zgb"
C₁
```

Every cumulative value already contains all previous history.

Nothing is lost.

Think of it like this.

```text id="d6x4jw"
C₀

↓

0
```

↓

```text id="l0ljj7"
C₁

↓

6000
```

↓

```text id="42c1b0"
C₂

↓

12000
```

Each cumulative value contains **everything that happened before it.**

---

# Child Analogy — Bank Balance

Imagine your bank account.

Monday

```text id="bzqk09"
₹100
```

Tuesday

```text id="yw6jlz"
₹150
```

Wednesday

```text id="hng12h"
₹220
```

Question:

How much money was added between Tuesday and Wednesday?

Do you need your entire banking history?

No.

You simply calculate

```text id="1m1w2e"
220

-

150

=

70
```

The previous history automatically disappears.

Exactly the same idea is used by Uniswap.

---

# The Big Realization

Suppose

```text id="8twl2g"
C₁ = 6000
```

and

```text id="n2fr2o"
C₂ = 12000
```

Question:

Without looking at any earlier history,

can we determine **how much was added only during the second interval?**

Yes.

We simply subtract.

```text id="s4qcz4"
C₂

-

C₁

=

12000

-

6000

=

6000
```

Question:

What is this

```text id="4v2rta"
6000
```

?

It is exactly

```text id="k2wftr"
200 × 30
```

which is the contribution of **only the second interval.**

---

# Why Is This Amazing?

Notice what happened.

We never needed to know

```text id="n1slor"
100 × 60
```

again.

That history disappeared automatically.

By subtracting

```text id="hrk5jd"
C₂ - C₁
```

everything before

```text id="ymrwsr"
C₁
```

was automatically removed.

---

# Apply This To Larger Histories

Imagine

```text id="ndks6w"
C₅
```

contains

```text id="gr2v1m"
Price₀ × Time₀

+

Price₁ × Time₁

+

Price₂ × Time₂

+

Price₃ × Time₃

+

Price₄ × Time₄
```

Later,

```text id="88n22h"
C₈
```

contains

```text id="mfhhf0"
Everything above

+

Price₅ × Time₅

+

Price₆ × Time₆

+

Price₇ × Time₇
```

Now subtract them.

```text id="xjlwmu"
C₈

-

C₅
```

What remains?

Only

```text id="ngmzq5"
Price₅ × Time₅

+

Price₆ × Time₆

+

Price₇ × Time₇
```

Everything before

```text id="pr1l2v"
C₅
```

automatically cancels out.

This is the mathematical genius behind cumulative prices.

---

# Wait...

Doesn't This Look Familiar?

Earlier, while deriving TWAP, we learned that the numerator is

```text id="ikz0ut"
Σ(ΔT × Price)
```

Look carefully.

After subtracting two cumulative values,

what remains?

```text id="86g30j"
Price₅ × Time₅

+

Price₆ × Time₆

+

Price₇ × Time₇
```

That is exactly

```text id="2jcmg6"
Σ(ΔT × Price)
```

for that observation window.

This is one of the biggest "aha!" moments in understanding the Uniswap oracle.

We didn't invent a new equation.

We simply realized that

```text id="oz8emh"
C₂ - C₁
```

or more generally

```text id="36igyj"
Cₙ - Cₖ
```

automatically gives us the exact numerator we wanted all along.

Instead of replaying years of history,

we simply subtract two cumulative snapshots.
