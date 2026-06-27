# 0.2 Why Is The Factory A Separate Contract?

## First Thought

Now that we know **why the Factory exists**, another question naturally came up.

> **Why is the Factory a completely separate contract?**

Why didn't Hayden Adams simply put everything inside `UniswapV2Pair`?

Something like:

```solidity
contract UniswapV2Pair {

    function createPair(...) external {}

    function swap(...) external {}

    function mint(...) external {}

    function burn(...) external {}
}
```

At first glance, this actually looked simpler.

One contract.

Everything together.

---

## Question

Suppose we choose this design.

Alice deploys the first Pair.

```text
ETH / USDC
```

Everything works.

Now Bob wants:

```text
WBTC / ETH
```

### Question

Who creates this new Pair?

Since there is no Factory,

the existing Pair must do it.

Conceptually:

```text
ETH / USDC Pair

↓

createPair()

↓

Deploy

↓

WBTC / ETH Pair
```

Initially, this seemed perfectly possible.

---

## Discussion

The immediate realization was:

> Technically, this works.

Every contract can execute `CREATE` or `CREATE2`.

There is nothing in the EVM preventing a Pair from deploying another Pair.

So we could have:

```text
Pair A

↓

Deploy Pair B

↓

Deploy Pair C

↓

Deploy Pair D
```

The EVM has absolutely no issue with this architecture.

---

## Question

If this works,

why didn't Uniswap build it this way?

---

## First Realization

One immediate issue became obvious.

Suppose later someone wants to create:

```text
LINK / ETH
```

Which Pair should they call?

```text
ETH / USDC Pair ?
```

or

```text
WBTC / ETH Pair ?
```

or

```text
LINK / DAI Pair ?
```

or literally **any Pair contract**?

All of them would contain:

```text
createPair()
```

So...

which one is the correct one?

There is no obvious answer.

---

## During Our Discussion

One realization came naturally.

> "It will be messy, but it will work."

Exactly.

Technically,

the architecture works.

Architecturally,

it becomes messy.

---

## Imagine The Future

Suppose Uniswap has:

```text
50,000 Pair Contracts
```

Every Pair now contains:

```text
swap()

mint()

burn()

sync()

skim()

oracle()

flashSwap()

+

createPair()

registry logic

duplicate checks
```

Now every liquidity pool carries code whose primary purpose is creating completely unrelated liquidity pools.

---

## Question

Does an ETH / USDC Pair ever actually need to create another Pair after deployment?

Think about its entire lifetime.

Users will only:

* swap,
* add liquidity,
* remove liquidity,
* trigger oracle updates.

Its job is simply:

```text
Manage

ONE

Liquidity Pool
```

Nothing more.

---

## Software Engineering Perspective

At this point we stopped thinking like Solidity developers

and started thinking like software engineers.

A Pair contract has one responsibility.

```text
Manage One Pool
```

A Factory has another responsibility.

```text
Create

↓

Track

↓

Register

Pairs
```

Both contracts have completely different jobs.

---

## Single Responsibility Principle (SRP)

This discussion naturally led us to one of the most important software engineering principles.

> **Single Responsibility Principle**

Every component should have one clear responsibility.

Instead of:

```text
Pair

↓

Swap

Mint

Burn

Oracle

Factory

Registry

Deployment
```

Uniswap separates concerns.

```text
Factory

↓

Creates & Tracks Pairs

----------------------------

Pair

↓

Manages One Liquidity Pool
```

The responsibilities become obvious.

---

## Another Question

A question naturally came up.

If Pair contracts created new Pair contracts,

would gas consumption be different?

The answer surprised us.

### Deployment Gas

Almost identical.

The deployment still happens through:

```text
CREATE2
```

The EVM does not care whether the caller is:

* Factory
* Pair
* Router
* Any other contract

Deployment gas remains essentially the same.

---

## Biggest Realization

The Factory is **not** separated for gas optimization.

It is separated because of architecture.

This was one of the biggest lessons from this discussion.

Initially it felt like:

```text
Factory

↓

Gas Optimization
```

After thinking more deeply we realized:

```text
Factory

↓

Clean Architecture

↓

Single Responsibility

↓

Single Authority

↓

Maintainability

↓

Cleaner API

↓

Easier Reasoning
```

Gas was never the motivation.

Software design was.

---

## Child Analogy

Imagine a restaurant.

### Good Design

```text
Reception

↓

Seats Customers

-------------------

Chef

↓

Cooks Food
```

Each person has one responsibility.

Now imagine:

```text
Chef

↓

Cook Food

↓

Seat Customers

↓

Answer Phone

↓

Take Payments

↓

Hire Employees

↓

Order Ingredients
```

Can the chef do all of these?

Yes.

Should the chef?

Absolutely not.

The exact same idea applies here.

The Pair *can* create other Pair contracts.

It simply **shouldn't**.

---

## Mental Model

```text
Need New Pair

↓

Factory

↓

Deploy Pair

----------------------

Need Swap

↓

Pair

↓

Execute Swap

----------------------

Need Mint

↓

Pair

↓

Mint LP Tokens

----------------------

Need Burn

↓

Pair

↓

Burn LP Tokens
```

Everyone immediately knows where to go.

---

## Final Realization

The question was never:

> **Can a Pair deploy another Pair?**

The answer is:

> **Yes.**

The real question is:

> **Should it?**

The answer is:

> **No.**

Not because of EVM limitations.

Not because of gas.

But because it violates one of the fundamental principles of good software architecture.

Uniswap deliberately separates responsibilities.

The Factory has exactly one job:

```text
Create

Track

Register

Pairs
```

Every Pair has exactly one job:

```text
Manage

One

Liquidity Pool
```

This clean separation makes the protocol easier to understand, easier to maintain, easier to reason about, and gives the entire system a single authority responsible for Pair creation.
