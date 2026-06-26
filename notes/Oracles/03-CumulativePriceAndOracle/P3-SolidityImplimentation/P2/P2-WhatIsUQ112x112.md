### 3.2.1.2 What Is `UQ112x112`?

Once we broke the oracle line into smaller pieces, the very first thing that caught our attention was:

```solidity
UQ112x112
```

Everything else in the expression depended on understanding this library first.

Naturally, our first question became:

> **What exactly is `UQ112x112`?**

At first glance, it looked mysterious.

Questions immediately started appearing.

- Is it a special Solidity datatype?
- Is it some kind of mathematical library?
- Is it part of OpenZeppelin?
- Is it a Uniswap invention?
- Why does price calculation even require a separate library?

Before opening the library itself, we tried to understand **why** it might even exist.

---

#### First Thought

Our initial assumption was very simple.

> "Why doesn't Uniswap simply divide the reserves?"

Suppose the reserves are:

```text
reserve1 = 10

reserve0 = 2
```

Price should simply be:

```text
10 / 2 = 5
```

That looks perfectly fine.

So why introduce an entirely new library?

---

#### Another Example

Now suppose the reserves become:

```text
reserve1 = 5

reserve0 = 2
```

Mathematically,

```text
5 / 2 = 2.5
```

However, Solidity performs integer division.

```solidity
5 / 2
```

becomes

```text
2
```

The decimal portion disappears.

Not rounded.

Not approximated.

Simply discarded.

---

#### Realization

At this point we realized the problem wasn't Uniswap.

The problem was Solidity.

Unlike many traditional programming languages,

Solidity has **no floating-point numbers.**

Everything is integer arithmetic.

---

#### Question

If Solidity throws away every decimal,

how can Uniswap ever build an accurate oracle?

A Time-Weighted Average Price (TWAP) depends on accurate prices.

If every division loses its decimal precision,

the oracle itself would become increasingly inaccurate.

Clearly,

Uniswap needed another way to represent decimal numbers.

---

#### Our First Idea

The first thing that came to our mind was:

> **Why not simply multiply everything by `1e18`?**

This is something almost every Solidity developer has seen.

Instead of storing:

```text
1.5
```

many protocols internally store:

```text
1500000000000000000
```

while remembering that the last 18 decimal places belong to the fractional part.

Naturally,

we asked:

> Why didn't Uniswap simply do the same?

---

#### Discussion

Interestingly,

Uniswap **could have** used `1e18`.

Nothing in Solidity prevents that.

Using decimal scaling would also preserve fractional precision.

Instead,

Uniswap deliberately chose something different.

Rather than decimal scaling,

it uses binary scaling.

Instead of:

```text
× 10¹⁸
```

it scales numbers by:

```text
2¹¹²
```

which immediately introduces another unfamiliar term:

```text
Q112.112
```

---

#### More Questions

As soon as we encountered:

```text
Q112.112
```

another series of questions appeared.

- What does **Q** even stand for?
- Why **112**?
- Why another **112**?
- Why not `Q64.64`?
- Why not `Q112.80`?
- Why not `Q112.100`?
- Why not `Q112.144`?
- Why not simply use `uint256` and avoid all this?

At this point, it became obvious that before we could understand `encode()` or `uqdiv()`, we first had to understand the fixed-point format itself.

That became the next major topic in our discussion.

---

#### Mental Model Before Moving Forward

Up until now, we had only reached one conclusion.

```text
Normal Solidity Division

↓

Loses Decimals

↓

TWAP Needs Decimals

↓

Uniswap Invents Another Representation

↓

UQ112x112
```

At this point, we still didn't know **how** `UQ112x112` worked.

But we finally understood **why** it existed.

It wasn't solving a Uniswap problem.

It was solving a Solidity limitation.