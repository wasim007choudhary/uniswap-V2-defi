# UV2Pair -- swap()

## Introduction

Before dissecting `Pair.swap()`, there is one extremely important fact to remember:

The Router has already completed its work.

Specifically:

✓ Path has already been determined.

✓ Expected outputs have already been calculated.

✓ Slippage checks have already been performed.

✓ The first Pair has already received the input tokens.

✓ Routing destinations have already been determined.

Example:

```text
A → B → C
```

Router already figured out:

```text
Pair(A,B)
    ↓ sends B
Pair(B,C)
```

Router already calculated:

```text
How much B should come out?

How much C should come out?
```

Router already knows where outputs should go.

The Pair does not.

---

## Biggest Mental Shift

### Initial Thought

```text
Router:
    A → B → C

Pair:
    A → B → C
```

### Reality

The Pair does not think:

```text
"A is input."

"B is output."
```

The Pair thinks:

```text
"I sent amount0Out."

"I sent amount1Out."

"Let me inspect balances."

"Let me compare them against reserves."

"Let me reconstruct reality."
```

---

## Mental Model

```text
Router
    =
    Calculate & Route

--------------------------------

Pair
    =
    Verify & Enforce
```

---

## The Function

```solidity
function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
) external lock
```

---

# Function Arguments

## amount0Out

Amount of token0 that should leave the Pair.

Example:

```text
token0 = A

amount0Out = 5
```

Means:

```text
5 A leaves the Pair.
```

---

## amount1Out

Amount of token1 that should leave the Pair.

Example:

```text
token1 = B

amount1Out = 10
```

Means:

```text
10 B leaves the Pair.
```

---

## to

Destination address.

Important:

```text
to
```

does NOT have to be the user.

In a multi-hop swap:

```text
A → B → C
```

the destination is usually:

```text
Next Pair
```

not:

```text
User
```

Example:

```text
Pair(A,B)

sends B

↓

Pair(B,C)
```

This is how tokens move through the route.

---

## data
>Please Visit and read **[ notes/Core/FlashSWAPandAtomicTransaction ]** hightly recommended befor going any further!

Used for flash swaps.

Normal swap:

```solidity
new bytes(0)
```

or:

```text
data.length == 0
```

Flash swap:

```text
data contains arbitrary information
```

The Pair doesn't care what the bytes represent.

Could be:

```text
Tiger

Elephant

Loan Information

Arbitrage Parameters

Anything
```

The Pair simply passes the bytes to the callback.

---

# lock Modifier

```solidity
modifier lock() {
    require(unlocked == 1, 'LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
}
```

Purpose:

```text
Reentrancy Protection
```

Mental Model:

```text
Function enters
    ↓
Door closes
    ↓
Function executes
    ↓
Door opens
```

Equivalent concept:

```text
OpenZeppelin ReentrancyGuard
```

The exact implementation differs.

Purpose is the same.

---

# Step 1

```solidity
require(
    amount0Out > 0 ||
    amount1Out > 0,
    'INSUFFICIENT_OUTPUT_AMOUNT'
);
```

At least one token must leave.

Otherwise:

```text
Nothing is being swapped.
```

---

# Step 2

```solidity
(uint112 _reserve0, uint112 _reserve1,) = getReserves();
```

The Pair loads reserves.

---

## Common Confusion

### Q

Why not use balances?

### Initial Thought

Balances are the real numbers.

Why not use them?

---

### Example

Before:

```text
reserve0 = 10
reserve1 = 20
```

Someone donates:

```text
20 token0
```

Now:

```text
balance0 = 30
balance1 = 20
```

But reserves are still:

```text
reserve0 = 10
reserve1 = 20
```

---

### Realization

Balances:

```text
Current Reality
```

Reserves:

```text
Previous Snapshot
```

The Pair needs both.

---

### Final Mental Model

```text
Reserves

=

Before Picture

--------------------------------

Balances

=

After Picture

--------------------------------

Pair

=

Detective
```

---

# Step 3

```solidity
require(
    amount0Out < _reserve0 &&
    amount1Out < _reserve1,
    'INSUFFICIENT_LIQUIDITY'
);
```

The Pair verifies it owns enough inventory.

Example:

