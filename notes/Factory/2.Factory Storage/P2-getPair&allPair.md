# 2.2-getPair & 2.3-allPairs 
>First we will dissect getPair mapping then we will dissect the array allPairs to its bone, nw I got you!
# 2.2 getPair 

```solidity
mapping(address => mapping(address => address)) public getPair;
```

## Mental Model Before Reading

The Factory may eventually deploy thousands or even millions of Pair contracts.

A natural question arises:

> **Given two token addresses, how can we instantly find the correct Pair contract?**

This is exactly the problem `getPair` solves.

---

## First Thought

At first glance this declaration looks intimidating.

```solidity
mapping(address => mapping(address => address))
```

A mapping...

inside another mapping...

storing another address.

However, once we understand the problem Uniswap is solving, this data structure becomes surprisingly simple.

---

## First Question

Imagine the Factory has already deployed one million Pair contracts.

Now Alice asks:

> "Where is the Pair contract for WETH and USDC?"

How should the Factory answer that question?

---

## Why Not Use An Array?

One possible design would be:

```solidity
address[] public allPairs;
```

and simply search through every Pair until the correct one is found.

For example:

```text
Pair 1 ?

↓

No

----------------------

Pair 2 ?

↓

No

----------------------

Pair 3 ?

↓

No

----------------------

...

----------------------

Pair 582931 ?

↓

Yes
```

This requires checking Pair after Pair until the correct one is found.

The lookup becomes:

```text
O(n)
```

As the protocol grows, searching becomes increasingly expensive.

Uniswap wanted immediate lookups instead.

---

## Why A Mapping?

Mappings are optimized for lookups.

Instead of searching through every Pair, we directly ask:

```text
Token A

+

Token B

↓

Pair Address
```

This provides approximately constant-time lookup.

```text
O(1)
```

---

## Why A Nested Mapping?

The declaration is:

```solidity
mapping(address => mapping(address => address))
```

Read it one step at a time.

The outer mapping says:

```text
Token A

↓

Another Mapping
```

Notice it does **not** immediately return a Pair address.

Instead, it returns another mapping.

That inner mapping says:

```text
Token B

↓

Pair Address
```

Putting them together:

```text
Token A

↓

Inner Mapping

↓

Token B

↓

Pair Address
```

Two lookups.

One final result.

---

## Visualizing The Nested Mapping

Imagine the first mapping creates shelves.

```text
WETH Shelf

↓

Inner Mapping

------------------------

WBTC Shelf

↓

Inner Mapping

------------------------

LINK Shelf

↓

Inner Mapping
```

Opening the WETH shelf reveals:

```text
USDC

↓

0xAAA...

------------------------

DAI

↓

0xBBB...

------------------------

LINK

↓

0xCCC...
```

So finding the Pair becomes:

```text
Go To WETH Shelf

↓

Find USDC

↓

Return Pair Address
```

---

## Child Analogy

Think of a library.

Instead of throwing every book into one giant pile:

```text
📚📚📚📚📚
```

The librarian first organizes books by bookshelf.

```text
Shelf: WETH

↓

USDC Book

↓

DAI Book

↓

LINK Book
```

When someone asks for:

```text
WETH / USDC
```

The librarian immediately walks to the WETH shelf,

then grabs the USDC book.

No searching through the entire library.

---

## Why Store Both Directions?

Suppose Alice creates:

```text
WETH / USDC
```

The Pair contract is deployed at:

```text
0xAAA...
```

Now Bob later searches:

```text
USDC / WETH
```

Should the Factory return:

```text
No Pair Exists
```

Of course not.

Both represent the exact same liquidity pool.

Therefore Uniswap stores:

```solidity
getPair[token0][token1] = pair;
getPair[token1][token0] = pair;
```

Notice something important.

The Pair contract is **not** deployed twice.

Only the mapping entry is stored twice.

Conceptually:

```text
(WETH, USDC)

↓

0xAAA...

------------------------

(USDC, WETH)

↓

0xAAA...
```

Two different lookup keys.

One Pair contract.

---

## Two Keys To One Door

A useful mental model from our discussion was:

```text
(WETH, USDC)

↓

🔑

↓

🚪

↓

0xAAA...

------------------------

(USDC, WETH)

↓

🔑

↓

🚪

↓

0xAAA...
```

Two different keys.

One door.

Both unlock the exact same Pair contract.

---

## Two Shelves, Same Pair

Using the shelf analogy,

the same Pair appears on two shelves.

