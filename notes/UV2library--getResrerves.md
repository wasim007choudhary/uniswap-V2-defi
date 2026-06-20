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