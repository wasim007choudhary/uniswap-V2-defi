# Uniswap V2 - Pair.getReserves() Detour

## Why We Went Inside The Pair Contract Before Understanding Library.getReserves()

---

# Where We Started

Inside `UniswapV2Library.sol`:

```solidity
function getReserves(
    address factory,
    address tokenA,
    address tokenB
)
    internal
    view
    returns (
        uint reserveA,
        uint reserveB
    )
{
    (address token0,) = sortTokens(tokenA, tokenB);

    (uint reserve0, uint reserve1,) =
        IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();

    (reserveA, reserveB) =
        tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
}
```

---

# My Question

Before understanding this function:

```text
Do we need to go inside Pair first?
```

---

# Answer

Yes.

Not because the library is complicated.

But because the library is adapting the output of:

```solidity
Pair.getReserves()
```

Without understanding what the Pair returns, the library function looks random.

---

# So We Opened Pair.getReserves()

```solidity
function getReserves()
    public
    view
    returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    )
{
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _blockTimestampLast = blockTimestampLast;
}
```

---

# First Impression

This looked almost stupidly simple.

```solidity
_reserve0 = reserve0;
_reserve1 = reserve1;
```

Basically:

```text
Read storage
Return storage
```

---

# Immediate Question

Where do these come from?

```solidity
reserve0
reserve1
blockTimestampLast
```

---

# Answer

Storage variables.

Something similar exists higher in the contract:

```solidity
uint112 private reserve0;
uint112 private reserve1;
uint32 private blockTimestampLast;
```

---

# My Confusion

Why store reserves separately?

Why not simply do:

```solidity
IERC20(token0).balanceOf(address(this))
```

every time?

---

# My Initial Thought

Because we need:

```text
Reserve Of Token0

Reserve Of Token1
```

separately.

Not one combined value.

---

# Correct But Incomplete

That is true.

However the deeper reason is:

```text
Reserve != Current Balance
```

---

# Massive Realization

Most beginners assume:

```text
reserve0
=
token0 balance
```

Always.

---

Reality:

```text
Not Always
```

---

# Example

Current State:

```text
reserve0 = 100 WETH
reserve1 = 300000 USDC
```

---

Someone directly transfers:

```solidity
WETH.transfer(pair, 50 ether);
```

to the Pair.

---

# What Happens?

Actual token balance:

```text
150 WETH
```

---

Stored reserve:

```text
100 WETH
```

---

# My Question

Will reserve0 become 150 automatically?

---

# Answer

No.

---

# Why?

ERC20 contract updates balances.

Uniswap Pair contract does not automatically know.

There is no magical notification.

---

# Therefore

Immediately after transfer:

```text
balanceOf(pair)
=
150
```

but

```text
reserve0
=
100
```

---

# Child Analogy

Warehouse

Inventory Record:

```text
100 boxes
```

---

Someone secretly adds:

```text
50 boxes
```

---

Reality:

```text
150 boxes
```

Inventory System:

```text
100 boxes
```

until inventory manager updates records.

---

# Mental Model

Balances:

```text
Actual Reality
```

---

Reserves:

```text
Protocol Accounting Reality
```

---

# Huge Takeaway

Uniswap swap math uses:

```text
reserve0
reserve1
```

not raw balances.

---

Because reserves represent:

```text
Official Recorded State
```

used by:

```text
x * y = k
```

calculations.

---

# Next Question

Why:

```solidity
uint112
```

instead of:

```solidity
uint256
```

?

---

# My Answer

Gas optimization.

Storage packing.

---

# Correct

Look at:

```text
112
+
112
+
32
=
256
```

---

One storage slot:

```text
256 bits
```

---

Therefore:

```text
reserve0
reserve1
blockTimestampLast
```

fit perfectly inside:

```text
ONE SLOT
```

---

# Visual

```text
Slot 0

| reserve0 | reserve1 | timestamp |
| 112 bits | 112 bits |  32 bits  |
```

---

# Without Packing

```solidity
uint256 reserve0;
uint256 reserve1;
uint256 timestamp;
```

would consume:

```text
Slot 0
Slot 1
Slot 2
```

---

# Important Correction

The gas saving comes from:

```text
Storage Packing
```

not merely because:

```text
uint112 < uint256
```

---

# New Question

Will uint112 eventually run out of space?

---

# Answer

Technically yes.

Practically no.

---

Maximum:

```text
2^112 - 1
```

which is approximately:

```text
5.19 × 10^33
```

---

Ridiculously large.

---

# New Question

How do I choose storage sizes?

---

# Rule

Most contracts:

```solidity
uint256
```

everywhere.

---

Use smaller types only when:

```text
1. You know maximum value.

2. Packing helps.

3. Gas matters.
```

---

# Storage Packing Rabbit Hole

Example:

```solidity
uint128 a;
uint64 b;
uint128 c;
```

---

Layout:

```text
Slot 0

| a(128) | b(64) | empty(64) |

Slot 1

| c(128) | empty(128) |
```

---

# My Question

Can a use the free 64 bits if it grows?

---

# Answer

No.

---

Variable boundaries are fixed.

```text
a
=
exactly 128 bits
```