```text
WETH Shelf

↓

USDC

↓

0xAAA...

------------------------

USDC Shelf

↓

WETH

↓

0xAAA...
```

The Pair contract itself is **not duplicated**.

Only its address is referenced from two different locations.

Think of it like two shortcuts pointing to the same file.

---

## Why Spend Extra Gas?

Storing both directions requires:

```solidity
getPair[token0][token1] = pair;
getPair[token1][token0] = pair;
```

which means an additional storage write during Pair creation.

So why spend the extra gas?

Because Pair creation happens only once.

Pair lookups happen millions of times.

Uniswap intentionally spends a little more gas during deployment to make future lookups easier and improve developer experience.

---

## Does This Eliminate Sorting?

No.

This is an important realization.

The protocol still sorts tokens during Pair creation.

Sorting is required for:

* deterministic CREATE2 deployment,
* canonical Pair identity,
* reserve ordering,
* consistent protocol behavior.

The reverse mapping exists almost entirely for **lookup convenience**.

It allows developers to query:

```solidity
getPair[tokenA][tokenB]
```

without worrying about token order.

---

## Public Getter

Because the mapping is declared:

```solidity
public
```

Solidity automatically generates a getter function similar to:

```solidity
function getPair(address tokenA, address tokenB)
    external
    view
    returns (address);
```

Users never access the mapping directly.

Instead, they call this automatically generated getter.

---

## Final Realization

`getPair` is a registry optimized for fast lookups.

Given two token addresses, it immediately returns the corresponding Pair contract.

By storing both token orders, Uniswap provides a much friendlier API while still maintaining a single canonical Pair internally.

---

# 2.3 allPairs

```solidity
address[] public allPairs;
```

## First Thought

At first glance this variable seems unnecessary.

We already have:

```solidity
getPair
```

Doesn't that already store every Pair?

Why do we also need an array?

---

## First Question

Suppose someone asks:

> "How many Pair contracts currently exist?"

Can `getPair` answer that?

The answer is:

**No.**

---

## Why?

Mappings only know one thing.

```text
Give me a key

↓

I'll give you a value.
```

Nothing more.

Mappings do **not** know:

* how many entries they contain,
* every key that exists,
* insertion order,
* or how to iterate through all entries.

If you ask a mapping:

> "Show me every Pair."

it has no answer.

---

## Hash Table Mental Model

Internally, mappings behave like hash tables.

Conceptually:

```text
Hash(Key)

↓

Storage Slot

↓

Value
```

There is no master list of every key.

There is no length counter.

There is no iteration mechanism.

---

## Why An Array?

Arrays solve the exact problem mappings cannot.

Whenever a new Pair is created:

```solidity
allPairs.push(pair);
```

The array becomes:

```text
0

↓

0xAAA...

------------------------

1

↓

0xBBB...

------------------------

2

↓

0xCCC...
```

Now we can answer questions like:

> How many Pairs exist?

```solidity
allPairs.length
```

> Give me Pair #250.

```solidity
allPairs[250]
```

> Iterate through every Pair.

Simply loop over the array.

---

## One Entry Per Pair

Unlike `getPair`,

the array stores every Pair exactly once.

```text
0

↓

0xAAA...

------------------------

1

↓

0xBBB...

------------------------

2

↓

0xCCC...
```

There is no duplicate entry for reversed token order.

Why?

Because arrays are not optimized for reverse lookups.

Their job is simply to maintain a complete list of every Pair ever created.

---

## Mapping vs Array

These two data structures solve completely different problems.

### getPair

Optimized for:

```text
Token A

+

Token B

↓

Pair Address
```

Fast lookup.

---

### allPairs

Optimized for:

```text
Show Every Pair

↓

Count Them

↓

Iterate Through Them
```

Enumeration.

Neither replaces the other.

Together they provide both capabilities.

---

## Quick Comparison

| Question                    | Data Structure |
| --------------------------- | -------------- |
| Does this Pair exist?       | `getPair`      |
| Give me the Pair address.   | `getPair`      |
| How many Pairs exist?       | `allPairs`     |
| Iterate through every Pair. | `allPairs`     |
| Give me Pair #N.            | `allPairs`     |

---

## Final Realization

The Factory intentionally stores the same information in two different data structures because each is optimized for a different operation.

`getPair` is optimized for fast lookups.

`allPairs` is optimized for enumeration.

Together they allow the Factory to answer both:

> "Where is this specific Pair?"

and

> "Show me every Pair ever created."