```text
reserve0 = 10

amount0Out = 15
```

Impossible.

Revert.

---

## Common Question

What if liquidity runs out in the middle of routing?

Answer:

```text
Cannot happen.
```

Every Pair validates its own liquidity before sending outputs.

---

# Step 4

```solidity
address _token0 = token0;
address _token1 = token1;
```

Gas optimization.

Reduces repeated storage reads.

---

# Step 5

```solidity
require(
    to != _token0 &&
    to != _token1,
    'INVALID_TO'
);
```

Prevent sending tokens directly to token contracts.

---

## Common Confusion

### Q

Why not send directly to token address?

Example:

```text
Send WETH
to WETH contract
```

---

### Problem

The token contract is not expecting swap outputs.

Tokens can become stuck.

Accounting can break.

Unexpected behavior can occur.

---

### Final Mental Model

```text
Outputs should go to:

✓ User

✓ Pair

✓ Arbitrage Contract

✓ Flash Swap Contract

Not

✗ Token Contracts
```

---

# Step 6

```solidity
if (amount0Out > 0)
    _safeTransfer(...);

if (amount1Out > 0)
    _safeTransfer(...);
```

The Pair sends outputs.

---

## Why Is Output Sent First?

This feels backwards.

We expect:

```text
Pay first

Receive later
```

But Uniswap does:

```text
Send first

Verify later
```

Why?

Flash Swaps.

The recipient gets temporary access to funds.

The Pair will later verify:

```text
Did payment arrive?

Did K survive?
```

If not:

```text
Revert everything.
```

---

## Atomicity

Even though tokens leave first:

```text
Send Tokens
    ↓
Verification Fails
    ↓
Revert
```

Result:

```text
Swap never happened.
```

Ethereum transactions are atomic.

---

# Step 7
>>Please Visit and read **[ notes/Core/FlashSWAPandAtomicTransaction ]** to fully understand flashswaps adn aTOMIC TRANSACTIONS

```solidity
if (data.length > 0)
    IUniswapV2Callee(to)
        .uniswapV2Call(...);
```

Flash swap callback.

Normal swap:

```text
Skipped
```

because:

```text
data.length == 0
```

Flash swap:

```text
Executed
```

because:

```text
data.length > 0
```

---

# Step 8

```solidity
balance0 =
    IERC20(_token0)
        .balanceOf(address(this));

balance1 =
    IERC20(_token1)
        .balanceOf(address(this));
```

The Pair measures reality.

Not assumptions.

Reality.

Current balances are fetched directly from token contracts.

---

# Biggest Realization

The Pair does not know:

```text
Who called.

What route exists.

What token is input.

What token is output.
```

The Pair measures balances.

Then reconstructs reality.

---

## Mental Model

```text
Router thinks in swaps.

Pair thinks in accounting.
```

---

# End of Part 1

We have now reached the point where:

```text
Tokens have been sent.

Flash callback has executed.

Actual balances have been measured.
```

Next section:

```text
amount0In

amount1In

Input reconstruction

Fee verification

K invariant
```

which is where the Pair becomes a detective and figures out what actually happened.
# UV2Pair -- swap() (Part 2)

---

# Step 9 — Reconstructing Inputs

```solidity
uint amount0In =
    balance0 > _reserve0 - amount0Out
        ? balance0 - (_reserve0 - amount0Out)
        : 0;

uint amount1In =
    balance1 > _reserve1 - amount1Out
        ? balance1 - (_reserve1 - amount1Out)
        : 0;
```

This is one of the most important parts of the entire swap function.

The Pair now asks:

```text
I know:

- Previous reserves
- What I sent out
- Current balances

Can I reconstruct what came in?
```

---

# Common Confusion

### Initial Thought

```text
Router already knows
the input amount.

Why doesn't Pair
just use that?
```

---

### Reality

The Pair does not trust Router.

The caller could be:

```text
✓ Router
✓ Arbitrage Contract
✓ Flash Swap Contract
✓ Custom Contract
```

Therefore Pair reconstructs reality itself.

---

# The Formula

Let's focus on token0.

```solidity
uint amount0In =
    balance0 > _reserve0 - amount0Out
        ? balance0 - (_reserve0 - amount0Out)
        : 0;
```

