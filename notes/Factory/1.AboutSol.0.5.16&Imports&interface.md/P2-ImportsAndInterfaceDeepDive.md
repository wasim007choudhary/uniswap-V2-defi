# 1.2 Imports

```solidity
import "./interfaces/IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";
```

## First Thought

At first glance these two imports look completely ordinary.

```solidity
import "./interfaces/IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";
```

Most people simply read them and continue to the contract.

However, during our discussion we realized that these two imports exist for **completely different reasons**.

One imports the **implementation**.

The other imports only the **interface**.

Although they appear side by side, they solve completely different problems.

---

# Import 1

```solidity
import "./UniswapV2Pair.sol";
```

## First Thought

Initially the question was:

> Why import the entire Pair contract?

Why not simply import:

```solidity
IUniswapV2Pair
```

instead?

---

## Discussion

The Factory never performs:

```solidity
pair.swap(...);

pair.mint(...);

pair.burn(...);
```

So it clearly isn't importing the Pair to call its normal functions.

That immediately raised another question.

Why does the Factory actually need the implementation?

---

## Discovery

Later inside `createPair()` we encounter:

```solidity
bytes memory bytecode =
    type(UniswapV2Pair).creationCode;
```

This answered the question.

The Factory imports the Pair because it needs access to its **creation bytecode**.

Not an instance.

Not an address.

The deployment blueprint.

---

## Child Analogy

Imagine a car factory.

The factory does not import:

```text
Car #1

Car #2

Car #3
```

Instead it keeps:

```text
Blueprint
```

Whenever a customer orders a new car:

```text
Blueprint

↓

Build New Car
```

The same thing happens here.

```text
UniswapV2Pair.sol

↓

Blueprint

↓

Factory

↓

CREATE2

↓

Deploy New Pair
```

Every Pair deployed by the Factory comes from this single blueprint.

---

## Another Realization

This also explains why every Pair behaves identically.

```text
ETH / USDC Pair

↓

Same Bytecode

-------------------

WBTC / ETH Pair

↓

Same Bytecode

-------------------

LINK / DAI Pair

↓

Same Bytecode
```

The deployed code is identical.

Only the initialization changes.

Later:

```solidity
initialize(token0, token1);
```

turns the generic blueprint into a specific liquidity pool.

---

## CREATE2

The imported Pair contract also contributes its creation bytecode to CREATE2.

CREATE2 uses multiple inputs to compute the deployment address, including:

* Factory address
* Salt
* Pair creation bytecode

A complete first-principles explanation of CREATE2, deterministic deployment, salts, address calculation, assembly, and the EVM internals has already been covered in:

```text
notes/Periphery/Library/Library/UV2Plibrary--PairForAndCreate2.md
```

so it is not repeated here.

---

# Import 2

```solidity
import "./interfaces/IUniswapV2Factory.sol";
```

## First Thought

Initially this import looked unnecessary.

The contract already defines:

```solidity
contract UniswapV2Factory
```

Why also import:

```solidity
IUniswapV2Factory
```

?

Couldn't we simply remove it?

Surprisingly...

Yes.

The contract would still compile if we removed both the interface and:

```solidity
is IUniswapV2Factory
```

provided all functions were still written correctly.

That raised a much deeper question.

---

## Question

If everything still works,

why do interfaces exist at all?

---

## First Assumption

Initially we wondered whether interfaces existed for gas optimization.

The answer is:

**No.**

Interfaces do not reduce runtime gas.

Whether another contract imports:

```solidity
IUniswapV2Factory
```

or

```solidity
UniswapV2Factory
```

the external call costs essentially the same gas.

The purpose of interfaces is not gas optimization.

---

## During Our Discussion

A much better question appeared.

> Why do I need an interface when I already have the contract?

The answer became clear after thinking about who actually consumes the Factory.

The Factory itself does not need its own interface.

Other contracts do.

For example:

* Router
* Other protocols
* Integrators
* Your own contracts

They only care about a few public functions.

```text
createPair()

getPair()

feeTo()

allPairsLength()
```

They do **not** care:

* how the Factory stores mappings,
* how CREATE2 works,
* how deployment happens,
* how internal helper functions are written,
* or any of its internal implementation.

---

## Why Not Simply Import The Contract?

This naturally led to another question.

If we already have:

```solidity
UniswapV2Factory.sol
```

why not simply import it everywhere?

The answer is:

We absolutely can.

Nothing in Solidity prevents another contract from importing the implementation directly.

However,

that contract now depends on the Factory's entire implementation.

It now sees:

* storage,
* internal functions,
* deployment details,
* helper functions,
* imported dependencies,
* implementation decisions.

Almost all of that information is unnecessary.

A Router, for example, only wants to know:

