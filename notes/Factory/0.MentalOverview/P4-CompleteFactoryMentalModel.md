# 0.4 Complete Factory Mental Model

## First Thought

At this point we had already answered three major questions.

* Why does the Factory exist?
* Why is the Factory a separate contract?
* How does the Factory interact with the Pair?

Now we wanted to zoom out and ask one final question before reading the Solidity code.

> **Can we mentally simulate the entire Factory lifecycle from start to finish?**

If we can understand the complete flow first,

then reading the implementation later becomes much easier.

---

## Imagine A Brand New Uniswap

Suppose Uniswap V2 has just been deployed.

There are:

```text
0 Pair Contracts
```

No liquidity.

No pools.

Nothing exists yet.

---

## Scenario

Alice wants to create the very first:

```text
ETH / USDC
```

pool.

At first glance,

it is tempting to think:

```text
Need Pool

↓

Deploy Pair
```

But after everything we learned in **0.1**,

we immediately realized that this is **not** the first step.

---

## Question

What is the Factory's very first question?

The answer became:

> **Does this Pair already exist?**

This was one of the biggest realizations.

The Factory never starts by deploying.

It first checks whether deployment is even necessary.

Conceptually:

```text
Need ETH / USDC

↓

Ask Factory

↓

Does Pair Already Exist?
```

---

## Two Possible Outcomes

Only two outcomes are possible.

### Case 1

The Pair already exists.

```text
Need ETH / USDC

↓

Factory

↓

Pair Exists

↓

Return Pair Address

↓

Done
```

No deployment.

No CREATE2.

No initialization.

The existing Pair is simply reused.

---

### Case 2

The Pair does not exist.

Only now does deployment begin.

Conceptually:

```text
Need ETH / USDC

↓

Factory

↓

Does Pair Exist?

↓

No

↓

Sort Tokens

↓

Generate Salt

↓

CREATE2

↓

Deploy Pair

↓

initialize()

↓

Store getPair

↓

Push Into allPairs

↓

Emit PairCreated

↓

Done
```

Notice how deployment happens only after every previous check succeeds.

---

## During Our Discussion

One realization became very obvious.

The Factory is involved for only a very small portion of the protocol's lifetime.

Something like:

```text
Need New Pool

↓

Factory

↓

Create Pair

↓

Done
```

After that,

its primary job is already complete.

---

## Then What?

Once the Pair exists,

users no longer keep interacting with the Factory.

Initially,

it might feel like this:

```text
User

↓

Factory

↓

Pair

↓

Factory

↓

Pair
```

But that is not how Uniswap operates.

---

## Actual Architecture

After deployment,

all normal protocol activity revolves around the Pair.

Users perform:

* swaps,
* liquidity additions,
* liquidity removals,
* reserve synchronization,
* oracle updates,

without the Factory participating.

Conceptually:

```text
Pair

↓

swap()

mint()

burn()

sync()

skim()
```

The Factory is no longer part of those operations.

---

## Router & Library

During our discussion we also remembered something important from our previous notes.

In production,

users usually do not interact directly with either the Factory or the Pair.

Instead,

the normal flow becomes:

```text
User

↓

Router

↓

Library

↓

pairFor()

↓

Pair.swap()
```

or

```text
User

↓

Router

↓

Factory.getPair()

↓

Pair.swap()
```

depending on how the Pair address is obtained.

The important architectural observation remains unchanged.

The Factory is **not** responsible for executing swaps.

Its responsibility ended once the Pair was created and registered.

The complete discussion about `pairFor()` and deterministic address calculation has already been covered in:

```text
notes/Periphery/Library/Library/UV2Plibrary--PairForAndCreate2.md
```

and is therefore not repeated here.

---

## Another Realization

Suppose Uniswap eventually contains:

```text
100,000 Pair Contracts
```

A brand new user now wants:

```text
SOL / USDC
```

The Factory asks only one question.

```text
Does This Pair Already Exist?
```

If:

```text
Yes
```

↓

Return the existing Pair.

If:

```text
No
```

↓

Create it.

That is the Factory's entire purpose.

Nothing more.

Nothing less.

---

## Child Analogy

Imagine a library.

You want a book.

The librarian does not immediately print a new copy.

The librarian first asks:

```text
Do We Already Have This Book?
```

If yes,

the existing copy is handed to you.

Only if the book does not exist would acquiring a new copy make sense.

The Factory behaves in exactly the same way.

It first checks whether the Pair already exists before creating anything.

---

## Complete Mental Model

```text
Need New Pool

↓

Factory

↓

Pair Exists?

├── Yes

│

│   Return Pair Address

│

└── No

    ↓

    Sort Tokens

    ↓

    CREATE2

    ↓

    Deploy Pair

    ↓

    initialize()

    ↓

    Store In Registry

    ↓

    Emit PairCreated

=================================

Pool Exists

↓

Router

↓

Library

↓

pairFor()

↓

Pair

↓

swap()

mint()

burn()

sync()

skim()
```

---

## Final Realization

Before reading the Factory contract,

it is important to understand that it is **not** the heart of Uniswap.

Its job is surprisingly small.

The Factory exists to answer one simple question.

> **Does this Pair already exist?**

If the answer is:

```text
Yes
```

↓

Return it.

If the answer is:

```text
No
```

↓

Create it.

Once the Pair has been deployed,

registered,

and initialized,

the Factory's primary responsibility is complete.

The Pair then lives independently for the rest of its lifetime,

handling every swap,

every liquidity event,

and every reserve update without depending on the Factory.

With this complete mental model in place,

we are now ready to open `UniswapV2Factory.sol` and study its implementation line by line.
