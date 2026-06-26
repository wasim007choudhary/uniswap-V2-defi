# UV2Pair -- _update() (Work In Progress)

## Mental Model Before Entering _update()

By the time `_update()` starts, the swap is already finished.

`_update()` exists to make the Pair remember what just happened.

---

swap()

=

Validate Trade

↓

_update()

=

Commit State

---

Reserves

=

Old Reality

Balances

=

New Reality

---

At first glance we assumed:

```solidity
reserve0 = balance0;
reserve1 = balance1;
```

and that's it.

But very quickly we discovered `_update()` is doing much more:

```text
Reserve Sync

+

Timestamp Accounting

+

Oracle Accounting

+

TWAP Preparation

+

State Commit
```

---

# Line 1

```solidity
require(
    balance0 <= uint112(-1) &&
    balance1 <= uint112(-1),
    'UniswapV2: OVERFLOW'
);
```

## First Thought

Looks like a normal overflow check.

---

## Question

Why are reserves `uint112` in the first place?

Why not:

```solidity
uint256 reserve0;
uint256 reserve1;
```

and avoid all this?

---

## Observation

I noticed:

```text
112 + 112 + 32 = 256
```

which perfectly fills a storage slot.

---

## Discussion

Uniswap intentionally stores:

```solidity
uint112 reserve0;
uint112 reserve1;
uint32 blockTimestampLast;
```

inside one storage slot.

Reason:

Gas optimization through storage packing.

---

## Additional Observation

The idea of a reserve exceeding:

```text
2^112 - 1
```

is practically unrealistic.

So Uniswap accepts a smaller type in exchange for cheaper storage forever.

---

## Question

Since I am using Solidity 0.8+, do I still need this check?

---

## Discovery

There are actually two different overflow categories.

### Arithmetic Overflow

Example:

```solidity
uint8 x = 255;
x = x + 1;
```

Old Solidity:

```text
0
```

Solidity 0.8+:

```text
Revert
```

---

### Type Conversion Overflow

Example:

```solidity
uint256 huge;
uint112 small = uint112(huge);
```

Solidity 0.8+ still allows truncation.

No automatic protection.

---

## Mental Model

```text
Arithmetic Overflow

≠

Type Conversion Overflow
```

This line protects:

```text
uint256

↓

uint112
```

not arithmetic.

---

## Final Realization

This require exists because later we do:

```solidity
reserve0 = uint112(balance0);
reserve1 = uint112(balance1);
```

Without the check the Pair could remember corrupted reserves.

---

# Line 2

```solidity
uint32 blockTimestamp =
    uint32(block.timestamp % 2**32);
```

## First Thought

Why not simply use:

```solidity
block.timestamp
```

?

---

## Question

Since I am using Solidity 0.8+, do I still need:

```solidity
% 2**32
```

?

---

## Discussion

Both:

```solidity
uint32(block.timestamp)
```

and:

```solidity
uint32(block.timestamp % 2**32)
```

produce the same result.

The modulo simply makes the intention obvious.

---

## What Is The Intention?

Uniswap intentionally creates:

```text
A 32-bit circular clock
```

instead of using an infinitely growing timestamp.

---

## Child Analogy #1

Car odometer.

```text
999999

↓

000000
```

after reaching the maximum value.

---

## Child Analogy #2

School clock.

```text
11

↓

0
```

after reaching the maximum hour.

---

## Example

Suppose:

```text
block.timestamp

=

4294967297
```

Then:

```text
4294967297 % 4294967296

=

1
```

Only the lower 32 bits remain.

---

## Mental Model

This line is NOT asking:

```text
What time is it?
```

It is preparing for:

```text
How much time passed?
```

---

## Final Realization

`blockTimestamp` is not a normal timestamp.

It is a position on a circular 32-bit clock.

---

# Line 3

```solidity
uint32 timeElapsed =
    blockTimestamp - blockTimestampLast;
// overflow is desired
```

## First Thought

Why would anyone ever want overflow?

---

## Question

If I am using Solidity 0.8+, do I still need special handling?

---

## Discussion

Original Uniswap was written before Solidity 0.8.

Back then:

```solidity
3 - 4
```

did NOT revert.

It wrapped.

---

## Question

Before Solidity 0.8, if developers forgot SafeMath, would they get these weird values?

---

## Answer

Yes.

That is exactly why SafeMath became so popular.

Without SafeMath:

```solidity
uint8 x = 0;

x = x - 1;
```

became:

```text
255
```

instead of reverting.

---

## Question

If I use unchecked in Solidity 0.8:

```solidity
3 - 4
```

becomes what?

0?

4?

---

## Answer

Neither.

It wraps to:

```text
2^32 - 1
```

for uint32 arithmetic.

---

## Child Analogy

Circular running track.

Track:

```text
0 1 2 3 4 5
```

Runner:

```text
4 → 5 → 0 → 1
```

The runner still moved forward.

---

## Example

Suppose:

```text
blockTimestampLast = 4294967294

blockTimestamp = 3
```

The clock wrapped.

Even though:

```text
3 < 4294967294
```

the subtraction still correctly measures elapsed time.

---

## Solidity 0.8+ Note

To preserve Uniswap behavior:

```solidity
unchecked {
    timeElapsed =
        blockTimestamp -
        blockTimestampLast;
}
```

---

## Mental Model

```text
Current Position On Clock

-

Previous Position On Clock

=

Time Passed
```

---

## Final Realization

This is one of the rare places where:

```text
Overflow

=

Feature
```

not bug.

---

# Line 4

```solidity
if (
    timeElapsed > 0 &&
    _reserve0 != 0 &&
    _reserve1 != 0
)
```

## First Thought

Looks like a safety check.

---

## Discovery

This is actually the first hint that `_update()` is secretly doing oracle accounting.

Not just reserve synchronization.

---

## Question

Will:

```solidity
_reserve0 != 0
_reserve1 != 0
```

ever matter after liquidity exists?

---

## Discussion

For active pools:

```text
Almost never.
```

But it still matters:

* Before first liquidity
* After all liquidity is removed
* To prevent division by zero

---

## Child Analogy

You cannot calculate:

```text
10 Apples

÷

0 Baskets
```

The answer is undefined.

---

## Additional Realization

This line is not asking:

```text
Should I update reserves?
```

It is asking:

```text
Do I have enough information
to record meaningful price history?
```

---

## Mental Model

Do we have:

```text
✓ Time Passed

✓ Token0 Liquidity

✓ Token1 Liquidity
```

If yes:

```text
Record Price History
```

---

## Final Realization

This is where `_update()` starts transforming from:

```text
Reserve Update Function
```

into:

```text
Oracle Accounting Function
```

---

# The rest are covered in **oracles/Oraclecles, go throgh all the notes one by one and you will get all that.
>The code lines look small below but it contains crazy stuffs, TWAP,custom uint224 in Q122.122, Cumulative, wwat uniswap uses and why not, who wuses twap , for whom the this lines were created. Please go trhough the and Come back. 
**Read all of them**



```solidity
price0CumulativeLast +=
    uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0))
    * timeElapsed;

price1CumulativeLast +=
    uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1))
    * timeElapsed;

reserve0 = uint112(balance0);

reserve1 = uint112(balance1);

blockTimestampLast = blockTimestamp;

emit Sync(reserve0, reserve1);
```
