### 3.2.1.7 Returning To `_update()`

After spending considerable time understanding:

- `UQ112x112`
- `Q112.112`
- `encode()`
- `uqdiv()`

we can finally return to the original line.

```solidity
price0CumulativeLast +=
    uint(
        UQ112x112.encode(_reserve1).uqdiv(_reserve0)
    ) * timeElapsed;
```

The expression no longer looks mysterious.

Instead, we can now read it from the inside out.

---

#### Step 1 — Encode The Numerator

```solidity
UQ112x112.encode(_reserve1)
```

Suppose

```text
reserve1 = 5
```

Encoding performs

```text
5 × 2¹¹²
```

Conceptually,

the integer moves into the upper 112 bits,

leaving the lower 112 bits reserved for future fractional precision.

At this point,

those fraction bits are still all zero.

Nothing has been divided yet.

---

#### Step 2 — Divide By The Denominator

```solidity
.uqdiv(_reserve0)
```

Suppose

```text
reserve0 = 2
```

Internally,

this becomes

```text
(5 × 2¹¹²)

──────────

2
```

which produces

```text
2.5 × 2¹¹²
```

Now,

for the first time,

the lower 112 bits begin storing meaningful fractional information.

We finally have a Q112.112 fixed-point representation of the price.

---

#### Step 3 — Why Cast To `uint`?

After obtaining the fixed-point price,

Uniswap performs:

```solidity
uint(...)
```

Immediately another question appeared.

> Wait...

The value is already an integer.

Why cast it again?

---

#### Discussion

The library returns:

```solidity
uint224
```

However,

the accumulator is declared as:

```solidity
uint
price0CumulativeLast;
```

which is simply

```solidity
uint256
```

Therefore,

before multiplication,

the value is promoted to:

```text
uint256
```

This doesn't change the numerical value.

It only changes the type.

Conceptually,

it becomes

```text
uint224

↓

uint256
```

Nothing about the number itself changes.

Only the container becomes larger.

---

#### Question

Earlier we had another discussion.

Can different unsigned integer types participate in arithmetic together?

For example,

can Solidity perform:

```solidity
uint8 * uint112
```

or

```solidity
uint112 * uint256
```

---

#### Discussion

Yes.

Modern Solidity automatically promotes operands to the larger unsigned integer type before performing the operation.

Conceptually,

```text
uint8

+

uint112

↓

Both Become

↓

uint112
```

Similarly,

```text
uint224

×

uint32

↓

Both Become

↓

uint224
```

The same promotion happens throughout Solidity arithmetic.

That is why the explicit cast to:

```solidity
uint
```

fits naturally with the accumulator's type.

---

#### Another Question

Earlier we also asked:

If Solidity automatically promotes integers,

why does `encode()` explicitly cast to:

```solidity
uint224
```

The answer is different.

Inside `encode()`,

we are **changing the fixed-point representation itself.**

Here,

we are simply matching the accumulator's type.

These are two completely different purposes.

---

#### Step 4 — Multiply By Time

Now the expression becomes

```text
Fixed Point Price

×

timeElapsed
```

This immediately raised another question.

Why multiply by time?

Why not simply accumulate prices?

Wouldn't this work?

```solidity
price0CumulativeLast += currentPrice;
```

At first,

that looked much simpler.

---

#### Example

Suppose the price behaves like this.

```text
Price = 100

for

1 second
```

Later,

another price exists.

```text
Price = 90

for

1 hour
```

If we simply add prices,

both contribute equally.

```text
100

+

90

=

190
```

That clearly doesn't represent reality.

The price of

```text
90
```

lasted

```text
3600 Times Longer.
```

It should influence the average much more.

---

#### Biggest Realization

Prices alone are not enough.

Duration matters.

The oracle must remember:

```text
Price

×

How Long That Price Existed
```

not merely:

```text
Price
```

This is exactly why Uniswap stores:

```text
Price × Time
```

instead of just:

```text
Price.
```

---

#### Mental Model

Imagine drawing a graph.

```text
Price

^

|

|

|

+---------------------------->

                Time
```

A price lasting one second contributes almost nothing.

A price lasting one hour contributes a much larger area.

Uniswap is continuously accumulating this area.

It is **not** accumulating raw prices.

That realization finally explains why the multiplication by:

```solidity
timeElapsed
```

is absolutely necessary.

Without it,

the oracle would ignore how long each price actually existed.