forever.

---

Even if slot contains free space.

---

# Child Analogy

Apartment:

```text
Room A = 128 sq ft

Room B = 64 sq ft

Empty Space = 64 sq ft
```

---

Room A cannot break walls and expand.

---

Storage layout is fixed at compile time.

---

# Final Realization Before Returning To Library

The most important thing learned from Pair.getReserves():

```text
reserve0 belongs to token0

reserve1 belongs to token1
```

NOT:

```text
reserveA belongs to tokenA

reserveB belongs to tokenB
```

This distinction is exactly why the Library.getReserves() function exists.
---
---

# Continuing The Pair.getReserves() Investigation

At this point we had understood:

```text
reserve0 belongs to token0

reserve1 belongs to token1

blockTimestampLast stores the timestamp of the
last reserve synchronization

reserve0 != actual token balance necessarily
```

But there were still a few questions.

---

# My Question

If reserves already exist as storage variables:

```solidity
uint112 private reserve0;
uint112 private reserve1;
uint32 private blockTimestampLast;
```

then why does the function declare:

```solidity
returns (
    uint112 _reserve0,
    uint112 _reserve1,
    uint32 _blockTimestampLast
)
```

again?

---

# My Thinking

It felt like:

```text
reserve0 already exists

why create another reserve0?
```

Seems redundant.

---

# Reality

These are not storage variables.

These are:

```text
Named Return Variables
```

---

Storage Variables:

```solidity
reserve0
reserve1
blockTimestampLast
```

live permanently in contract storage.

---

Return Variables:

```solidity
_reserve0
_reserve1
_blockTimestampLast
```

exist only during function execution.

---

# Child Analogy

Warehouse:

```text
reserve0
reserve1
```

are the actual inventory.

---

Inventory Report:

```text
_reserve0
_reserve1
```

are the values copied onto a report sheet and handed back to the caller.

---

# Interesting Realization

Uniswap could have written:

```solidity
function getReserves()
    public
    view
    returns (
        uint112,
        uint112,
        uint32
    )
{
    return (
        reserve0,
        reserve1,
        blockTimestampLast
    );
}
```

and it would work exactly the same.

---

The version used by Uniswap is largely style and readability.

---

# Next Question

Why return:

```solidity
blockTimestampLast
```

at all?

Why not only:

```solidity
reserve0
reserve1
```

?

---

# My Thinking

Maybe:

```text
Time when somebody asked for reserves

Current block timestamp

Reserve query timestamp
```

---

# Reality

None of those.

---

The timestamp represents approximately:

```text
Time when reserves were last synchronized
```

through:

```solidity
_update(...)
```

---

# Important Clarification

It is NOT:

```text
Current Time
```

and NOT:

```text
Time getReserves() was called
```

---

Instead:

```text
Last Official Reserve Update Time
```

---

# Why Is That Useful?

At first it looks unnecessary.

But later Uniswap V2 uses time information for:

```text
TWAP

(Time Weighted Average Price)
```

calculations.

---

To know how long a particular price existed, the protocol needs:

```text
Current Time

Previous Time
```

---

Therefore it stores:

```solidity
blockTimestampLast
```

alongside reserves.

---

# Another Important Question

Suppose current state:

```text
reserve0 = 100

reserve1 = 300000

blockTimestampLast = 1000
```

---

Then somebody performs:

```solidity
WETH.transfer(pair, 50 ether);
```

directly to the Pair.

---

# My Answer

Actual token balance becomes:

```text
150
```

immediately.

---

But:

```text
reserve0
```

probably remains:

```text
100
```

because reserves have not been updated.

---

# Reality

Correct.

---

Immediately after transfer:

```text
Actual Balance = 150

reserve0 = 100

blockTimestampLast = 1000
```

---

Nothing changes.

---

# Why?

Because:

```text
Transfer Occurred

_update() Did Not Occur
```

---

The Pair contract intentionally separates:

```text
Physical Reality
```

from

```text
Accounting Reality
```

---

Physical Reality:

```text
ERC20 Balances
```

Current actual tokens inside the Pair.

---

Accounting Reality:

```text
reserve0

reserve1

blockTimestampLast
```

Last officially recorded state.

---

# Child Analogy

Warehouse:

```text
Actual Boxes = 150
```

Inventory System:

```text
Recorded Boxes = 100
```

---

Until inventory manager updates records:

```text
Official Count = 100
```

---

# Huge Takeaway

The protocol trusts:

```text
reserve0
reserve1
```

for swap calculations.

Not:

```solidity
balanceOf(address(this))
```

directly.

---

# Final Pair.getReserves() Mental Model

```text
reserve0
=
Last Recorded Token0 Reserve

reserve1
=
Last Recorded Token1 Reserve

blockTimestampLast
=
When Those Reserves Were Last Recorded
```

---

# Most Important Realization Before Returning To The Library

The entire reason we detoured into Pair was to learn:

```text
reserve0 belongs to token0

reserve1 belongs to token1
```

NOT:

```text
reserveA belongs to tokenA

reserveB belongs to tokenB
```

That distinction is the key to understanding why the Library version of:

```solidity
getReserves(...)
```

must reorder values before returning them.
