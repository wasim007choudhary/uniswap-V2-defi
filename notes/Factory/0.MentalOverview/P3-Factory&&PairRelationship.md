# 0.3 Factory ↔ Pair Relationship

## First Thought

Now that we understand:

* Why the Factory exists.
* Why the Factory is a separate contract.

another question naturally came up.

> **How do the Factory and Pair actually interact?**

At first, it is easy to imagine something like this:

```text
Factory

⇄

Pair
```

Almost like the Factory constantly manages every Pair after deployment.

---

## Question

Suppose the Factory has already created:

```text
ETH / USDC Pair
```

Now Alice wants to perform a swap.

Who does Alice interact with?

Does she call:

```text
Factory

↓

Pair
```

or

```text
Pair
```

directly?

---

## Initial Realization

The immediate answer was:

> **The Pair.**

Once the Pair is deployed,

the Factory's primary responsibility is already complete.

Conceptually:

```text
Factory

↓

Deploy Pair

↓

Initialize Pair

↓

Store Pair Address

↓

Factory's Main Job Is Done
```

After that,

all pool-related operations happen inside the Pair itself.

---

## Discussion

Suppose Alice now wants to:

```text
Swap

↓

Add Liquidity

↓

Remove Liquidity
```

Does the Factory participate?

Does it receive a callback?

Does it update reserves?

Does it verify swaps?

The answer is:

**No.**

The Pair manages all of those operations independently.

---

## Bigger Picture

Initially, it feels like the Factory is involved in every operation.

Something like:

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

But this is not how Uniswap works.

Instead:

```text
Need New Pool

↓

Factory

↓

Deploy Pair

↓

Register Pair

========================

Pool Already Exists

↓

Interact With Pair
```

The Factory is **not** sitting in the middle of every transaction.

---

## During Our Discussion

At this point an important observation came up.

The real Uniswap flow is actually even cleaner.

Instead of users manually calling either the Factory or the Pair,

they usually interact with the **Router**.

The Router then determines the correct Pair.

Initially this was described as:

```text
Router

↓

Factory

↓

Find Pair

↓

Pair
```

However,

we remembered something important from our previous notes.

---

## pairFor()

During our Uniswap Library discussion,

we already studied:

```text
pairFor()
```

Instead of always asking the Factory,

the Router can deterministically compute the Pair address.

Conceptually:

```text
User

↓

Router

↓

Library

↓

pairFor()

↓

Calculate Pair Address

↓

Pair.swap()
```

This works because the Pair was deployed using **CREATE2**.

The address can therefore be calculated without performing an on-chain lookup.

This topic has already been covered in crazy detail inside:


>**[ notes/Periphery/Library/Library/UV2Plibrary--PairForAndCreate2.md ]**


so it is not repeated here.

---

## Important Clarification

For learning purposes,

throughout these notes we sometimes simplify the interaction as:

```text
User

↓

Pair
```

This allows us to focus only on the relationship between the Factory and the Pair.

In production,

the interaction is normally:

```text
User

↓

Router

↓

Library

↓

Pair
```

The architectural conclusion remains exactly the same.

The Factory is **not** responsible for swaps once the Pair exists.

---

## Another Realization

Suppose Uniswap has:

```text
50,000 Pair Contracts
```

Every day,

millions of swaps occur.

If every swap had to pass through the Factory,

the Factory would become an unnecessary bottleneck.

Instead,

each Pair becomes completely independent after creation.

Every Pair manages only its own liquidity pool.

---

## Child Analogy

Think of a parent and a child.

```text
Parent

↓

Child Is Born

↓

Registers Birth

↓

Child Grows Up

↓

Lives Independently
```

The parent does not approve every decision the child makes afterwards.

The Factory behaves similarly.

```text
Factory

↓

Creates Pair

↓

Registers Pair

↓

Pair Lives Independently
```

The Pair no longer depends on the Factory for its day-to-day operations.

---

## Mental Model

```text
Pool Does Not Exist

↓

Factory

↓

Deploy Pair

↓

Initialize Pair

↓

Store Pair Address

=============================

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

Notice how the Factory appears only once.

Everything afterwards revolves around the Pair.

---

## Final Realization

Initially,

it seemed like the Factory and Pair continuously communicated.

After thinking through the architecture,

we realized that this is not the case.

The Factory's responsibility is to:

* Create Pair contracts.
* Initialize them.
* Register them.
* Keep track of them.

Once those responsibilities are complete,

its job is essentially finished.

Everyday protocol operations—

* swaps,
* liquidity additions,
* liquidity removals,
* oracle updates,
* reserve synchronization,

are all handled entirely by the Pair (typically reached through the Router and Library).

The Factory is a deployment and registry contract.

The Pair is the state machine that manages one liquidity pool throughout its lifetime.
