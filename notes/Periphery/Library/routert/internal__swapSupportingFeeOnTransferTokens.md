# `_swapSupportingFeeOnTransferTokens()`

> **Prerequisite**
>
> Before reading these notes, first read:
>
> **`notes/Periphery/Router/_swap.md`**
>
> Almost everything inside this function (loop, `sortTokens()`, `pairFor()`, reserve mapping, `getAmountOut()`, `amount0Out/amount1Out`, routing to the next Pair, `pair.swap()`, etc.) was already completely dissected there.
>
> This file focuses only on **what is different** for fee-on-transfer tokens, while briefly referencing concepts already covered.

---

> **Important**
>
> Before entering `_swapSupportingFeeOnTransferTokens()`, the public function has **already transferred the input tokens to the first Pair** via `TransferHelper.safeTransferFrom()`.
>
> So when this function starts, the **first Pair already holds the input tokens** (after any transfer fees charged by the token contract).
>
> Here, we check the **actual input amount received** (after fees), then perform the swap just like `_swap()`.
---

# Purpose

```solidity
function _swapSupportingFeeOnTransferTokens(
    address[] memory path,
    address _to
) internal
```

This function performs the **actual swaps** for fee-on-transfer (tax/burn/reflection) tokens.

Unlike the normal `_swap()`, this function **does not trust the input amount supplied by the user**.

Instead, before every swap, it measures **how many input tokens actually reached the Pair**, then calculates the correct output from that measured value.

---

# Execution Flow

```text
For Every Pair

↓

Determine input/output token

↓

Locate Pair

↓

Read reserves

↓

Determine reserveInput/reserveOutput

↓

Measure actual input received

↓

Calculate amountOutput

↓

Convert to amount0Out/amount1Out

↓

Determine receiver

↓

Call Pair.swap()

↓

Next Pair
```

---

# Biggest Difference From `_swap()`

Normal `_swap()` already knows every output amount.

```text
getAmountsOut()

↓

amounts[]

↓

_swap()

↓

pair.swap()
```

This only works because normal ERC20 tokens transfer exactly the amount requested.

```text
User sends 100

↓

Pair receives 100
```

---

Fee-on-transfer tokens break that assumption.

Example:

```text
User sends 100

↓

Token deducts 2

↓

Pair receives 98
```

Now:

```text
amountIn = 100
```

is no longer correct.

Therefore this Router measures reality instead of trusting assumptions.

---

# Loop

```solidity
for (uint256 i; i < path.length - 1; i++)
```

Exactly the same as `_swap()`.

Iterates through every Pair in the swap path.

Already discussed.

---

# Current Input & Output Tokens

```solidity
(address input, address output) =
    (path[i], path[i + 1]);
```

Exactly the same as `_swap()`.

Already discussed.

---

# Determine `token0`

```solidity
(address token0,) =
    UniswapV2Library.sortTokens(input, output);
```

Already dissected.

This simply determines which token has the smaller address.

---

# Locate The Pair

```solidity
IUniswapV2Pair pair =
    IUniswapV2Pair(
        UniswapV2Library.pairFor(
            factory,
            input,
            output
        )
    );
```

Already discussed in detail.

The Router stores the Pair interface because it will call multiple functions on it:

```solidity
pair.getReserves();

pair.swap(...);
```

Instead of repeatedly writing:

```solidity
IUniswapV2Pair(
    UniswapV2Library.pairFor(...)
)
```

the Router casts once and reuses the interface.

> **Note**
>
> The following is functionally equivalent:
>
> ```solidity
> IUniswapV2Pair(
>     UniswapV2Library.pairFor(...)
> ).swap(...);
> ```
>
> The stored variable simply makes the code cleaner.

---

# Declare Variables

```solidity
uint256 amountInput;
uint256 amountOutput;
```

Unlike `_swap()`, `amountInput` is **not already known**.

It will be measured from the Pair's balance.

---

# Read Reserves

```solidity
(uint256 reserve0, uint256 reserve1,) =
    pair.getReserves();
```

Already dissected.

Notice the Router stores them as `uint256` even though the Pair returns `uint112`.

This is simply an implicit widening conversion.

The Router performs arithmetic using `uint256`, so widening once keeps the code cleaner.

---

# Determine `reserveInput` & `reserveOutput`

```solidity
(uint256 reserveInput, uint256 reserveOutput) =
    input == token0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
```

Already covered in `_swap()`.

The Pair stores:

```text
reserve0
reserve1
```

It never stores:

```text
reserveInput
reserveOutput
```

The Router establishes that relationship every iteration.

Example:

```text
token0 = USDC
token1 = WETH
```

Swap:

```text
USDC → WETH
```

becomes:

```text
reserveInput = reserve0

reserveOutput = reserve1
```

Reverse swap:

```text
WETH → USDC
```

becomes:

```text
reserveInput = reserve1

reserveOutput = reserve0
```

The relationship between `input` and `reserveInput` is established right here.

---

# ⭐ Measure Actual Input

```solidity
amountInput =
    IERC20(input)
        .balanceOf(address(pair))
        .sub(reserveInput);
```

This is the entire reason this function exists.

