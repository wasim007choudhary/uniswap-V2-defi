### 3.2.1.6 Understanding `uqdiv()`

After understanding `encode()`, we finally moved to the second function inside the library.

```solidity
function uqdiv(uint224 x, uint112 y)
    internal
    pure
    returns (uint224 z)
{
    z = x / uint224(y);
}
```

Once again,

the implementation looked almost too simple.

```solidity
z = x / uint224(y);
```

Only one line.

However,

just like `encode()`,

almost all of the complexity comes from **what the line means**, not how many lines of code it contains.

---

#### First Thought

Immediately one question appeared.

The function signature is:

```solidity
uqdiv(uint224 x, uint112 y)
```

It clearly accepts:

```text
Two Parameters
```

Yet inside `_update()` we only saw:

```solidity
.encode(_reserve1).uqdiv(_reserve0)
```

We immediately asked:

> Wait...

> Doesn't `uqdiv()` take **two** arguments?

Why are we only passing:

```solidity
_reserve0
```

Where did the first parameter go?

---

#### Discussion

This turned out to be Solidity's **library extension syntax**.

Normally,

the function could be written as:

```solidity
UQ112x112.uqdiv(
    UQ112x112.encode(_reserve1),
    _reserve0
);
```

Notice that there are now clearly two parameters.

```text
x

=

encode(_reserve1)

y

=

_reserve0
```

However,

Solidity allows another syntax.

```solidity
encode(_reserve1).uqdiv(_reserve0)
```

The value on the left side of the dot automatically becomes the first parameter.

Conceptually,

Solidity internally rewrites:

```text
a.uqdiv(b)
```

into

```text
uqdiv(a, b)
```

---

#### Realization

Nothing magical is happening.

We simply moved from:

```text
Function Style
```

to

```text
Method Style
```

The left-hand object automatically becomes the first argument.

---

#### Another Question

Next,

we noticed something else.

Inside the function,

Uniswap performs:

```solidity
uint224(y)
```

Immediately we asked:

> Wait...

Shouldn't we encode the denominator too?

Wouldn't this be more consistent?

```text
encode(reserve1)

──────────────

encode(reserve0)
```

At first,

this felt like the logical thing to do.

---

#### Discussion

Suppose:

```text
reserve1 = 5

reserve0 = 2
```

If we encoded both numbers,

the calculation becomes:

```text
(5 × 2¹¹²)

──────────────

(2 × 2¹¹²)
```

Immediately,

the scaling factors cancel.

```text
2¹¹²

────────

2¹¹²

=

1
```

The expression becomes:

```text
5

──

2
```

Exactly where we started.

All of the fixed-point scaling disappears.

Encoding both numbers defeats the entire purpose.

---

#### Biggest Realization

Only the numerator is encoded.

The denominator intentionally remains an ordinary integer.

That preserves the scaling factor throughout the division.

The actual computation becomes:

```text
(5 × 2¹¹²)

──────────

2
```

which produces:

```text
2.5 × 2¹¹²
```

Now,

for the very first time,

the lower 112 bits begin storing meaningful fractional information.

---

#### Another Confusion

Then another question appeared.

> Wait...

If we aren't encoding the denominator,

why are we still converting it into:

```solidity
uint224
```

Isn't that also encoding?

---

#### Discussion

No.

This became one of the biggest distinctions during our discussion.

There is an enormous difference between:

```solidity
uint224(y)
```

and

```solidity
encode(y)
```

Although both mention:

```text
224
```

they perform completely different jobs.

---

#### Cast

```solidity
uint224(2)
```

Value before:

```text
2
```

Value after:

```text
2
```

Nothing changed.

Only the container became larger.

Conceptually,

think of pouring two litres of water into a larger bucket.

The bucket changed.

The amount of water didn't.

---

#### Encode

Now compare that with:

```solidity
encode(2)
```

This performs:

```text
2 × 2¹¹²
```

Now the numerical value itself changes.

Conceptually,

the integer shifts into the upper 112 bits,

creating space for fractional precision.

This is **not** a simple cast.

---

#### Live Comparison

```text
Cast

2

↓

uint224(2)

↓

2
```

versus

```text
Encode

2

↓

2 × 2¹¹²
```

These are completely different operations.

One changes the type.

The other changes the representation.

---

#### Another Question

At one point we asked:

> Doesn't reserve0 become a `uint224` then?

The answer was:

Yes,

its **type** becomes:

```solidity
uint224
```

But its numerical value remains:

```text
2
```

Only the container changes.

It is **not** scaled.

---

#### Execution Flow

Putting everything together,

suppose:

```text
reserve1 = 5

reserve0 = 2
```

Step 1

```text
encode(5)

↓

5 × 2¹¹²
```

Step 2

```text
Cast

2

↓

uint224(2)
```

Notice,

the denominator is **not** multiplied.

It remains:

```text
2
```

Step 3

Division:

```text
(5 × 2¹¹²)

──────────

2
```

Result:

```text
2.5 × 2¹¹²
```

This is exactly the fixed-point representation we wanted.

---

#### Mental Model

Think of `encode()` as preparing an empty notebook.

Think of `uqdiv()` as finally writing inside those empty pages.

Before division,

the lower 112 bits were nothing but zeros.

After division,

those bits finally begin storing fractional precision.

---

#### Final Realization

`uqdiv()` does **not** simply divide two integers.

It performs the final step required to create a Q112.112 fixed-point representation of the price.

After `encode()`,

the number only has room for fractions.

After `uqdiv()`,

those fraction bits finally become meaningful.

Only now do we have a properly scaled fixed-point price ready to be used by the oracle.