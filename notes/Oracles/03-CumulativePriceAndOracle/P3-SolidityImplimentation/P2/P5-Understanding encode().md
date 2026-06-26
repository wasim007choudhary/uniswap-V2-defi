### 3.2.1.5 Understanding `encode()`

After understanding:

- Why Solidity needs fixed-point arithmetic
- What Q112.112 represents
- Why Uniswap chose binary scaling
- Why multiplying by `2¹¹²` shifts the integer into the upper 112 bits

we finally opened the library itself.

```solidity
function encode(uint112 y)
    internal
    pure
    returns (uint224 z)
{
    z = uint224(y) * Q112;
}
```

At first glance,

the function looked almost disappointingly simple.

```solidity
z = uint224(y) * Q112;
```

That was it.

Only one line.

Naturally,

our first reaction was:

> "Surely there's more happening here."

Surprisingly,

there isn't.

The complexity comes from **what this multiplication represents**, not from the code itself.

---

#### First Question

The first thing we noticed was the parameter type.

```solidity
uint112 y
```

Immediately we asked:

> Why `uint112`?

Why not

```solidity
uint256
```

or

```solidity
uint224
```

instead?

---

#### Discussion

The answer comes directly from the Pair contract.

Earlier we already learned that reserves are stored as:

```solidity
uint112 reserve0;
uint112 reserve1;
```

Therefore,

when `encode()` receives a reserve,

its natural input type is also:

```solidity
uint112
```

Nothing needs to be converted before entering the function.

The reserve is already the correct size.

---

#### Another Question

Then something else caught our attention.

```solidity
uint224(y)
```

Why cast?

Why not simply write:

```solidity
y * Q112
```

Wouldn't Solidity automatically figure everything out?

---

#### Discussion

Initially,

we assumed the cast existed purely for readability.

That wasn't the real reason.

The multiplication is:

```solidity
uint112

×

uint224
```

The result itself needs to live inside a:

```solidity
uint224
```

because after encoding,

the number now contains:

- 112 integer bits
- 112 fraction bits

Together,

they require:

```text
224 Bits
```

Conceptually,

the reserve is being moved into its new container.

---

#### Another Question

Then we asked something interesting.

> Why not cast directly to:

```solidity
uint256
```

Wouldn't that provide even more space?

---

#### Discussion

Technically,

it would.

Nothing would stop us from storing the encoded number inside:

```solidity
uint256
```

However,

the fixed-point format itself only requires:

```text
224 Bits
```

Using:

```solidity
uint224
```

perfectly matches the representation.

Anything larger would simply allocate additional bits that the chosen format never uses.

---

#### Live Example

Suppose:

```text
reserve = 5
```

The function performs:

```text
5 × 2¹¹²
```

Notice something important.

We do **not** suddenly obtain:

```text
5.0
```

or

```text
5.5
```

Nothing like that has happened.

The value has simply been shifted.

Conceptually,

```text
Before

5

↓

After Encoding

5 × 2¹¹²
```

The lower:

```text
112 Bits
```

are still:

```text
000000000000000...
```

Nothing has yet been written into the fractional portion.

---

#### Biggest Confusion

At this point we asked ourselves:

> Wait...

If the lower 112 bits are all zero,

haven't we just wasted half of the number?

The answer turned out to be:

No.

Those zeros are intentional.

They're empty placeholders waiting for future fractional precision.

Encoding itself never creates decimal values.

It merely prepares space where decimal values can later appear.

---

#### Another Question

Then we wondered:

> If encoding creates all this empty fractional space,

shouldn't we encode both reserves before dividing?

Something like:

```text
(reserve1 × 2¹¹²)

──────────────

(reserve0 × 2¹¹²)
```

Wouldn't that make more sense?

At first,

this felt logical.

Both numbers would now be represented using the same fixed-point format.

However,

after thinking about it more carefully,

we realized something important.

---

#### Discussion

Suppose we encoded both numbers.

We would obtain:

```text
(5 × 2¹¹²)

──────────────

(2 × 2¹¹²)
```

Both scaling factors immediately cancel.

```text
2¹¹²

────────

2¹¹²

=

1
```

The result becomes:

```text
5

──

2
```

which is exactly where we started.

The fractional scaling disappears completely.

Encoding both operands defeats the entire purpose of fixed-point arithmetic.

---

#### Realization

Only the numerator is encoded.

The denominator remains an ordinary integer.

This preserves the scaling factor throughout the division.

Conceptually,

the library computes:

```text
(5 × 2¹¹²)

──────────

2
```

instead of:

```text
(5 × 2¹¹²)

──────────────

(2 × 2¹¹²)
```

That single design decision allows the lower 112 bits to finally begin storing fractional precision.

---

#### Mental Model

Think of `encode()` as preparing an empty notebook.

Before encoding,

there is nowhere to write decimal values.

After encoding,

112 empty pages suddenly exist.

Nothing has been written yet.

But now,

there is finally somewhere for future fractional information to live.

---

#### Final Realization

`encode()` does **not** calculate price.

It does **not** calculate fractions.

It does **not** create decimal values.

Its only responsibility is to convert a normal integer into a Q112.112 fixed-point number by shifting it left 112 bits.

Everything after that—including the creation of fractional precision—happens during the division performed by `uqdiv()`.