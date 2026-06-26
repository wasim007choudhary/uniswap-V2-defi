# UniswapV2Library — `getAmountsIn()`

> 📖 **Before Proceeding Further:**
> 
> 1. Read **[notes/Perphery/Library/UV2PLibrary--getAmountsOut.md]**
> 2. Read **[notes/Periphery/Library/UV2Library--getAmountIn.md]**
> 3. Review the **Multi-Swap In Calculation** in the Natspec above this function
> 4. Review the **Multi-Swap Out Calculation** natspec first present above **getAmountsOut()**
```solidity
function getAmountsIn(
    address factory,
    uint amountOut,
    address[] memory path
)
    internal
    view
    returns (uint[] memory amounts)
{
    require(
        path.length >= 2,
        'UniswapV2Library: INVALID_PATH'
    );

    amounts = new uint[](path.length);

    amounts[amounts.length - 1] = amountOut;

    for (
        uint i = path.length - 1;
        i > 0;
        i--
    ) {
        (uint reserveIn, uint reserveOut) =
            getReserves(
                factory,
                path[i - 1],
                path[i]
            );

        amounts[i - 1] =
            getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut
            );
    }
}
```

---

# Purpose

`getAmountsIn()` calculates the minimum required input amount at every hop of a multi-hop swap path in order to obtain a desired final output amount.

Think of it as:

```text
I know what I WANT.

Tell me what I MUST PAY.
```

---

# Relation To getAmountsOut()

This function is the mirror image of:

```solidity
getAmountsOut()
```

---

`getAmountsOut()`

```text
Known:
    Initial Input

Find:
    Final Output

Direction:
    →
```

Visual:

```text
Input
 ↓
Hop 1
 ↓
Hop 2
 ↓
Final Output
```

---

`getAmountsIn()`

```text
Known:
    Final Output

Find:
    Initial Input

Direction:
    ←
```

Visual:

```text
Final Output
 ↑
Hop 2 Input
 ↑
Hop 1 Input
 ↑
Initial Input
```

---

# The Entire Function In One Sentence

```text
Starting from the desired final output amount,
walk backwards through every pair in the path,
repeatedly asking:

"How much input is required
to obtain this output?"
```

until the first token is reached.

---

# Child Analogy

Imagine you want:

```text
100 Pokémon Cards
```

from your friend.

Your friend says:

```text
To get 100 cards,
you must give me 50 marbles.
```

Now you ask another friend:

```text
How many stickers do I need
to get 50 marbles?
```

They say:

```text
25 stickers.
```

Now you know:

```text
25 Stickers
    ↓
50 Marbles
    ↓
100 Pokémon Cards
```

You worked backwards from the thing you wanted.

That is exactly what `getAmountsIn()` does.

---

# Path vs Swaps

Suppose:

```solidity
path = [
    WETH,
    USDC,
    DAI
];
```

Visual:

```text
WETH → USDC → DAI
```

---

Number of tokens:

```text
3
```

Number of swaps:

```text
2
```

Rule:

```text
Swaps = Tokens - 1
```

---

Therefore:

```text
WETH → USDC

USDC → DAI
```

are the two actual swaps.

---

# First Require

```solidity
require(
    path.length >= 2,
    ...
);
```

Why?

Because:

```text
One token

=

No pair

=

No swap
```

Minimum valid path:

```text
[A, B]
```

---

# Creating The Amounts Array

```solidity
amounts =
    new uint[](path.length);
```

For:

```solidity
path = [
    WETH,
    USDC,
    DAI
];
```

creates:

```text
amounts = [0,0,0]
```

---

# Biggest Difference From getAmountsOut()

In `getAmountsOut()`:

```solidity
amounts[0] = amountIn;
```

because the input is known.

---

Here:

```solidity
amounts[
    amounts.length - 1
] = amountOut;
```

because the output is known.

---

Example:

```text
I WANT:

1000 DAI
```

Then:

```text
amounts = [?, ?, 1000]
```

---

# Why Last Element?

Because:

```text
Path

WETH → USDC → DAI
```

and:

```text
DAI
```

is the final destination.

Therefore:

```text
amounts[2]
```

is known first.

---

# Understanding The Loop

```solidity
for (
    uint i = path.length - 1;
    i > 0;
    i--
)
```

---

This is the opposite of:

```solidity
getAmountsOut()
```

which walks:

```text
left → right
```

---

This walks:

```text
right ← left
```

because the final output amount is already known.

---

# Why Does The Loop Start At The End?

Because:

```text
We know the destination.

We don't know the starting amount.
```

Therefore:

```text
Start from the destination.

Work backwards.
```

---

# Example Walkthrough

Suppose:

```solidity
path = [
    WETH,
    USDC,
    DAI
];
```

and:

```text
amountOut = 1000 DAI
```

Initial state:

