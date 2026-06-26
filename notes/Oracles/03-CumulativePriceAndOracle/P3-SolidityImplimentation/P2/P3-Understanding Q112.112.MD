### 3.2.1.3 Understanding `Q112.112`

After discovering that Uniswap uses binary fixed-point arithmetic instead of decimal scaling, we immediately encountered another unfamiliar term.

```text
Q112.112
```

At first glance, this notation looked intimidating.

It wasn't immediately obvious whether it represented:

- A Solidity datatype
- A library
- A mathematical formula
- Some ERC standard
- Or simply a naming convention

Naturally, our first question became:

> **What exactly is Q112.112?**

---

#### Initial Thought

Initially, we assumed it might be some special Solidity feature.

It wasn't.

`Q112.112` is simply a way of describing how bits inside a number are divided.

Instead of treating the entire integer as one continuous value, we split it into two logical sections.

```text
+----------------------+----------------------+
|    Integer Portion   |   Fraction Portion   |
+----------------------+----------------------+
|      112 Bits        |      112 Bits        |
+----------------------+----------------------+
```

The first 112 bits represent the whole-number portion.

The remaining 112 bits represent the fractional precision.

Together they occupy:

```text
112 + 112 = 224 Bits
```

Immediately another mystery was solved.

---

#### Realization

This explains why the library keeps using:

```solidity
uint224
```

The number literally requires:

```text
224 Bits
```

to hold both portions.

---

#### Question

Why exactly **112** integer bits?

Why not:

```text
64

80

96

100

128
```

Where did the number 112 come from?

Was it mathematically required?

Or was it simply a design decision?

---

#### Discussion

The answer comes directly from the Pair contract itself.

Earlier we already saw:

```solidity
uint112 reserve0;

uint112 reserve1;
```

Each reserve can already occupy up to:

```text
2¹¹² - 1
```

Therefore,

our fixed-point representation must still be capable of storing every possible reserve value.

If we reduced the integer portion below:

```text
112 Bits
```

some perfectly valid reserve values would no longer fit.

For example,

imagine using:

```text
Q100.124
```

Now the integer portion only has:

```text
100 Bits
```

But reserves themselves may require:

```text
112 Bits
```

Immediately,

certain reserve values become impossible to represent.

That would completely break the system.

---

#### First Realization

The integer portion isn't arbitrary.

It directly matches the reserve size.

Since reserves are stored as:

```solidity
uint112
```

the integer portion must also contain:

```text
112 Bits.
```

---

#### Another Question

If the first 112 bits are already occupied,

why choose another **112** bits for the fraction?

Why not:

```text
80

96

100

144

200
```

Our very first thought was surprisingly simple.

> "Maybe 112 + 112 just looks nice."

Although symmetry certainly makes the format elegant,

that isn't the real reason.

---

#### Discussion

The second half determines the amount of decimal precision.

More fraction bits means:

- More precision.
- Smaller rounding error.

Fewer fraction bits means:

- Less precision.
- Larger rounding error.

So Uniswap intentionally decided to dedicate another:

```text
112 Bits
```

to fractional precision.

---

#### Question

Could Uniswap have used:

```text
Q112.80
```

instead?

Surprisingly,

yes.

Nothing fundamental would break.

The oracle would still function correctly.

The only difference would be:

```text
Less Precision
```

---

#### Another Question

What about:

```text
Q112.100
```

Again,

yes.

The oracle still works.

The trade-off is simply slightly lower precision.

---

#### Another Question

What about:

```text
Q112.144
```

Again,

yes.

This would provide **even more precision**.

However,

now the representation requires:

```text
112 + 144

=

256 Bits
```

instead of:

```text
224 Bits.
```

---

#### Our Biggest Confusion

At this point we started wondering:

> If `uint256` gives even more room,

why didn't Uniswap simply use:

```solidity
uint256
```

instead of:

```solidity
uint224
```

Initially,

our assumption was:

> Maybe `uint224` somehow avoids overflow.

After discussing it,

we realized that wasn't correct.

Both:

```text
uint224

and

uint256
```

have maximum limits.

Eventually,

both overflow.

One simply has more available bits than the other.

---

#### Discussion

Using:

```solidity
uint256
```

would certainly allow even more fractional bits.

However,

Uniswap didn't actually need them.

Remember,

the integer portion already perfectly matches:

```text
uint112 reserves.
```

Adding another:

```text
112 Fraction Bits
```

already provides an enormous amount of precision.

Anything beyond that becomes an engineering trade-off rather than a mathematical necessity.

---

#### Biggest Realization

One misconception we had during the discussion was believing:

> **Q112.112 is the only correct choice.**

It isn't.

All of these are mathematically valid.

```text
Q112.80

Q112.100

Q112.112

Q112.144
```

They simply balance:

- Precision
- Storage
- Bit allocation

differently.

Uniswap chose:

```text
Q112.112
```

because it perfectly matches:

- 112-bit reserves
- Extremely high precision
- A clean and symmetric representation

It wasn't forced by Solidity.

It was an engineering decision made by the Uniswap developers.

---

#### Mental Model

At this point,

our understanding became:

```text
uint112 Reserve

↓

Need To Preserve Entire Integer

↓

Reserve Uses 112 Bits

↓

Keep 112 Integer Bits

↓

Need Decimal Precision

↓

Allocate Another 112 Fraction Bits

↓

Q112.112

↓

Stored Inside uint224
```

This was the point where `Q112.112` finally stopped looking like a mysterious notation and instead became a straightforward bit layout.