---

## Purpose

Determines:

> **"How many input tokens actually reached the Pair?"**

Not:

> "How many the user wanted to send."

Not:

> "How many `amountIn` says."

But:

> "How many tokens are actually inside the Pair because of this swap?"

---

## Why Doesn't It Use `amountIn`?

Suppose Alice swaps:

```text
50 USDC → XYZ
```

The Router knows:

```text
amountIn = 50
```

Can it trust that?

No.

Suppose the token charges a 2% transfer fee.

Execution becomes:

```text
Alice sends

50

↓

Token deducts

1

↓

Pair receives

49
```

Now:

```text
amountIn = 50
```

is incorrect.

---

## Step 1 — Read Pair Balance

```solidity
IERC20(input).balanceOf(address(pair))
```

Suppose before the transfer:

```text
Pair Balance

1000
```

After the transfer:

```text
Pair Balance

1049
```

This is the Pair's **actual ERC20 balance**.

---

## Common Confusion — Isn't This The Total Balance?

Yes.

The current balance contains:

```text
Old Liquidity

+

New Tokens
```

We don't want:

```text
1049
```

We only want:

```text
49
```

---

## Step 2 — Subtract Previous Reserve

```solidity
.sub(reserveInput)
```

Suppose:

```text
reserveInput

1000
```

Current balance:

```text
1049
```

Now:

```text
1049

-

1000

=

49
```

Now the Router knows:

```text
Actual Input

49
```

---

## Biggest Realization

When execution reaches this line:

```solidity
amountInput =
    balanceOf(pair)
    - reserveInput;
```

the Pair has **not** executed:

```solidity
_update(...)
```

yet.

Therefore:

```text
Current Balance

≠

Stored Reserve
```

The reserve is still the **old stored value**.

The balance already includes the newly transferred tokens.

Example:

Before transfer:

```text
Reserve = 1000

Balance = 1000
```

After transfer:

```text
Reserve = 1000

Balance = 1049
```

The Router subtracts:

```text
1049

-

1000

=

49
```

Later, inside `pair.swap()`, the Pair finally executes:

```solidity
_update(...)
```

and storage becomes:

```text
Reserve = 1049
```

At that point:

```text
Reserve

=

Balance
```

again.

---

## Common Confusion — Where Was The Transfer Fee Deducted?

The Router never subtracts the transfer fee.

The fee was already deducted earlier inside the token contract during:

```solidity
transferFrom(...)
```

This line simply measures the final result.

Think of a warehouse:

```text
Yesterday

1000 Boxes

↓

Truck claims

"I shipped 50."

↓

Warehouse counts

1049

↓

1049

-

1000

=

49 arrived
```

The warehouse didn't remove a box.

It simply counted what actually arrived.

The Router does exactly the same thing.

---

# Calculate Output

```solidity
amountOutput =
    UniswapV2Library.getAmountOut(
        amountInput,
        reserveInput,
        reserveOutput
    );
```

Already dissected in detail.

Nothing inside `getAmountOut()` changes.

The LP fee is identical.

The constant product formula is identical.

The only difference is:

Normal Router:

```text
User's intended input

↓

getAmountOut()
```

Fee-On-Transfer Router:

```text
Actual Pair input

↓

getAmountOut()
```

---

# Determine `amount0Out` / `amount1Out`

```solidity
(uint256 amount0Out, uint256 amount1Out) =
    input == token0
        ? (uint256(0), amountOutput)
        : (amountOutput, uint256(0));
```

Exactly identical to `_swap()`.

Nothing changes.

The only difference is where `amountOutput` came from.

---

# Determine Receiver

```solidity
address to =
    i < path.length - 2
        ? UniswapV2Library.pairFor(
            factory,
            output,
            path[i + 2]
        )
        : _to;
```

Already discussed in `_swap()`.

If another hop exists:

```text
Current Pair

↓

Next Pair
```

Otherwise:

```text
Current Pair

↓

Final Recipient
```

The Router streams tokens directly from Pair to Pair without holding them itself.

---

# Execute Swap

```solidity
pair.swap(
    amount0Out,
    amount1Out,
    to,
    new bytes(0)
);
```

Everything about `swap()` has already been dissected.

The only thing worth noting here is:

```solidity
new bytes(0)
```

which creates an empty bytes array.

Inside the Pair:

```solidity
if (data.length > 0) {
    IUniswapV2Callee(to).uniswapV2Call(...);
}
```

Since:

```text
data.length == 0
```

the Pair performs a **normal swap**.

No callback.

No flash swap.
>For flash we have to go through pair.swap directly, no router, raw call to the pair contract from the flash acting contrct.

---

# Final Takeaway

This function is almost identical to `_swap()`.

The Pair behaves exactly the same.

The pricing formula is exactly the same.

The LP fee is exactly the same.

The invariant check is exactly the same.

The **only fundamental difference** is this single line:

```solidity
amountInput =
    IERC20(input)
        .balanceOf(address(pair))
        .sub(reserveInput);
```

Instead of trusting the user's declared input amount, the Router measures the Pair's actual received input. Everything else in the swap process remains unchanged.