```text
amounts = [?, ?, 1000]
```

---

# Iteration 1

```solidity
i = 2
```

Current target:

```text
Need:

1000 DAI
```

Question:

```text
How much USDC
is required
to obtain 1000 DAI?
```

---

Get reserves:

```solidity
getReserves(
    factory,
    USDC,
    DAI
)
```

---

Then:

```solidity
getAmountIn(
    1000,
    reserveIn,
    reserveOut
)
```

returns:

```text
950 USDC
```

Store:

```text
amounts = [?, 950, 1000]
```

---

# Iteration 2

```solidity
i = 1
```

Current target:

```text
Need:

950 USDC
```

Question:

```text
How much WETH
is required
to obtain 950 USDC?
```

---

Get reserves:

```solidity
getReserves(
    factory,
    WETH,
    USDC
)
```

---

Suppose result:

```text
0.5 WETH
```

Store:

```text
amounts = [
    0.5,
    950,
    1000
]
```

Done.

---

# Common Confusion #1

## Why Doesn't The Loop Reach i = 0?

Loop:

```solidity
i > 0
```

not:

```solidity
i >= 0
```

---

Question:

```text
Shouldn't i reach 0?

Arrays start at 0.
```

Answer:

```text
Index 0 is calculated
when i = 1.
```

---

Look:

```solidity
amounts[i - 1] =
    getAmountIn(...);
```

When:

```solidity
i = 1
```

we write:

```solidity
amounts[0]
```

because:

```text
1 - 1 = 0
```

---

Therefore:

```text
i = 2
    fills index 1

i = 1
    fills index 0

STOP
```

Nothing remains.

---

# Common Confusion #2

## Why path[i - 1] Before path[i]?

Current code:

```solidity
getReserves(
    factory,
    path[i - 1],
    path[i]
)
```

Example:

```text
WETH → USDC → DAI
```

When:

```solidity
i = 2
```

becomes:

```solidity
getReserves(
    factory,
    USDC,
    DAI
)
```

---

Question:

```text
Shouldn't it be:

DAI,
USDC
?
```

Answer:

```text
No.
```

Because the question being asked is:

```text
How much USDC
must I provide
to obtain DAI?
```

Therefore:

```text
Input Token  = USDC

Output Token = DAI
```

and:

```solidity
getAmountIn()
```

expects:

```text
reserveIn
reserveOut
```

in that exact order.

---

# Common Confusion #3

## Doesn't getReserves() Automatically Fix The Order?

YES.

For pair lookup.

---

Example:

```solidity
getReserves(
    factory,
    USDC,
    DAI
)
```

and:

```solidity
getReserves(
    factory,
    DAI,
    USDC
)
```

both find:

```text
The Same Pair
```

because:

```solidity
sortTokens()
```

is used internally.

---

# Then Why Care About Order?

Because:

```solidity
getReserves()
```

returns reserves in YOUR requested order.

Example Pair:

```text
token0 = USDC
token1 = DAI

reserve0 = 1000
reserve1 = 2000
```

---

Call:

```solidity
getReserves(
    factory,
    USDC,
    DAI
)
```

returns:

```text
USDC reserve first
DAI reserve second
```

---

Call:

```solidity
getReserves(
    factory,
    DAI,
    USDC
)
```

returns:

```text
DAI reserve first
USDC reserve second
```

---

Both are correct.

The library translates automatically.

---

# Where Is The Relationship Established?

Many people think:

```text
tokenA ↔ reserveA
```

exists inside the Pair.

It does not.

---

Pair establishes:

```text
token0 ↔ reserve0
token1 ↔ reserve1
```

inside:

```solidity
_update()
```

when reserves are updated.

---

Library establishes:

```text
tokenA ↔ reserveA
tokenB ↔ reserveB
```

inside:

```solidity
getReserves()
```

through:

```solidity
(reserveA, reserveB) =
    tokenA == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
```

---

# Mental Model

```text
Pair World

token0 ↔ reserve0
token1 ↔ reserve1

                ↓

Library Translator

                ↓

Caller World

tokenA ↔ reserveA
tokenB ↔ reserveB
```

---

# Another Mental Model

`getAmountsOut()`

```text
I have money.

How many apples can I buy?
```

Known:

```text
Input
```

Find:

```text
Output
```

---

`getAmountsIn()`

```text
I want 10 apples.

How much money
must I bring?
```

Known:

```text
Output
```

Find:

```text
Input
```

---

# Final Mental Model

```text
getAmountsOut()

Known:
    Initial Input

Direction:
    →

Uses:
    getAmountOut()

----------------------------------

getAmountsIn()

Known:
    Final Output

Direction:
    ←

Uses:
    getAmountIn()
```

Same path.

Same pools.

Same reserves.

Same AMM.

Same multi-hop mechanism.

Just running the movie backwards.
