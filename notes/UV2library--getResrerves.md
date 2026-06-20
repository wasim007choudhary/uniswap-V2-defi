# Library.getReserves() — Part 2

## Calling Pair.getReserves() Through The Derived Pair Address

At this point in the function:

```solidity
(address token0,) = sortTokens(tokenA, tokenB);

(uint reserve0, uint reserve1,) =
    IUniswapV2Pair(
        pairFor(factory, tokenA, tokenB)
    ).getReserves();
```

we already know:

* what `pairFor()` does
* how CREATE2 derives pair addresses
* how Pair `getReserves()` works
* why reserves exist
* reserve0 ↔ token0
* reserve1 ↔ token1

For those topics see:

```text
notes/UV2Library--PairForAndCreate2.md
notes/Pair-getReserves.md
```

---

# My Confusion

Why do we need:

```solidity
IUniswapV2Pair(...)
```

?

Why not simply do:

```solidity
pairFor(...).getReserves();
```

?

---

# What I Was Thinking

We already know the Pair address.

So shouldn't we be able to call:

```solidity
address.getReserves()
```

directly?

---

# Reality

No.

Because:

```solidity
pairFor(...)
```

returns:

```solidity
address
```

only.

---

The compiler sees:

```solidity
address
```

and thinks:

```text
This is only an address.

I do not know what functions exist there.
```

---

# Child Analogy

Imagine:

```text
+91-9999999999
```

is a phone number.

The number tells you:

```text
Where
```

something is.

But not:

```text
What
```

that thing can do.

---

Similarly:

```solidity
address pair
```

tells Solidity:

```text
Where the contract lives
```

but not:

```text
What functions exist there.
```

---

# Therefore

We cast:

```solidity
IUniswapV2Pair(pairAddress)
```

which tells the compiler:

```text
Treat this address as a Pair contract.
```

---

Now Solidity knows:

```solidity
getReserves()
swap()
mint()
burn()
sync()
```

exist.

---

# Flow

```text
tokenA/tokenB
        ↓
pairFor()
        ↓
Pair Address
        ↓
Cast To IUniswapV2Pair
        ↓
Call getReserves()
        ↓
Receive Reserves
```

---

# Next Confusion

Pair returns:

```solidity
(
    uint112 reserve0,
    uint112 reserve1,
    uint32 blockTimestampLast
)
```

But the Library writes:

```solidity
(uint reserve0, uint reserve1,) =
```

instead of:

```solidity
(uint112 reserve0, uint112 reserve1,)
```

---

# My Thought

Shouldn't types match exactly?

Pair returns:

```solidity
uint112
```

so why receive:

```solidity
uint256
```

?

---

# Reality

Solidity automatically performs:

```text
Implicit Upcasting
```

---

Meaning:

```solidity
uint112
        ↓
uint256
```

safely.

---

# Why?

Because the Pair contract is optimized for:

```text
Storage
```

while the Library is optimized for:

```text
Math
```

---

# Pair Contract Goal

Store reserves efficiently.

```solidity
uint112 reserve0;
uint112 reserve1;
uint32 blockTimestampLast;
```

because:

```text
112 + 112 + 32
=
256 bits
```

which packs perfectly into one storage slot.

---

# Library Goal

Perform calculations.

Later functions will execute math such as:

```solidity
reserveIn * amountIn

reserveOut * amountInWithFee

reserveIn * reserveOut
```

and many other arithmetic operations.

---

For arithmetic:

```solidity
uint256
```

is the most convenient type.

---

# Important Realization

The EVM is fundamentally a:

```text
256-bit machine
```

---

Therefore:

```solidity
uint256
```

is its native arithmetic size.

---

# My Next Question

Does using:

```solidity
uint256
```

here create expensive storage usage?

---

# Reality

No.

These are:

```text
Local Function Variables
```

not storage variables.

---

This:

```solidity
uint reserve0;
```

does NOT create:

```text
Storage Slot
Persistent State
Blockchain Storage
```

---

Instead it exists temporarily during execution.

---

# Child Analogy

Storage:

```text
Hard Drive
```

Expensive.

Persistent.

---

Function Variables:

```text
RAM
```

Temporary.

Cheap.

---

# Important Takeaway

Storage optimization matters here:

```solidity
uint112 reserve0;
```

inside the Pair contract.

