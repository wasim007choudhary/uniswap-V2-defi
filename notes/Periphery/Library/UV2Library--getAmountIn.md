

# UniswapV2Library `getAmountIn()`

## First Realization

At first glance this looked like a completely different formula from `getAmountOut()`.

My question was:

```text
I can see the same dy formula with everything inversed and with a twist of +1 added ?
```

Realization:

```text
No.

This is not a different AMM.

This is the SAME AMM.

The question has simply been flipped adn a +1 .
```

---

## Mental Model

`getAmountOut()`

```text
Known: dx (amountIn)

Find: dy (amountOut)
```

###### In Q/A terms:

```text
I have this much input.

How much output will I get?
```

---

`getAmountIn()`

```text
Known: dy (amountOut)

Find: dx (amountIn)
```

###### In Q/A term:

```text
I want this much output.

How much input must I provide?
```

---




### Store Analogy

###### In Q/A term 1:-

```text
I have $10.

How many apples can I buy?
```

Equivalent to:

```text
getAmountOut()
```

---

###### In Q/A term 2:-

```text
I want 5 apples.

How many dollars must I bring?
```

Equivalent to:

```text
getAmountIn()
```

Same store.

Same apples.

Different unknown variable.

---
#### My realization:

```text
Bro if I just turn the question upside down then boom?
```

Answer:

```text
YES.
```

This function is basically:

```text
getAmountOut()

↓

Turn the question upside down

↓

Solve for `dx` instead of `dy` with a twitst of `+1` at the end which
I thought to just remeber without understanding but I was like nah 
lets dig deep! `Start from AMM core itself `X * Y = k`
```

---

# Starting From The Invariant

Instead of starting from:

```text
dy = (y * dx * 0.997) / (x + dx * 0.997) 
```
- which is the `UniswapV2 SWAP FORMULA` for `dy` BTW!
it is easier to start from:

```text
X * Y = k
```

because that is the actual AMM invariant where that formula came from .
>Lets Start the Math!




---

# Deriving `getAmountIn()` From The Constant Product Formula

Every Uniswap V2 pool must always satisfy:

```text
X * Y = k
```

Where:

```text
X = reserve of token X
Y = reserve of token Y
k = constant product
```

This invariant must hold:

* Before a swap
* After a swap

---

## 1️⃣ Initial Pool State

Before the trade:

```text
X = X₀
Y = Y₀
```

Therefore:

```text
X₀ * Y₀ = k
```

---

## 2️⃣ Trader Wants Output

Unlike `getAmountOut()`:

```text
Known: dx

Find: dy
```

Here we in `getAmountIn` know:

```text
Known: dy

Find: dx
```

The trader says:

```text
I want dy tokens out.
```

and Uniswap must determine:

```text
How much dx must be supplied?
```

---

## 3️⃣ Pool State After The Swap

The trader receives:

```text
dy
```

tokens.

Therefore:

```text
Y₁ = Y₀ - dy
```

---

The trader supplies:

```text
dx
```

tokens.

However Uniswap charges:

```text
0.3% fee
```

Therefore only:

```text
dx * 0.997
```

participates in the invariant.

So:

```text
X₁ = X₀ + dx * 0.997
```

---

## 4️⃣ Apply The Invariant

The pool must still satisfy:

```text
X₁ * Y₁ = k
```

Substitute:

```text
(X₀ + dx * 0.997)(Y₀ - dy) = k
```

But:

```text
k = X₀ * Y₀
```

Therefore:

```text
(X₀ + dx * 0.997)(Y₀ - dy)
=
X₀ * Y₀
```

---

## 5️⃣ Expand The Left Side

Multiply everything:

```text
X₀Y₀ - X₀dy + dx*0.997*Y₀ - dx*0.997*dy

=
X₀Y₀
```

---

## 6️⃣ Cancel Common Terms

Subtract:

```text
X₀Y₀
```

from both sides:

```text
-X₀dy + dx*0.997*Y₀ - dx*0.997*dy = 0
```

---

## 7️⃣ Move Terms

Move:

```text
X₀dy
```

to the right side:

```text
dx*0.997*Y₀ - dx*0.997*dy = X₀dy
```

---

## 8️⃣ Factor Out dx*0.997

Left side:

```text
dx*0.997*Y₀ - dx*0.997*dy
```

contains a common factor:

```text
dx*0.997
```

Factor it out:

```text
dx*0.997(Y₀ - dy) = X₀dy
```

---

## 9️⃣ Solve For dx

Divide both sides by:

```text
0.997(Y₀ - dy)
```

Result:

```text
          X₀dy