Equivalent:

```solidity
uint amount0In;

if (
    balance0 >
    (_reserve0 - amount0Out)
) {
    amount0In =
        balance0 -
        (_reserve0 - amount0Out);
} else {
    amount0In = 0;
}
```

---

# Mental Model

Expected Balance:

```text
Reserve Before Swap

-

Amount Sent Out
```

Actual Balance:

```text
Current Token Balance
```

Input Amount:

```text
Actual Balance

-

Expected Balance
```

---

# Example

Before:

```text
reserve0 = 100
```

Pair sends:

```text
amount0Out = 10
```

Expected:

```text
100 - 10

=

90
```

Actual:

```text
balance0 = 95
```

Difference:

```text
95 - 90

=

5
```

Therefore:

```text
amount0In = 5
```

---

# Biggest Realization

The Pair is not tracking swaps.

The Pair is performing accounting.

It asks:

```text
I expected 90.

I see 95.

Where did the extra 5 come from?
```

Answer:

```text
5 token0 entered.
```

---

# Common Confusion We Had

### Question

If:

```text
amount0Out > 0
```

doesn't that mean:

```text
amount0In = 0
```

?

---

### Initial Intuition

Yes.

Because normal swaps look like:

```text
A enters

↓

B leaves
```

---

### Reality

The Pair never assumes that.

The Pair simply measures balances.

For a standard Router swap:

```text
A enters

↓

amount0In > 0

↓

amount1Out > 0
```

or:

```text
B enters

↓

amount1In > 0

↓

amount0Out > 0
```

But the Pair code is written generally enough to support:

```text
Flash Swaps

Arbitrage

Custom Contracts
```

Therefore it measures reality.

---

# Final Mental Model

```text
The Pair does not think:

"A is input."

"B is output."

The Pair thinks:

"What left?"

"What arrived?"

"Let me compare balances."
```

---

# Step 10 — Input Validation

```solidity
require(
    amount0In > 0 ||
    amount1In > 0,
    'INSUFFICIENT_INPUT_AMOUNT'
);
```

---

# Purpose

The Pair already sent tokens out.

Now it asks:

```text
Did anything come back?
```

---

# Example

Before:

```text
100 A

200 B
```

Pair sends:

```text
10 A
```

Current balances:

```text
90 A

200 B
```

Result:

```text
amount0In = 0

amount1In = 0
```

Pair concludes:

```text
I gave tokens away.

Nobody paid me.
```

Revert.

---

# Mental Model

Previous Check:

```text
Do I have inventory
to send?
```

This Check:

```text
Did I receive payment?
```

---

# Step 11 — Fee Adjusted Invariant

```solidity
uint balance0Adjusted =
    balance0 * 1000
    - amount0In * 3;

uint balance1Adjusted =
    balance1 * 1000
    - amount1In * 3;
```

---

# Common Confusion

### Question

Didn't Router already calculate fees?

---

### Answer

Yes.

But Router only calculates.

Pair enforces.

Router says:

```text
Assuming fee is paid,
output should be X.
```

Pair later verifies:

```text
Was the fee actually paid?
```

---

# Why 1000?

Uniswap fee:

```text
0.3%

=

3 / 1000
```

Because Solidity has no decimals:

```text
1000

=

100%

3

=

0.3%

997

=

99.7%
```

---

# Example

User sends:

```text
100 token0
```

Fee:

```text
100 × 0.3%

=

0.3
```

Effective Input:

```text
99.7
```

---

# What balanceAdjusted Really Means

```text
balanceAdjusted
```

is NOT:

```text
Reserve

Balance

Token Amount
```

It is:

```text
Temporary Fee-Adjusted Balance
```

used only for invariant verification.

---

# Mental Model

```text
Remove Fee

↓

Check Invariant

↓

Discard Value
```

---

# Biggest Realization

```text
balanceAdjusted

is fake accounting data.

It exists solely
for the K check.
```

---

# End of Part 2

We now know:

```text
✓ What left

✓ What entered

✓ Payment was received

✓ Fee was accounted for
```

The final step is:

```text
Did the completed swap
respect the AMM invariant?
```

Which leads directly into:

