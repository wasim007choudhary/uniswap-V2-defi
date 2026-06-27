# 0.1 Why Does The Factory Exist?

## First Thought

Before reading a single line of `UniswapV2Factory.sol`, the first question naturally arises:

> **Why does Uniswap even need a Factory contract?**

After all, if a `UniswapV2Pair` contract manages a liquidity pool, why can't users simply deploy Pair contracts themselves?

Initially, this feels like a perfectly reasonable idea.

Suppose Alice wants to create an:

```text
ETH / USDC
```

liquidity pool.

Why can't Alice simply deploy a new `UniswapV2Pair` contract?

---

## Discussion

Imagine the Factory contract does not exist.

Alice deploys:

```text
ETH / USDC Pair
```

A few minutes later,

Bob also wants an:

```text
ETH / USDC
```

pool.

At first, two possibilities seem possible.

### Option A

Bob reuses Alice's Pair.

### Option B

Bob deploys another `ETH / USDC` Pair.

Initially, it might seem that both options are acceptable.

However, after thinking about it, we realized that **reusing the existing Pair is the only sensible choice.**

---

## Question

Why is reusing the existing Pair better?

---

## Discovery #1 — User Confusion

Suppose multiple `ETH / USDC` Pairs exist.

```text
ETH / USDC Pair #1

ETH / USDC Pair #2

ETH / USDC Pair #3
```

A new user now faces several questions.

* Which pool should I trade against?
* Which one is the official pool?
* Which one should I provide liquidity to?
* Which one has the deepest liquidity?

There is no longer a single canonical liquidity pool.

This creates unnecessary confusion for every user interacting with the protocol.

---

## Discovery #2 — Liquidity Fragmentation

Instead of having one large liquidity pool,

the liquidity becomes spread across many smaller pools.

Instead of:

```text
ETH / USDC

1000 ETH
2,000,000 USDC
```

we might have:

```text
Pool A

100 ETH

----------------

Pool B

250 ETH

----------------

Pool C

650 ETH
```

The liquidity is fragmented.

Rather than everyone sharing one deep pool,

users are divided across multiple shallow pools.

---

## Discovery #3 — Larger Price Fluctuations

One of the biggest realizations during our discussion was:

> **The larger the liquidity pool, the smaller the price fluctuation caused by a single trade.**

Conversely,

the smaller the pool,

the larger the price movement.

Suppose someone buys:

```text
10 ETH
```

from a pool containing only:

```text
10 ETH
```

The trade dramatically changes the reserves,

causing significant slippage and price movement.

Now compare that to a pool containing:

```text
1000 ETH
```

The exact same trade barely affects the reserves,

resulting in much smaller price movement.

A deep liquidity pool creates a much more stable market.

---

## Discovery #4 — Different Prices

If multiple pools exist,

they can each have different reserve ratios.

For example:

```text
Pool A

Price

=

2000 USDC / ETH
```

while another pool may have:

```text
Pool B

Price

=

2350 USDC / ETH
```

Now there is no single market price.

Different users may receive completely different prices depending on which pool they interact with.

---

## Realization

At this point, we realized that allowing everyone to deploy Pair contracts freely would create several major problems.

* User confusion.
* Liquidity fragmentation.
* Higher slippage.
* Larger price fluctuations.
* Multiple competing prices for the same token pair.

Clearly, there should only be **one official Pair contract** for every unique token combination.

---

## Solution

Instead of allowing users to deploy Pair contracts directly,

everyone asks a central contract.

```text
User

↓

Factory

↓

Does Pair Already Exist?

├── Yes

│     ↓

│     Return Existing Pair

│

└── No

      ↓

      Deploy New Pair
```

The Factory becomes the single source of truth for every liquidity pool in the protocol.

---

## During Our Discussion

While thinking about duplicate pools, an interesting idea came up.

> "First we make sure the pool gets deployed, and later if someone tries to deploy again we cancel them because they will have the same address."

This intuition is actually very close to how Uniswap works.

However, an important distinction exists.

The Factory does **not** primarily rely on deployment failure to detect duplicates.

Instead, before deploying anything, it first checks its internal registry.

Conceptually:

```text
Does Pair Already Exist?

↓

Yes

↓

Revert Immediately
```

Only if no Pair exists does deployment continue.

Later, when we study `createPair()`, we will see this implemented using:

```solidity
require(
    getPair[token0][token1] == address(0),
    "PAIR_EXISTS"
);
```

---

## CREATE2

During our discussion, we also connected this idea with `CREATE2`.

Because Uniswap uses `CREATE2`, the Pair contract's deployment address can be computed **before** the contract is deployed.

This provides deterministic deployment addresses.

However,

the Factory still performs an explicit registry check before attempting deployment.

So conceptually, there are two layers of protection.

```text
Layer 1

Registry (getPair)

↓

Prevent Duplicate Request

----------------------------

Layer 2

CREATE2

↓

Deterministic Address

↓

Deployment Cannot Occupy The Same Address Twice
```

This chapter only introduces that idea.

A complete first-principles explanation of `CREATE2`, deterministic deployment, address computation, salts, bytecode, and the EVM internals is covered separately in:

```text
notes/Periphery/Library/Library/UV2Plibrary--PairForAndCreate2.md
```

---

## Mental Model

Think of the Factory as a central registry.

Instead of everyone independently creating their own liquidity pool,

everyone asks the Factory.

```text
Need ETH / USDC Pool

↓

Ask Factory

↓

Already Exists?

├── Yes

│     ↓

│     Use Existing Pair

│

└── No

      ↓

      Create Pair

      ↓

      Register Pair

      ↓

      Future Users Reuse It
```

---

## Final Realization

At the beginning, it seemed reasonable to let anyone deploy Pair contracts.

After thinking through the consequences, we discovered why that would be a poor design.

The Factory exists to guarantee:

* Exactly one Pair contract per unique token combination.
* A single canonical liquidity pool.
* Deep, shared liquidity.
* Better price stability.
* Lower slippage.
* Easier discovery of existing pools.

In other words,

the Factory is not merely a deployment contract.

It is the protocol's registry and the single source of truth for all Pair contracts.

```
```