dx = -----------------
      0.997(Y₀ - dy)
```

---

## 🔟 Replace 0.997

Uniswap/soldidity avoids decimals.

Instead:

```text
0.997 = 997 / 1000
```

Substitute:

```text
             X₀dy
dx = -----------------------
      (997/1000)(Y₀ - dy)
```

---

## 1️⃣1️⃣ Remove The Decimal

We currently have:

```text
            X₀dy
dx = --------------------
      (997/1000)(Y₀-dy)
```

Uniswap avoids decimals.

We do not want:

```text
997/1000
```

inside the denominator.

---

Therefore multiply BOTH the numerator and denominator by:

```text
1000
```

Remember:

```text
      a          a × 1000
     ---   =   -----------
      b          b × 1000
```

This does NOT change the value.

---

Applying that:

```text
            X₀dy × 1000
dx = ---------------------------
      (997/1000)(Y₀-dy) × 1000
```

The:

```text
/1000
```

cancels out:

```text
       X₀dy × 1000
dx = ---------------
       997(Y₀-dy)
```

Or:

```text
          X₀dy * 1000
dx = ---------------------
        (Y₀ - dy) * 997
```

---

## 1️⃣2️⃣ Convert To Solidity Variables

Replace:

```text
X₀  → reserveIn

Y₀  → reserveOut

dx  → amountIn

dy  → amountOut
```

Result:

```text
                  reserveIn * amountOut * 1000
amountIn = ------------------------------------------------
            (reserveOut - amountOut) * 997
```

---

## 1️⃣3️⃣ Match The Actual Code

Numerator:

```solidity
uint numerator =
    reserveIn
        .mul(amountOut)
        .mul(1000);
```

becomes:

```text
reserveIn * amountOut * 1000
```

---

Denominator:

```solidity
uint denominator =
    (reserveOutn - amountOut) * 997;
```

becomes:

```text
(reserveOut - amountOut) * 997
```

---

Therefore:

```solidity
amountIn = numerator / denominator;
```

is exactly:

```text
            reserveIn * amountOut * 1000
amountIn = ---------------------------------
            (reserveOut - amountOut) * 997
```

---

## 1️⃣4️⃣ Now we will need to do +1 , So Why The +1 ?

Solidity integer division always rounds:

```text
DOWN
```

Example:

```text
100 / 3

=
33.333...
```

Solidity returns:

```text
33
```

---

But `getAmountIn()` calculates:

```text
Minimum required input
```

If the true answer is:

```text
33.333...
```

Then:

```text
33
```

is insufficient.

Therefore Uniswap rounds up:

```solidity
amountIn =
    (numerator / denominator) + 1;
```

which guarantees enough input is provided.

---

# Final Mental Model

```text
getAmountOut()

Known: dx

Find: dy

--------------------------------

getAmountIn()

Known: dy

Find: dx
```

Same AMM.

Same fee.

Same invariant.

Same curve.

Just with A `+1` for rounding and avoinding `< amountIn`

Just solving the equation for the opposite variable and Just with A `+1` for rounding and avoinding `< amountIn`

 # Final copy Paste formula for mainly Soldity and Uniswap -             
```solidity
amountIn = (reserveIn * amountOut * 1000/(reserveOut - amountOut) * 997) + 1
```

Or in Algebric terms 
```solidity
dx = (X₀dy * 1000 / (Y₀ - dy) * 997) + 1
```     
    

---

# Solidity ^0.8.20 Modernization Note

Original Uniswap V2 uses:

```solidity
.mul()
.add()
.sub()
.div()
```

because it predates Solidity's built-in overflow checks.

For Solidity:

```solidity
pragma solidity ^0.8.20;
```

use:

```solidity
*
+
-
/
```

instead.

Examples:

```solidity
reserveIn * amountOut * 1000

(reserveOut - amountOut) * 997
```

instead of:

```solidity
reserveIn.mul(amountOut).mul(1000)

reserveOut.sub(amountOut).mul(997)
```

>Remark UniswapV2 was made using older solidity versions so they had to do all that safeMath and stuffs, We/I am good!