```solidity
require(
    balance0Adjusted
        * balance1Adjusted
    >=
    reserve0
        * reserve1
        * 1000**2,
    "Uniswap: K"
);
```

The most famous line in Uniswap V2.
# UV2Pair -- swap() (Part 3)

---

# Step 12 — The K Invariant Check

```solidity id="2w4yzm"
require(
    balance0Adjusted
        * balance1Adjusted
    >=
    uint256(_reserve0)
        * uint256(_reserve1)
        * 1000**2,
    "Uniswap: K"
);
```

This is the final security check of the swap.

Everything before this point was preparing for this moment.

---

# What Is The Pair Asking?

The Pair asks:

```text id="w0qt6s"
After accounting for fees,

did this swap violate
the AMM invariant?
```

Or more simply:

```text id="wjkr96"
Did somebody steal value
from the pool?
```

---

# Common Confusion

### Initial Thought

```text id="nwtf84"
K must always remain constant.
```

---

### Reality

Without fees:

```text id="9v4u3q"
New K

=

Old K
```

Exactly.

---

Example:

Before:

```text id="r9zw1z"
10 * 5

=

50
```

After:

```text id="1t3v1r"
20 * 2.5

=

50
```

Still:

```text id="h3ehj9"
K = 50
```

---

# But Uniswap Has Fees

Uniswap charges:

```text id="jq3u6w"
0.3%
```

and keeps that fee inside the pool.

Therefore:

```text id="ckhtvc"
New K

>=

Old K
```

Usually:

```text id="fw6b5z"
New K

>

Old K
```

---

# Biggest Realization

Constant Product AMM does NOT mean:

```text id="k49uv9"
K remains constant forever.
```

It means:

```text id="6k6u9y"
K must never decrease.
```

---

# Common Confusion

### Question

We already removed fees using:

```solidity id="jvcms5"
balance0Adjusted

balance1Adjusted
```

So why:

```solidity id="bvgfuk"
>=
```

instead of:

```solidity id="9q6h9j"
==
```

?

---

### Answer

Because Solidity uses integer math.

Integer math introduces rounding.

Uniswap intentionally rounds in favor of the pool.

Therefore:

```text id="l7gqza"
Perfect Mathematical Result

↓

K = Old K

--------------------------------

Real Solidity Result

↓

K >= Old K
```

---

# Final Mental Model

The invariant is:

```text id="w3gxrz"
K must not decrease.
```

That's it.

That is the entire purpose of this line.

---

# Common Confusion

### Question

Does Router verify K?

---

### Answer

No.

Router never verifies K.

Router only predicts output amounts.

Example:

```solidity id="e0u78q"
getAmountOut(...)
```

calculates:

```text id="rw78l4"
Given reserves
and amountIn,

how much output
should exist?
```

---

Router performs:

```text id="sd2eyv"
Price Discovery
```

Pair performs:

```text id="8rjlwm"
Price Enforcement
```

---

# Mental Model

```text id="v9c8m5"
Router

=

Calculator

--------------------------------

Pair

=

Judge
```

Router predicts.

Pair verifies.

---

# Common Confusion

### Question

Why are reserves cast?

Original Uniswap:

```solidity id="6kl2lc"
uint(_reserve0)
    .mul(_reserve1)
```

Only one reserve is cast.

Why?

---

### Answer

Once one operand becomes:

```text id="6k5ylm"
uint256
```

the other operand is automatically promoted.

Therefore:

```solidity id="cw89t6"
uint256(_reserve0)
    * _reserve1
```

already performs:

```text id="ajk1hj"
uint256 arithmetic
```

for both operands.

---

# Modern Solidity

Valid:

```solidity id="svjcbf"
uint256(_reserve0)
    * _reserve1
```

Also valid:

```solidity id="10gc3m"
uint256(_reserve0)
    * uint256(_reserve1)
```

Second version is simply more explicit.

---

# Important Note

Your implementation:

```solidity id="jvxyzk"
if (
    balance0Adjusted
        * balance1Adjusted
    <
    uint256(reserve_0)
        * uint256(reserve_1)
        * 1000**2
) {
    revert UV2Pair___swap__BrokeTheUniswapAMMconstantVariant__K();
}
```

is logically identical to:

