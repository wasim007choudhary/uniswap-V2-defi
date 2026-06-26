# UniswapV2Library — quote()

```solidity

function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
)
    internal
    pure
    returns (uint amountB)
{
    require(
        amountA > 0,
        'UniswapV2Library: INSUFFICIENT_AMOUNT'
    );

    require(
        reserveA > 0 && reserveB > 0,
        'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
    );

    amountB = amountA.mul(reserveB) / reserveA;
}
```

---

# Purpose

Given an amount of Token A and the current pool reserves,
`quote()` calculates how much Token B is needed to maintain
the pool's existing ratio.

It is fundamentally a:

```text
Pool Ratio Preservation Function
```

Example:

Pool:

10 Apples
20 Oranges

If you want to add:

2 Apples

`quote()` tells you:

Bring 4 Oranges too

so the ratio remains unchanged.
---

# First Observation

Unlike:

```solidity
getReserves()
```

or

```solidity
getAmountsOut()
```

this function is:

```solidity
pure
```

not:

```solidity
view
```

---

# Why pure?

Because it does not read:

```text
Factory
Pair
Storage
Blockchain State
Reserves
```

directly.

Everything it needs is supplied as arguments:

```solidity
amountA
reserveA
reserveB
```

It simply performs mathematical calculations.

---

# My Initial Confusion

Is this a swap function?

Does it use:

```text
x * y = k
```

?

Does it charge:

```text
0.3% fee
```

?

Does it use:

```text
997 / 1000
```

?

---

# Reality

No.

None of those appear.

This is NOT swap mathematics.

This is ratio mathematics.

---

# What Is It Really Asking?

Suppose a pool contains:

```text
10 ETH
20,000 USDC
```

Current ratio:

```text
1 ETH = 2,000 USDC
```

---

If I bring:

```text
2 ETH
```

How much USDC must I also bring to maintain the same ratio?

That is the question `quote()` answers.

---

# Child Analogy

Pool contains:

```text
10 Apples
20 Oranges
```

Current ratio:

```text
1 Apple : 2 Oranges
```

---

You want to add:

```text
2 Apples
```

How many oranges should you bring?

---

Answer:

```text
4 Oranges
```

because:

```text
10 : 20

=

2 : 4
```

The ratio remains unchanged.

---

# Mathematical Derivation

Pool ratio:

```text
reserveA : reserveB
```

Amount being added:

```text
amountA : amountB
```

To preserve the ratio:

```text
reserveA : reserveB

=

amountA : amountB
```

---

Convert to fractions:

```text
reserveA / reserveB

=

amountA / amountB
```

---

Cross multiply:

```text
reserveA × amountB

=

reserveB × amountA
```

---

Solve for amountB:

```text
amountB

=

(reserveB × amountA)
/ reserveA
```

Rearrange:

```text
amountB

=

amountA × reserveB
/ reserveA
```

Which becomes:

```solidity
amountB = amountA.mul(reserveB) / reserveA;
```

Exactly the code inside `quote()`.

---

# Example

Pool:

```text
10 ETH
20,000 USDC
```

Inputs:

```text
amountA = 2 ETH

reserveA = 10 ETH

reserveB = 20,000 USDC
```

Calculation:

```text
amountB

=

2 × 20,000
/ 10

=

4,000 USDC
```

Result:

```text
2 ETH

↔

4,000 USDC
```

maintains the existing pool ratio.

---

# Why The require Statements Exist

## Check #1

```solidity
require(
    amountA > 0,
    'UniswapV2Library: INSUFFICIENT_AMOUNT'
);
```

---

Question:

```text
What is the equivalent amount
for zero tokens?
```

Meaningless.

The calculation only makes sense if some amount is provided.

---

## Check #2

```solidity
require(
    reserveA > 0 && reserveB > 0,
    'UniswapV2Library: INSUFFICIENT_LIQUIDITY'
);
```

---

Without reserves:

```text
0 ETH
0 USDC
```

there is no ratio.

And division by zero would become possible.

---

Therefore both reserves must exist.

---

# quote() vs getAmountOut()

One of the most important distinctions.

---

## quote()

Goal:

```text
Maintain Ratio
```

Pool:

```text
10 ETH
20,000 USDC
```

Add:

```text
2 ETH
4,000 USDC
```

Result:

```text
12 ETH
24,000 USDC
```

Ratio unchanged.

---

k increases:

```text
10 × 20,000
=
200,000

↓

12 × 24,000
=
288,000
```

This is expected.

Liquidity was added.

---

## getAmountOut()

Goal:

```text
Perform Swap
```

Uses:

```text
x * y = k
```

Uses:

```text
0.3% fee
```

Uses:

```text
997 / 1000
```

Ratio changes.

Price changes.

The trade moves along the curve.

---

# Mental Model

```text
Swap

Maintain:
    x * y = k

Ratio:
    Changes

----------------------

quote()

Maintain:
    Reserve Ratio

k:
    Increases when liquidity is added
```

---

# Final Summary

`quote()` is not performing AMM swap mathematics.

It is simply solving:

```text
A : B = C : D
```

using reserve ratios.

The function answers:

"If I add amountA, how much amountB must I also add to preserve the current pool ratio?"

That is the entire purpose of `quote()`.