---

Storage optimization matters very little here:

```solidity
uint reserve0;
```

inside the Library.

---

# Another Confusion

Pair returns:

```solidity
reserve0
reserve1
blockTimestampLast
```

Yet the Library receives:

```solidity
(uint reserve0, uint reserve1,)
```

---

Why ignore the timestamp?

---

# What I Initially Thought

Maybe:

```text
The timestamp is ignored by Pair.
```

---

# Reality

No.

Pair still returns it.

---

The Library simply chooses not to store it.

---

Equivalent example:

```solidity
(uint a, uint b,) = someFunction();
```

If:

```solidity
someFunction()
```

returns:

```text
1
2
3
```

then:

```text
a = 1
b = 2
3 is discarded
```

---

# Why Does The Library Ignore It?

Because the purpose of this function is:

```text
Get Reserves

Fix Ordering

Return Reserves
```

---

It is NOT responsible for:

```text
TWAP
Oracle Logic
Price Accumulators
Time Tracking
```

---

Therefore only:

```text
reserve0
reserve1
```

are needed.

---

# Final Mental Model Before The Last Line

Pair Contract:

```text
Returns:
    reserve0
    reserve1
    blockTimestampLast
```

---

Library:

```text
Needs:
    reserve0
    reserve1
```

---

Timestamp is still returned by Pair.

Timestamp is simply discarded by the Library because it is irrelevant to reserve reordering.
---
>The next section will be the most important line in the entire function:
```solidity
(
    reserveA, reserveB) =
    tokenA == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
```
This is where the library finally translates:
```text
Pair Language:
token0/token1

into

Caller Language:
tokenA/tokenB
```

which is the actual purpose of Library.getReserves().

---

# Final Line - Translating Pair Reserves Into Caller Reserves

We have now reached the most important line in the function:

```solidity
(reserveA, reserveB) =
    tokenA == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
```

---

# My Confusion

This line looked insane at first.

Questions that came to mind:

```text
How did reserveA suddenly become tokenA's reserve?

Why are reserves being swapped?

Why don't we use token1?

Why compare tokenA to token0?

Why not compare both tokens?

What is actually happening here?
```

---

# Important Realization

Nothing is being modified.

Nothing is being updated.

Nothing is being written back to the Pair contract.

This line only determines:

```text
Which reserve value should be returned
as reserveA and reserveB.
```

---

# What We Know So Far

The Pair contract always speaks in:

```text
token0
token1

reserve0
reserve1
```

and guarantees:

```text
reserve0 ↔ token0

reserve1 ↔ token1
```

(For the exact proof of this relationship, is establised in the Pair Contract `_update()`.)

---

# What The Caller Speaks

The caller does not care about:

```text
token0
token1
```

The caller asked:

```solidity
getReserves(
    factory,
    tokenA,
    tokenB
)
```

So the caller expects:

```text
reserveA ↔ tokenA

reserveB ↔ tokenB
```

---

# The Translation Problem

Suppose caller provides:

```text
tokenA = USDC
tokenB = WETH
```

After sorting:

```text
token0 = WETH
token1 = USDC
```

Pair returns:

```text
reserve0 = 100
reserve1 = 300000
```

---

If we simply returned:

```solidity
return (reserve0, reserve1);
```

caller would receive:

```text
100
300000
```

and might assume:

```text
reserveA = 100 USDC ❌

reserveB = 300000 WETH ❌
```

which is completely wrong.

---

# Why token1 Does Not Matter

One of my biggest questions was:

```text
Why only use token0?

Where did token1 go?
```

---

Answer:

A Pair only contains:

```text
token0
token1
```

Two tokens.

No more.

---

Therefore:

If:

```text
tokenA == token0
```

then automatically:

```text
tokenB == token1
```

---

If:

```text
tokenA != token0
```

then automatically:

```text
tokenA == token1

tokenB == token0
```

There is nowhere else for them to go.

---

# Child Analogy

Two chairs:

```text
Chair0
Chair1
```

Two people:

```text
Wasim
Ahmed
```

If I tell you:

```text
Wasim is sitting on Chair0
```

you immediately know:

```text
Ahmed is sitting on Chair1
```

without checking.

---

Same idea.

Knowing where one token belongs automatically tells us where the other token belongs.

---

# Expanding The Ternary Operator