```solidity id="8v8mw4"
require(
    balance0Adjusted
        * balance1Adjusted
    >=
    uint256(_reserve0)
        * uint256(_reserve1)
        * 1000**2,
    "K"
);
```

One checks:

```text id="5p0y9v"
Pass Condition
```

The other checks:

```text id="5q5hj2"
Fail Condition
```

Same invariant.

Same result.

---

# Final State Validation Complete

At this point the Pair has verified:

```text id="mkl9f1"
✓ Liquidity exists

✓ Outputs were sent

✓ Callback executed

✓ Inputs reconstructed

✓ Payment received

✓ Fee paid

✓ K not violated
```

The swap is valid.

---

# Step 13 — Commit New State

```solidity id="vwr1x8"
_update(
    balance0,
    balance1,
    _reserve0,
    _reserve1
);
```

The Pair now updates reserves.

Important:

During the ENTIRE swap:

```text id="6n8s3z"
_reserve0

_reserve1
```

were frozen snapshots.

Balances changed.

Reserves did not.

Now the Pair commits:

```text id="rtg0ux"
Current Balances

↓

New Reserves
```

---

# Mental Model

```text id="1rqy1v"
swap()

=

Validate Trade

--------------------------------

_update()

=

Commit New State
```

---

# Deep Dive Reference

The following topics belong to:

```text id="57qfh4"
UV2Pair--_update.md
```

not this document:

```text id="n0m5o0"
- reserve synchronization

- timestamp updates

- cumulative price tracking

- oracle mechanics

- TWAP preparation
```

For now remember:

```text id="jlwm7r"
_update()

=

Store balances
as new reserves.
```

---

# Step 14 — Emit Event

```solidity id="0d5zsp"
emit Swap(
    msg.sender,
    amount0In,
    amount1In,
    amount0Out,
    amount1Out,
    to
);
```

Purpose:

```text id="1v1y9f"
Tell the outside world
that a swap occurred.
```

Used by:

```text id="4h3t1l"
✓ Frontends

✓ Block Explorers

✓ Indexers

✓ Analytics Platforms

✓ Monitoring Tools
```

No state changes occur.

Only information is emitted.

---


## Final Two Lines

```solidity
_update(balance0, balance1, _reserve0, _reserve1);

emit Swap(
    msg.sender,
    amount0In,
    amount1In,
    amount0Out,
    amount1Out,
    to
);
```

### `_update(...)`

Purpose:

```text
Store the current balances
as the new reserves. Also it acts as Price Oracle which you will go in dept in while dissecting that function
```

The swap has already been validated.

`_update()` commits the new state of the Pair and performs additional reserve/oracle accounting.

For a complete line-by-line breakdown see:

**notes/Core/UV2Pair--_update.md** after this then go to **notes/Oracles** and clean it up all! You will undrstand some crazy stuff there. GGs

---

### `emit Swap(...)`

Purpose:

```text
Inform the outside world
that a swap occurred.
```

Used by:

* Frontends
* Indexers
* Block Explorers
* Analytics Platforms

No state changes occur.

The event only records what happened.

---

# Final Mental Model Of Pair.swap()

```text id="3w8e2f"
Router

↓

Calculates Outputs

↓

Transfers Initial Input

--------------------------------

Pair

↓

Checks Liquidity

↓

Sends Outputs

↓

Executes Flash Callback

↓

Measures Balances

↓

Reconstructs Inputs

↓

Verifies Payment

↓

Applies Fee Logic

↓

Verifies K

↓

Updates Reserves

↓

Emits Event(show the outside world this and that mainly for frontend)

↓

Swap Complete
```

---

# Biggest Takeaway From This Entire Deep Dive

At the beginning it is natural to think:

```text id="53g0p8"
Pair executes swaps.
```

After studying the code:

```text id="gtl33s"
Pair performs accounting.
```

The Pair does not know:

```text id="gcgyjf"
Which route exists.

Who called.

Which token is input.

Which token is output.
```

The Pair only knows:

```text id="kzk8d7"
Reserves

Balances

Outputs

Current State
```

and reconstructs reality.

---

# Ultimate Mental Model

```text id="lm4fjr"
Router thinks in routes.

Pair thinks in accounting.
```

That single sentence explains almost every design decision inside `UV2Pair.swap()`.
