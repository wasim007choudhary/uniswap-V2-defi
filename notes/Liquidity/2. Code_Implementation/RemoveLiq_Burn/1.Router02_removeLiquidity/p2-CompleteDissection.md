# Part I — Locating the Correct Pair

The first executable line is:

```solidity
address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
```

> **Complete Dissection**
>
> For a complete line-by-line walkthrough of `pairFor()` visit:- ***[ notes/Periphery/Library/Library/UV2Plibrary--PairForAndCreate2.md ]*** , here we will only just do a quick summary no indept of it.

## Summary

The Router's first responsibility is simply to determine **which Pair
contract corresponds to the supplied token pair**.

`pairFor()` performs a deterministic CREATE2 address calculation and
returns the expected Pair address.

Notice that this function **does not verify whether the Pair has been
deployed**.

This is intentional.

The next external call naturally verifies that the Pair exists.

If no contract has been deployed at the computed address, the call
fails and the transaction reverts automatically.

At this point, the Router knows **which Pair contract** should perform
the liquidity redemption.

---

# Part II — Moving LP Tokens Into the Pair

The next line is:

```solidity
IUniswapV2Pair(pair).transferFrom(
    msg.sender,
    pair,
    liquidity
);
```

Before LP tokens can be redeemed, the Pair contract must first own
them.

Think of LP tokens as ownership certificates.

The user first returns those ownership certificates to the Pair.

Only then can the Pair destroy them and return the corresponding
underlying assets.

```text
User

100 LP
        │
        ▼
Pair

100 LP
        │
        ▼
Pair.burn()
        │
        ▼
Destroy LP Tokens
        │
        ▼
Return Token0 & Token1
```

Notice something important.

The Router **does not burn** LP tokens.

It merely transfers them into the Pair contract.

The actual burning happens later inside:

```text
Pair.burn()
```

During normal operation, the Pair only holds those LP tokens for a very
short period:

```text
transferFrom()

↓

Pair temporarily owns LP Tokens

↓

burn()

↓

Pair LP Balance returns to 0
```

The LP token `totalSupply` is **not** affected by this transfer.

Ownership is merely moving from the user to the Pair.

`totalSupply` only decreases later when `Pair.burn()` internally calls
`_burn()`.

---

# Part III — Handing Control to the Pair

The next line is:

```solidity
(uint256 amount0, uint256 amount1) =
    IUniswapV2Pair(pair).burn(to);
```

> **Complete Dissection**
>
> For the complete walkthrough of `Pair.burn()`, including:
>
> - LP redemption mathematics
> - Ownership calculation
> - `_burn()`
> - `_safeTransfer()`
> - `_update()`
> - `kLast`
> - Reserve synchronization
>
> See:
>
> ```text
> notes/
> └── Core/
>     └── UV2Pair--burn.md
> ```

## Summary

At this point, the Router has completed its preparation work.

The Pair now:

- Reads the LP tokens it currently owns.
- Calculates the proportional share of the pool.
- Burns the LP tokens.
- Transfers the underlying assets.
- Updates its reserves.
- Returns the redeemed amounts.

The Router simply receives:

```solidity
amount0
amount1
```

representing the assets returned by the Pair.

---

# Part IV — Restoring the User's Token Order

The next lines are:

```solidity
(address token0,) =
    UniswapV2Library.sortTokens(tokenA, tokenB);

(amountA, amountB) =
    tokenA == token0
        ? (amount0, amount1)
        : (amount1, amount0);
```

> **Complete Dissection**
>
> For a complete walkthrough of `sortTokens()`, see natspecs of `sortTokens()` at: ***[ contracts/peripheryUV2/library/UV2Library.sol ]***, here we will only just do a quick summary no indept of it.


## Summary

Internally, every Pair always works using:

```text
token0
token1
```

and therefore returns:

```text
amount0
amount1
```

However, the Router's public API promises:

```text
amountA
amountB
```

If the user's requested token order differs from the Pair's internal
ordering, the Router simply swaps the returned values before returning
them.

Think of the Router as a translator:

```text
Pair

token0 / token1

↓

Router

tokenA / tokenB
```

This ensures the Router's output always matches the user's requested
token order.

---

---

# Part V — Slippage Protection

The final lines are:

```solidity
require(
    amountA >= amountAMin,
    "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
);

require(
    amountB >= amountBMin,
    "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
);
```

## Summary

After `Pair.burn()` completes, the Router knows exactly how many tokens
were redeemed.

Before allowing the transaction to finish, it verifies that the user
received at least the minimum acceptable amounts specified when calling
`removeLiquidity()`.

If either condition fails, the entire transaction reverts.

This protects liquidity providers from:

- Slippage
- Front-running
- Unexpected reserve changes between transaction submission and
  execution

These checks serve the same purpose as the minimum amount parameters
used throughout the Router's other liquidity functions.

---

# Complete Execution Flow

Ignoring the mathematical details inside `Pair.burn()`, the Router
performs the following workflow:

```text
User requests liquidity removal
        │
        ▼
Locate the Pair
        │
        ▼
Transfer LP Tokens
User ─────► Pair
        │
        ▼
Pair.burn()
        │
        ▼
Receive amount0 & amount1
        │
        ▼
Restore token order
(amount0/amount1 → amountA/amountB)
        │
        ▼
Verify slippage
        │
        ▼
Return redeemed assets
```

Notice that the Router itself performs **very little business logic**.

Its primary role is to coordinate the liquidity removal process.

The actual redemption—including LP ownership calculations, LP token
burning, reserve synchronization, protocol fee handling, and token
transfers—is performed entirely inside `Pair.burn()`.

---

# Key Takeaways

- The Router coordinates the removal process but does not perform the
  redemption itself.
- `pairFor()` locates the correct Pair contract.
- LP tokens are first transferred from the user to the Pair.
- `Pair.burn()` performs the actual redemption.
- The Router restores the token order expected by the user.
- Final slippage checks ensure the user receives at least their minimum
  acceptable amounts before the transaction succeeds.