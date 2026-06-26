### 3.2.1.4 Why `2¹¹²`?

After finally understanding what **Q112.112** represents, another question naturally appeared.

Even if we now understand that:

```text
112 Bits → Integer

112 Bits → Fraction
```

there was still something that didn't make sense.

How do we actually place a normal integer into this representation?

This eventually led us to another important question.

> Why does Uniswap keep multiplying by:

```text
2¹¹²
```

instead of simply storing the reserve directly?

---

#### First Thought

Suppose we have:

```text
reserve = 5
```

Why not simply store:

```text
5
```

inside a `uint224`?

Wouldn't that already fit?

Initially, it felt like the multiplication by:

```text
2¹¹²
```

was unnecessary.

---

#### Discussion

The key idea is that a normal integer has **no reserved space for fractional precision**.

Imagine writing the binary representation of:

```text
5
```

inside a Q112.112 number.

Conceptually,

it looks like this.

```text
+----------------------+----------------------+
| Integer Portion      | Fraction Portion     |
+----------------------+----------------------+
| 5                    | ?                    |
+----------------------+----------------------+
```

The question immediately became:

Where do the fraction bits come from?

At this point,

they don't exist.

We first have to create room for them.

---

#### The Purpose Of Multiplying By `2¹¹²`

Multiplying by:

```text
2¹¹²
```

doesn't create fractions.

Instead,

it **moves the integer into the integer portion of the fixed-point representation**.

Everything that used to be occupied by the integer now shifts to the left.

Conceptually,

```
Before

5

↓

After Multiplying By 2¹¹²

5 << 112
```

The integer has moved into the upper 112 bits.

The lower 112 bits become empty.

---

#### Another Question

At this point we asked ourselves:

> Empty?

What exactly does "empty" mean?

Are they garbage values?

Random bits?

Uninitialized memory?

None of those.

They simply become:

```text
000000000000000...
```

All zeros.

---

#### Live Visualization

Suppose we start with:

```text
5
```

Conceptually,

before encoding:

```text
+----------------------+----------------------+
| Integer              | Fraction             |
+----------------------+----------------------+
| 5                    | Doesn't Exist Yet    |
+----------------------+----------------------+
```

After multiplying by:

```text
2¹¹²
```

the integer moves completely into the integer portion.

```text
+----------------------+----------------------+
| Integer              | Fraction             |
+----------------------+----------------------+
| 5                    | 0000000000000000000  |
+----------------------+----------------------+
```

Notice something important.

We still haven't created any decimal values.

The fraction bits are simply:

```text
0
```

At this point,

we haven't stored:

```text
5.5

5.25

5.125
```

or anything similar.

We've only prepared space where fractions can later appear.

---

#### Biggest Confusion

One of the questions we kept coming back to was:

> If multiplying by `2¹¹²` creates the fraction bits,

why are they all zero?

Eventually we realized something important.

Multiplying by:

```text
2¹¹²
```

does **not** create fractions.

It only creates **room** for fractions.

The fractional information only appears later,

when we perform the division.

Until then,

the lower 112 bits remain:

```text
000000000...
```

---

#### Mental Model

Think of encoding as moving furniture into a larger room.

Originally,

everything is packed together.

After moving,

half of the room becomes completely empty.

That empty space isn't useless.

It's intentionally reserved for future fractional precision.

---

#### Final Realization

The purpose of multiplying by:

```text
2¹¹²
```

is **not** to calculate decimal values.

Its purpose is to prepare the number for decimal values.

The multiplication shifts the integer into the upper 112 bits,

leaving the lower 112 bits empty.

Only after division will those lower bits begin storing fractional precision.

That realization became the bridge between understanding **Q112.112** and finally understanding **`encode()`**.