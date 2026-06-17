# Uniswap V2 Dissection Series

# getAmountOut()

---

## Why This Function Matters

This is one of the most important functions in Uniswap V2.

Without understanding `getAmountOut()`:

* AMMs feel like magic
* Swap pricing feels mysterious
* Slippage makes no sense
* Router logic becomes difficult to follow

Every swap in Uniswap eventually relies on this function.

Its job is simple:

> Given an input amount and pool reserves, determine how many output tokens can be received.
> It is to Calculates the output for **one swap between one pair**. ex. - ETH -> USDC

---
 
# Original Code
Customized for better gas optimization using custom errors and omitted the safeMath library as v8.+ does it automatically 
So used direct operation signs unlike uniswap v2!
```solidity
function getAmountOut(
    uint inputAmount,
    uint reserveIn,
    uint reserveOut
)
    internal
    pure
    returns (uint amountOut)
{
    if (inputAmount <= 0) {
            revert UV2Library__getAmountOut__InsufficientInputAmount();
        }
        if (reserveIn <= 0 || reserveOut <= 0) {
            revert UV2Library__getAmountOut__InsufficientLiquidity();
    }

    uint inputAmountWithFee =
        inputAmount * 997 ;

    uint numerator =
        inputAmountWithFee * reserveOut;

    uint denominator =
         inputAmountWithFee + (reserveIn * 1000);

    amountOut =
        numerator / denominator;
}
```
> Kindly also check the function natspecs for fully understand the calulations and more detailed stuffs!
---

# Child Analogy

Imagine a toy shop.

The shop owns:

* 100 Apples
* 100 Bananas

You walk into the shop carrying:

* 10 Apples

You ask:

> How many bananas can I get?

The shop cannot simply give you any amount.

It must:

* maintain inventory balance
* charge a small fee
* make sure the shop does not run out of bananas

That calculation is exactly what `getAmountOut()` performs.

---

# Function Name

```solidity
getAmountOut
```

English translation:

> Determine how many output tokens should be received.

Example:

Input:

```text
1000 USDC
```

Output:

```text
0.394 ETH
```

---

# Parameters

## inputAmount

```solidity
uint inputAmount
```

Represents:

> How many input tokens are entering the pool.

Example:

```text
1000 USDC
```

---

## reserveIn

```solidity
uint reserveIn
```

Represents:

> Current reserve of the token entering the pool.

Example:

```text
100000 USDC
```

Already stored inside the pool.

---

## reserveOut

```solidity
uint reserveOut
```

Represents:

> Current reserve of the token leaving the pool.

Example:

```text
40 ETH
```

Stored inside the same pool.

---

# Return Value

```solidity
returns (uint amountOut)
```

Represents:

> How many output tokens the trader receives.

Example:

```text
0.394 ETH
```

---

# Visibility

## internal

```solidity
internal
```

Meaning:

This function cannot be called directly by users.

Only:

* Router
* Library
* Other contracts

can call it.

---

## pure

```solidity
pure
```

Meaning:

The function reads no blockchain state.

It only uses:

* inputAmount
* reserveIn
* reserveOut

Everything required is passed as input.

---

# First Safety Check

```solidity
require(
    inputAmount > 0,
    "INSUFFICIENT_INPUT_AMOUNT"
);
```

Question:

Can a user swap zero tokens?

Example:

```text
0 USDC -> ETH
```

No.

The transaction reverts.

---

## Child Version

Imagine entering a toy shop and saying:

> I want bananas but I am giving zero apples.

The shopkeeper would refuse.

---

# Second Safety Check

```solidity
require(
    reserveIn > 0 &&
    reserveOut > 0,
    "INSUFFICIENT_LIQUIDITY"
);
```

Question:

Can an empty pool process swaps?

No.

Examples:

Invalid:

```text
USDC Reserve = 0
ETH Reserve = 40
```

Invalid:

```text
USDC Reserve = 100000
ETH Reserve = 0
```

Both reserves must be greater than zero.

---

# Fee Calculation

```solidity
uint inputAmountWithFee =
    inputAmount.mul(997);
```

This is where Uniswap charges its fee.

---

## Why 997?

Uniswap V2 charges:

```text
0.3%
```

So:

```text
100%
-0.3%
=
99.7%
```

Represented mathematically as:

```text
997 / 1000
```

---

# Example

User provides:

```text
1000 USDC
```

Only:

```text
997 USDC
```

participates in the pricing formula.

The remaining:

```text
3 USDC
```

becomes protocol fee for liquidity providers.

---

## Child Analogy

Imagine a toy shop.

You bring:

```text
1000 apples
```

Shopkeeper keeps:

```text
3 apples
```

as payment.

Only:

```text
997 apples
```

are used for the trade.

---

# Numerator

```solidity
uint numerator =
    inputAmountWithFee.mul(reserveOut);
```

Example:

```text
997 * 40 ETH
```

This forms the upper portion of the pricing equation.

---

# Why Multiply By reserveOut?

Because:

The output reserve determines how much output liquidity exists.

The more ETH available:

```text
Higher reserveOut
```

the more ETH can potentially leave.

---

# Denominator

```solidity
uint denominator =
    reserveIn.mul(1000)
    .add(inputAmountWithFee);
```

Example:

```text
100000 * 1000
+
997
```

---

# Why Add inputAmountWithFee?

Because after the trade:

The pool contains more input tokens.

Before:

```text
100000 USDC
```

After:

```text
100997 USDC
```

The pool state changes.

Price must account for this.

---

# Final Calculation

```solidity
amountOut =
    numerator / denominator;
```

This computes:

> The actual amount of output tokens received.

Example:

```text
0.394 ETH
```

---

# The Hidden Secret

You never see:

```text
x * y = k
```

inside this function.

Yet the entire function exists because of that equation.

The pricing formula used here was mathematically derived from:

```text
reserveIn * reserveOut = k
```

The constant product invariant.

---

# What This Function Is Really Doing

Suppose a pool currently contains:

```text
100000 USDC
40 ETH
```

A user wants to add:

```text
1000 USDC
```

The question becomes:

> How much ETH can safely leave the pool while preserving the AMM invariant?

That is exactly what this function calculates.

---

# Mental Model

This function is NOT:

* moving tokens
* changing reserves
* performing swaps

It is only:

```text
Pricing Engine
```

Its job is:

> Determine the maximum output amount allowed by the AMM.

---

# Common Interview Question

Question:

Why not simply calculate:

```text
inputAmount * reserveOut / reserveIn
```

Answer:

Because that assumes:

* price never moves
* reserves never change
* no fees exist

Real AMMs must account for:

* slippage
* changing reserves
* liquidity depth
* protocol fees
* invariant preservation

Therefore Uniswap uses the constant-product pricing formula instead.

---

# Key Takeaways

1. `inputAmount` is what the trader provides.
2. `reserveIn` is current pool liquidity of the input token.
3. `reserveOut` is current pool liquidity of the output token.
4. Uniswap charges a 0.3% fee.
5. The fee is represented by `997 / 1000`.
6. The formula is derived from `x * y = k`.
7. No tokens move in this function.
8. This function is purely a pricing engine.
9. Every swap route ultimately depends on this calculation.
10. Understanding this function is the foundation for understanding Uniswap V2.