```text
Can I call:

createPair() ?

getPair() ?

feeTo() ?

allPairsLength() ?
```

Nothing more.

This is exactly why interfaces exist.

They expose only the public API while hiding every implementation detail.

---

## WHAT vs HOW

This led to one of the biggest realizations.

An interface describes:

```text
WHAT
```

a contract can do.

The implementation describes:

```text
HOW
```

it does it.

Example:

```text
Interface

↓

createPair()

getPair()

feeTo()

----------------------

Implementation

↓

Mappings

↓

CREATE2

↓

Assembly

↓

Internal Logic
```

Consumers only need the "WHAT".

They do not need the "HOW".

---

## Import vs `is`

Another important question naturally appeared.

If importing the interface is enough,

then why do we also write:

```solidity
contract UniswapV2Factory
    is IUniswapV2Factory
```

?

The import itself does almost nothing.

It simply makes the interface available to the compiler.

The important part is:

```solidity
is IUniswapV2Factory
```

By writing this,

the contract promises:

> "I implement every function described by this interface."

The compiler then verifies that promise.

If any required function is missing,

or has the wrong signature,

compilation fails.

---

## Does A Contract Need To Inherit The Interface?

Another question followed.

Suppose we remove:

```solidity
is IUniswapV2Factory
```

but still manually implement every required function.

Will the contract still work?

The answer is:

**Yes.**

The EVM does not require interface inheritance.

The contract will still deploy and function correctly.

The inheritance exists for the compiler,

not for the blockchain.

Without:

```solidity
is IUniswapV2Factory
```

the compiler simply assumes you are creating your own API.

With it,

the compiler verifies that you correctly implemented the agreed interface.

---

## Can Multiple Contracts Implement The Same Interface?

During our discussion another question appeared.

Suppose three different contracts all implement:

```solidity
IUniswapV2Factory
```

Will they clash?

The answer is:

**No.**

Example:

```text
Factory A

0xAAA...

-------------------

Factory B

0xBBB...

-------------------

Factory C

0xCCC...
```

Each deployed contract has its own address.

The interface never chooses between them.

The address does.

---

## How Does The Interface Know Which Contract?

This became one of the biggest conceptual questions.

Initially it felt like the interface somehow searched the blockchain looking for the correct implementation.

It does not.

When we write:

```solidity
IFactory(factoryAddress)
```

the compiler simply uses **our local interface file**.

It tells the compiler:

> "Assume the contract at this address exposes these functions."

The compiler then generates the correct function selector.

At runtime,

the EVM only receives:

```text
Contract Address

+

Function Selector

+

Calldata
```

The interface itself never reaches the blockchain.

The address completely determines which deployed contract receives the call.

---

## Do Interfaces Get Deployed?

One of the biggest questions during our discussion was:

> Do interfaces themselves get deployed?

The answer is:

**No.**

Interfaces exist only during compilation.

They help with:

* type checking,
* compiler verification,
* ABI generation,
* developer tooling,
* function selector generation.

Once compilation finishes,

they disappear.

Only the implementation contract's runtime bytecode is deployed onto the blockchain.

---

## Compile Time vs Runtime

One of the biggest mental models from this discussion was separating Solidity from the EVM.

### Compile Time

```text
Interfaces Exist

↓

Compiler Verifies

↓

Compiler Generates ABI

↓

Compiler Generates Function Selectors
```

### Runtime

```text
Interfaces Disappear

↓

Contract Address

↓

Function Selector

↓

Execution
```

The EVM never asks:

```text
Does this contract inherit the interface?
```

Instead,

it simply executes the function matching the selector at the supplied address.

---

## Biggest Mental Model

One sentence summarized our entire discussion.

> **Interfaces teach the compiler. Addresses tell the EVM where to execute. Function selectors tell the EVM what to execute.**

Everything before deployment belongs to Solidity.

Everything after deployment belongs to the EVM.

---

## Child Analogy

Think of an interface as a TV remote.

The remote exposes only:

```text
Power

Volume

Channel
```

It hides:

* motherboard,
* processor,
* wiring,
* display electronics.

Similarly,

the interface exposes only the public API.

The implementation hides all internal details.

---

## Final Realization

Although both imports appear side by side,

they serve completely different purposes.

`UniswapV2Pair.sol` is imported because the Factory needs the Pair's **creation bytecode** to deploy new liquidity pools using CREATE2.

`IUniswapV2Factory.sol` is imported because interfaces define the public API that other contracts rely on, separating **what** the Factory does from **how** it does it.

The interface is never deployed.

It never chooses which contract to call.

It never exists at runtime.

It teaches the compiler what functions should exist, while the EVM simply executes the requested function selector at the supplied contract address.

One import exists for deployment.

The other exists for abstraction.
