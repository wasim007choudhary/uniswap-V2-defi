### Part 2.2 — Why `Cₙ − Cₖ` Works (The Mathematics Behind TWAP)

In Part 1, we developed an intuition for why subtracting two cumulative prices works.

We said:

> **Subtracting two cumulative prices removes everything that happened before the observation window.**

Now we're going to **prove it mathematically.**

This is one of the most important derivations in the entire Uniswap V2 oracle.

---

# Our Starting Point

From Part 2.1, we derived the official definition of cumulative price.

```text id="vm8hrn"
             j−1
             Σ
Cⱼ =        ΔTᵢPᵢ
           i=0
```

This means:

> **The cumulative price at time `Tⱼ` is simply the sum of every completed `(Price × Time)` contribution since the Pair was created.**

---

# Let's Expand A Cumulative Price

Suppose we want to expand

```text id="q7tzc6"
C₈
```

Using our formula,

it becomes

```text id="sltjlwm"
C₈

=

ΔT₀P₀

+

ΔT₁P₁

+

ΔT₂P₂

+

ΔT₃P₃

+

ΔT₄P₄

+

ΔT₅P₅

+

ΔT₆P₆

+

ΔT₇P₇
```

Notice something.

The final contribution is

```text id="e6h4rf"
ΔT₇P₇
```

not

```text id="l5vbdm"
ΔT₈P₈
```

because interval

```text id="tbrmu4"
T₈ → T₉
```

has not finished yet.

This is exactly why our summation ends at

```text id="6m7bf8"
j − 1.
```

---

# Now Expand Another Cumulative Price

Suppose we also expand

```text id="pnh1nd"
C₅
```

It becomes

```text id="wzbjlwm"
C₅

=

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

---

# Now Comes The Magic

Suppose we subtract

```text id="twjlj9"
C₈ − C₅
```

Substituting the expanded equations gives

```text id="od3xbl"
(
ΔT₀P₀
+
ΔT₁P₁
+
ΔT₂P₂
+
ΔT₃P₃
+
ΔT₄P₄
+
ΔT₅P₅
+
ΔT₆P₆
+
ΔT₇P₇
)

-

(
ΔT₀P₀
+
ΔT₁P₁
+
ΔT₂P₂
+
ΔT₃P₃
+
ΔT₄P₄
)
```

Now watch what happens.

Every identical term cancels.

```text id="3qjlwm"
❌ ΔT₀P₀

❌ ΔT₁P₁

❌ ΔT₂P₂

❌ ΔT₃P₃

❌ ΔT₄P₄
```

What remains is

```text id="jlwm5q"
ΔT₅P₅

+

ΔT₆P₆

+

ΔT₇P₇
```

---

# Wait...

Haven't We Seen This Before?

Earlier,

when deriving TWAP from scratch,

we discovered that the numerator of TWAP is

```text id="jlwm6r"
             n−1
             Σ
            ΔTᵢPᵢ
           i=k
```

Now suppose

```text id="2wjlwm"
k = 5

n = 8
```

Then the summation becomes

```text id="jlwm8s"
ΔT₅P₅

+

ΔT₆P₆

+

ΔT₇P₇
```

Exactly the same result!

This is **not a coincidence.**

---

# The Big Mathematical Proof

We have just proven

```text id="jlwm9t"
             n−1
             Σ
            ΔTᵢPᵢ

=

Cₙ − Cₖ
           i=k
```

This is one of the most important equations in Uniswap V2.

Instead of replaying every historical price,

we simply subtract two cumulative prices.

One subtraction replaces an entire summation.

---

# Child Analogy — Your Bank Account

Imagine your account balance today is

```text id="jlwm10u"
₹50,000
```

Last month,

your balance was

```text id="jlwm11v"
₹35,000
```

Question.

How much money was added during the last month?

Do you need to inspect every single deposit?

No.

Simply calculate

```text id="jlwm12w"
50,000

-

35,000

=

15,000
```

The old deposits disappear automatically.

Exactly the same thing happens with cumulative price.

---

# Child Analogy — Odometer

Suppose your car's odometer reads

```text id="jlwm13x"
150,000 km
```

Yesterday morning,

it read

```text id="jlwm14y"
149,700 km
```

Question.

How far did you drive yesterday?

Again,

no need to inspect every road you travelled.

Simply subtract.

```text id="jlwm15z"
150,000

-

149,700

=

300 km
```

Exactly the same principle.

The cumulative price behaves like an odometer.

Subtracting two readings automatically gives the contribution between them.

---

# Our Biggest Realization

When we first saw

```text id="jlwm16a"
Cₙ − Cₖ
```

it looked like a mysterious mathematical trick.

Now we understand exactly why it works.

Subtracting cumulative prices does **not** perform any magic.

It simply removes everything that both cumulative values have in common.

Everything before

```text id="jlwm17b"
Tₖ
```

appears in **both** cumulative prices.

Therefore,

everything before

```text id="jlwm18c"
Tₖ
```

cancels.

Only the observation window remains.

---

# One More Question

Earlier during our discussion,

a natural question came up.

We asked:

> **"Where did the `n−1` go?"**

When we replaced

```text id="jlwm19d"
             n−1
             Σ
            ΔTᵢPᵢ
           i=k
```

with

```text id="jlwm20e"
Cₙ − Cₖ
```

it looked as if

```text id="jlwm21f"
n−1
```

had disappeared.

It didn't.

The reason is simple.

The upper limit

```text id="jlwm22g"
n−1
```

is already built into the definition of

```text id="jlwm23h"
Cₙ.
```

Remember,

```text id="jlwm24i"
             n−1
             Σ
Cₙ =        ΔTᵢPᵢ
           i=0
```

The summation hasn't vanished.

It has simply been replaced by the variable name

```text id="jlwm25j"
Cₙ.
```

Exactly the same way that,

if we define

```text id="jlwm26k"
A

=

1 + 2 + 3 + 4 + 5
```

later,

we simply write

```text id="jlwm27l"
A
```

instead of rewriting the entire expression again.

---

# Part 2.2 Summary

At this point, we have mathematically proven something remarkable.

Instead of storing every historical price,

instead of replaying every interval,

instead of recalculating every contribution,

Uniswap simply computes

```text id="jlwm28m"
Cₙ − Cₖ
```

and instantly obtains the exact

```text id="jlwm29n"
Price × Time
```

accumulated during the observation window.

This is the mathematical idea that makes the Uniswap V2 oracle both elegant and gas efficient.