Original:

```solidity
(reserveA, reserveB) =
    tokenA == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
```

Expanded:

```solidity
if (tokenA == token0) {
    reserveA = reserve0;
    reserveB = reserve1;
} else {
    reserveA = reserve1;
    reserveB = reserve0;
}
```

---

# Case 1

Caller:

```text
tokenA = WETH
tokenB = USDC
```

Sorted:

```text
token0 = WETH
token1 = USDC
```

Pair:

```text
reserve0 = 100
reserve1 = 300000
```

Condition:

```solidity
tokenA == token0
```

becomes:

```text
WETH == WETH
```

Result:

```solidity
reserveA = reserve0;
reserveB = reserve1;
```

Final:

```text
reserveA = 100 WETH
reserveB = 300000 USDC
```

Correct.

---

# Case 2

Caller:

```text
tokenA = USDC
tokenB = WETH
```

Sorted:

```text
token0 = WETH
token1 = USDC
```

Pair:

```text
reserve0 = 100
reserve1 = 300000
```

Condition:

```solidity
tokenA == token0
```

becomes:

```text
USDC == WETH
```

False.

Result:

```solidity
reserveA = reserve1;
reserveB = reserve0;
```

Final:

```text
reserveA = 300000 USDC
reserveB = 100 WETH
```

Correct.

---

# Another Confusion I Had

Where exactly does:

reserveA ↔ tokenA

get established?

---

The answer is:

This Library function establishes:

reserveA ↔ tokenA

reserveB ↔ tokenB

for its returned values.

Specifically here:

```solidity
reserveA = reserve0;
```

or

```solidity
reserveA = reserve1;
```

depending on which branch executes.

---

Important Clarification

At this point in the dissection we have NOT yet proven from the Pair contract code that:

reserve0 ↔ token0

reserve1 ↔ token1

We strongly infer this relationship from:

- Pair naming conventions
- Pair API design
- Uniswap architecture

but the actual assignment chain has not yet been traced.

That proof will appear later when we dissect:

```solidity
_update(...)
```

inside the Pair contract.

---

Therefore the safest statement right now is:

The Library assumes:

reserve0 ↔ token0

reserve1 ↔ token1

and translates those values into:

reserveA ↔ tokenA

reserveB ↔ tokenB

for the caller.

The exact origin of the reserve0/token0 relationship will be verified later during the `_update()` dissection.



---

# What This Function Really Does

This function does fetch reserves.

Specifically, it retrieves:

```solidity
reserve0
reserve1
```

from the Pair contract by calling:

```solidity
pair.getReserves()
```

---

However, fetching reserves is not its primary purpose.

The Pair contract already stores and manages reserve data.

The unique responsibility of this Library function is to:

```text
Translate

token0/token1 reserves

into

tokenA/tokenB reserves
```

for the caller.

---

This function does not:

- calculate reserves
- update reserves
- synchronize reserves
- modify Pair state

No state changes occur.

---

Its workflow is:

1. Determine token0.
2. Derive Pair address.
3. Fetch reserve0 and reserve1 from the Pair.
4. Reorder reserves to match tokenA/tokenB ordering.
5. Return the reordered reserves.

---

The real purpose is:

```text
Translate:

token0/token1 reserves

into

tokenA/tokenB reserves
```

---

# Mental Model

Pair Contract says:

`token0 -> reserve0`
`token1 -> reserve1`

Caller says:

I don't care about `token0/token1`.

I asked for:

`tokenA`
`tokenB`

Library says:

No problem.

I'll figure out whether:

`reserve0` belongs to `tokenA`

or

`reserve1` belongs to `tokenA`

and return them in your order.

>The Library is not creating new reserve relationships.The Library is reordering the answer to match the order the caller asked in.

---

# Final Summary

Step 1

```solidity
sortTokens(...)
```

Determine token0.

---

Step 2

```solidity
pairFor(...)
```

Calculate Pair address.

---

Step 3

```solidity
pair.getReserves()
```

Get:

```text
reserve0
reserve1
```

---

Step 4

Determine whether:

```text
tokenA == token0

hence, 

reserve0 == reserveA or reserveB
```

---

Step 5

Return reserves in the same order as the caller's tokens.

---

That is the entire purpose of:

```solidity
UniswapV2Library.getReserves()
```
