# `Router.removeLiquidity()` — Overview & Execution Flow

> **Before studying this function, complete the prerequisite chapters below.**

>Read all these before coming here: ***notes/Liquidity/1. Conceptual_and_MathematicalFoundation*** and then ***notes/Liquidity/1. Conceptual_and_MathematicalFoundation/P5-BurnSharesFormulaMathematical.md*** or else ypu will feel lost ngl!
>
> This chapter intentionally **does not** re-derive LP ownership,
> liquidity mathematics, or the internal redemption logic. Those topics
> have already been covered in detail.
>
> Instead, this chapter focuses on **how the Router coordinates the
> liquidity removal process** before handing control over to
> `Pair.burn()`.

---

# Required Reading

```text
notes/
└── Liquidity/
    │
    ├── 1. Conceptual_and_MathematicalFoundation/
    │
    │   Read every chapter.
    │
    │   This section derives all of the mathematics behind LP
    │   ownership, proportional liquidity, LP minting, and LP
    │   redemption.
    │
    └── 2. Code_Implementation/
        │
        ├── AddLiq_Mint/
        │
        │   Read every chapter.
        │
        │   Understanding how liquidity is added makes the reverse
        │   redemption process much easier.
        │
        └── Pair.burn.md
            │
            └── Must read after this chapter.
```

### Additional References

- `notes/Core/UV2Pair--burn.md`
- `notes/UV2ERC20.md`

---

# The Function

```solidity
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
)
```

This function is responsible for **coordinating the entire liquidity
removal process**.

Unlike `Pair.burn()`, the Router performs very little computation.

Instead, it simply acts as the coordinator between the user and the Pair
contract.

Its responsibilities are to:

- Locate the correct Pair.
- Move LP tokens into the Pair.
- Ask the Pair to redeem those LP tokens.
- Verify the user received acceptable amounts.
- Return those redeemed amounts.

Notice what the Router **does not** do.

It never:

- Calculates ownership.
- Calculates redemption amounts.
- Burns LP tokens.
- Updates reserves.

Those responsibilities belong entirely to `Pair.burn()`.

---

# High-Level Flow

Ignoring the implementation details, the Router performs only five jobs.

```text
User wants to remove liquidity
        │
        ▼
Locate the correct Pair
        │
        ▼
Transfer LP Tokens
User ─────────► Pair
        │
        ▼
Tell Pair:
"Redeem these LP tokens."
        │
        ▼
Receive amount0 & amount1
        │
        ▼
Restore token order
        │
        ▼
Verify slippage
        │
        ▼
Done
```

Notice something interesting.

Almost all of the actual work happens inside:

```text
Pair.burn()
```

The Router simply orchestrates the process.

---

# Before Reading The Code

Think back to adding liquidity.

```text
User

↓

Router

↓

Transfer Token0

↓

Transfer Token1

↓

Pair.mint()

↓

Receive LP Tokens
```

Now we are doing the exact opposite.

Instead of depositing assets and receiving ownership, we are returning
ownership and receiving assets.

```text
LP Ownership

↓

Underlying Assets
```

The Router simply coordinates that redemption.

---

# Function Parameters

```solidity
removeLiquidity(
    tokenA,
    tokenB,
    liquidity,
    amountAMin,
    amountBMin,
    to,
    deadline
)
```

---

## tokenA

One of the two assets inside the liquidity pool.

Example:

```text
WETH
```

---

## tokenB

The second asset inside the liquidity pool.

Example:

```text
USDC
```

Together these identify **which liquidity pool** we are interacting with.

---

## liquidity

This is the number of **LP tokens** the user wishes to redeem.

Notice something important.

This does **not** mean:

> "Remove all my liquidity."

Instead it means:

> "Redeem this many LP tokens."

Example:

```text
Wallet

250 LP

↓

Pass

100 LP

↓

Only 100 LP are redeemed.
```

The remaining:

```text
150 LP
```

stay inside the user's wallet.

---

## amountAMin

The minimum acceptable amount of `tokenA` the user is willing to receive.

If the redemption would return less than this amount:

```text
Transaction Reverts
```

This protects against:

- Slippage
- Front-running
- Reserve changes

---

## amountBMin

Exactly the same idea as `amountAMin`.

It specifies the minimum acceptable amount of `tokenB`.

---

## to

This is **not necessarily** `msg.sender`.

Instead it represents:

> **The address that will receive the redeemed underlying assets.**

Example:

```text
Alice

↓

Owns LP Tokens

↓

Calls removeLiquidity()

↓

to = Bob

↓

Bob receives
ETH + USDC
```

Alice supplied the LP ownership.

Bob receives the underlying assets.

Therefore:

```text
msg.sender

↓

Pays LP Tokens

-------------------------

to

↓

Receives Token0 & Token1
```

The two addresses may be different.

---

## deadline

Already covered earlier.

Protects users from stale transactions.

If the deadline has already expired, the transaction reverts.

---

# Locating The Pair

The first executable line is:

```solidity
address pair =
    UniswapV2Library.pairFor(
        factory,
        tokenA,
        tokenB
    );
```

The Router first needs to determine:

> **"Which Pair contract owns the liquidity for these two tokens?"**

We already dissected `pairFor()` earlier.

It simply computes the deterministic Pair address using CREATE2.

Notice something interesting.

It does **not** check whether the Pair actually exists.
