# 0.1 Why Does The Factory Exist?

## First Thought

Before reading a single line of `UniswapV2Factory.sol`, the first question naturally came to mind.

> **Why does Uniswap even need a Factory contract?**

If a `UniswapV2Pair` manages a liquidity pool, why can't users simply deploy Pair contracts themselves?

Initially, this sounded completely reasonable.

---

## Discussion

Imagine the Factory contract never existed.

The only contract available is:

```text
UniswapV2Pair
```

Now suppose Alice wants to create an:

```text
ETH / USDC
```

pool.

### Question

Who deploys the Pair?

Possible answers could be:

```text
A) Alice

B) Uniswap Team

C) Anyone

D) Something Else
```

At first, we assumed Alice simply deploys the Pair herself.

---

## Next Scenario

A few minutes later...

Bob also wants an:

```text
ETH / USDC
```

pool.

Now two possibilities exist.

### Option A

Bob reuses Alice's Pair.

### Option B

Bob deploys another Pair.

At this point the immediate answer was:

> **Reuse. Better.**

---

## Question

Why is reusing better?

At first glance, both options seem perfectly valid.

So we started thinking about the consequences.

---

## Discovery #1 — User Confusion

Suppose multiple ETH / USDC pools exist.

```text
ETH / USDC Pair #1

ETH / USDC Pair #2

ETH / USDC Pair #3
```

Now every new user has to ask:

* Which one should I trade against?
* Which one should I provide liquidity to?
* Which one is the "official" pool?

There is no canonical liquidity pool anymore.

Immediately, unnecessary confusion is introduced into the protocol.

This was our first realization.

---

## Discovery #2 — Liquidity Fragmentation

Suppose instead of everyone using one pool, everyone creates their own.

Instead of:

```text
ETH / USDC

1000 ETH
```

we might have:

```text
Pool A

100 ETH

------------------

Pool B

250 ETH

------------------

Pool C

650 ETH
```

Liquidity is no longer shared.

Instead, it becomes fragmented across many pools.

---

## Discussion

At this point another question came up.

Suppose someone wants to buy:

```text
10 ETH
```

Which situation is better?

### Small Pool

```text
10 ETH
```

or

### Large Pool

```text
1000 ETH
```

The realization was immediate.

> **The bigger the pool, the smaller the price fluctuation caused by a single trade.**

Conversely,

> **The smaller the pool, the larger the price fluctuation.**

Exactly the same trade produces completely different price movement depending on the available liquidity.

---

## Child Analogy

Think about throwing the same rock.

### Small Pond

```text
💧

Huge Splash
```

### Ocean

```text
🌊

Tiny Ripple
```

The rock is identical.

Only the amount of water changes.

Liquidity behaves exactly the same way.

Large liquidity absorbs trades much better than small liquidity.

---

## Discovery #3 — Different Prices

Suppose two ETH / USDC pools now exist.

Pool A might currently price ETH at:

```text
2000 USDC
```

while Pool B might already be at:

```text
2350 USDC
```

Now users trading the exact same asset pair receive different prices depending on which pool they accidentally choose.

There is no single market anymore.

---

## Question

Suppose we have:

```text
100 Users
```

Would we rather have:

### Option A

```text
10 Pools

Each With

100 ETH
```

or

### Option B

```text
1 Pool

With

1000 ETH
```

The answer became obvious.

> **One large shared pool.**

It provides:

* deeper liquidity,
* smaller price fluctuations,
* lower slippage,
* and a much better user experience.

---

## Realization

At this point we realized something important.

The problem is **not** that users can deploy Pair contracts.

The problem is allowing everyone to deploy their **own version of the same Pair.**

There should only ever be:

```text
One

ETH / USDC

Pair
```

not hundreds of them.

---

## Solution

Instead of everyone deploying Pair contracts directly,

everyone asks a central contract.

Conceptually:

```text
User

↓

Factory

↓

Does Pair Already Exist?

├── Yes

│

│   Return Existing Pair

│

└── No

    ↓

    Create New Pair
```

The Factory becomes the protocol's registry.

---

## During Our Discussion

While thinking about duplicate pools, another idea came up.

The thought was:

> "First we make sure the pool gets deployed, and later if someone tries to deploy again we cancel them because they will have the same address."

This intuition is actually very close to the real implementation.

However, there is an important distinction.

---

## Registry vs CREATE2

Initially it seems like Uniswap could simply rely on CREATE2.

Since CREATE2 produces deterministic addresses,

deploying the same Pair twice would naturally fail.

That is true.

However,

the Factory doesn't wait for deployment to fail.

Instead,

it first checks its registry.

Conceptually:

```text
Does Pair Already Exist?

↓

Yes

↓

Revert Immediately
```

Only after passing this check does deployment continue.

Later we'll study this line:

```solidity
require(
    getPair[token0][token1] == address(0),
    "PAIR_EXISTS"
);
```

The registry is the first layer of protection.

CREATE2 provides an additional guarantee through deterministic deployment.

---

## CREATE2

During the discussion we also connected this with CREATE2.

Because CREATE2 computes deterministic deployment addresses,

the Pair's address can be known before deployment.

However,

this chapter only introduces that idea.

The complete deep dive—including:

* Why CREATE2 exists.
* CREATE vs CREATE2.
* Deterministic deployment.
* Address calculation.
* Salt.
* Bytecode.
* Assembly.
* EVM execution.
* Security.
* Mental models.

is covered separately in:

```text
notes/Periphery/Library/Library/UV2Plibrary--PairForAndCreate2.md
```

This chapter focuses only on why the Factory exists.

---

## Mental Model

Think of the Factory as the protocol's registry.

Whenever someone wants a liquidity pool,

they don't deploy a Pair directly.

Instead,

they ask the Factory.

```text
Need ETH / USDC

↓

Ask Factory

↓

Already Exists?

├── Yes

│

│   Reuse Existing Pair

│

└── No

    ↓

    Deploy Pair

    ↓

    Register Pair

    ↓

    Future Users Reuse It
```

---

## Final Realization

At the beginning,

allowing anyone to deploy Pair contracts sounded perfectly reasonable.

After thinking through the consequences,

we realized why that design would fail.

Without a Factory we would have:

* user confusion,
* fragmented liquidity,
* different prices,
* larger slippage,
* no canonical pool.

The Factory solves all of these problems by acting as the protocol's single source of truth.

Its job is not merely to deploy contracts.

Its job is to guarantee that every unique token combination maps to exactly one official Pair contract.
