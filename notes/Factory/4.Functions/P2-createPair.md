# 4.2 createPair()
>**Attention** In my codes I made some tweaks and gas optimization and sol0.8.+ updation so dont freak out if you see a bit diff lines

```solidity
function createPair(address tokenA, address tokenB)
    external
    returns (address pair)
{
    require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');

    (address token0, address token1) =
        tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

    require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');

    require(
        getPair[token0][token1] == address(0),
        'UniswapV2: PAIR_EXISTS'
    );

    bytes memory bytecode =
        type(UniswapV2Pair).creationCode;

    bytes32 salt =
        keccak256(
            abi.encodePacked(token0, token1)
        );

    assembly {
        pair := create2(
            0,
            add(bytecode, 32),
            mload(bytecode),
            salt
        );
    }

    IUniswapV2Pair(pair).initialize(token0, token1);

    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair;

    allPairs.push(pair);

    emit PairCreated(
        token0,
        token1,
        pair,
        allPairs.length
    );
}
```

## Overview

`createPair()` is the most important function in the Factory.

Its responsibility is to deploy a brand-new `UniswapV2Pair` contract for two ERC-20 tokens and permanently register that Pair inside the Factory.

The Factory also guarantees one of the protocol's most important invariants:

> **For any two tokens, there can only ever be one Pair contract.**

At a high level, the function performs the following steps:

```text
Receive Two Token Addresses

↓

Validate Input

↓

Sort Into Canonical Order

↓

Ensure The Pair Doesn't Already Exist

↓

Prepare CREATE2 Deployment

↓

Deploy The Pair

↓

Initialize The Pair

↓

Register The Pair

↓

Emit PairCreated Event
```

Rather than repeating concepts already discussed elsewhere, this chapter references those notes and focuses on the parts unique to the Factory.

---

# 4.2.1 Token Validation & Sorting

The first three lines:

```solidity
require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');

(address token0, address token1) =
    tokenA < tokenB
        ? (tokenA, tokenB)
        : (tokenB, tokenA);

require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
```

are functionally identical to:

```solidity
sortTokens(...)
```

inside:

```text
contracts/peripheryUV2/library/UV2Library.sol
```
Please read the complete NatSpec documentation for `sortTokens()` before continuing.
Additionally through  inside: 
```text
notes/Factory/2.Factory Storage/P2-getPair&allPair.md
```
You will find sub Part inside it about `sortTokens()` apart from the natspecs.



That note already covers:

* identical addresses,
* zero address validation,
* canonical token ordering,
* deterministic ordering,
* preventing duplicate pools,
* and why the Factory intentionally duplicates these three lines instead of importing the Library.

Those concepts are not repeated here.

---

# 4.2.2 Pair Already Exists

```solidity
require(
    getPair[token0][token1] == address(0),
    'UniswapV2: PAIR_EXISTS'
);
```

Before deploying a new Pair, the Factory checks whether one has already been registered for this token combination.

If the mapping already contains a Pair address, the transaction immediately reverts.

This guarantees that there can only ever be one liquidity pool for any canonical token pair.

A detailed discussion of the Factory registry and `getPair` has already been covered in:

```text
notes/Factory/2.Factory Storage/P2-getPair&allPair.md
```
Just hangtight while going through it, you will love it, just keeo pushing through the notes and from section5 in there it starts getting real good, but go through the the verybeginning, highly recommended!
---

# 4.2.3 Creation Code & Salt

```solidity
bytes memory bytecode =
    type(UniswapV2Pair).creationCode;

bytes32 salt =
    keccak256(
        abi.encodePacked(token0, token1)
    );
```

These two lines prepare everything required for deterministic CREATE2 deployment.

A complete first-principles discussion of:

* Creation Code (Init Code)
* Runtime Code
* `type(...).creationCode`
* `INIT_CODE_HASH`
* Salt generation
* CREATE2
* Deterministic deployment
* Pair address calculation

has already been covered in:

```text
notes/Periphery/Library/Library/UV2Library--PairForAndCreate2.md
```

The only difference here is that the Library **predicts** the Pair address, whereas the Factory actually **deploys** the Pair.

---
# 4.2.4 Deploying The Pair

```solidity
assembly {
    pair := create2(
        0,
        add(bytecode, 32),
        mload(bytecode),
        salt
    )
}
```

## First Thought

Everything before this point was merely preparation.

The Factory has already:

* validated the input,
* sorted the tokens,
* confirmed the Pair doesn't already exist,
* obtained the Pair's creation code,
* and generated the CREATE2 salt.

However, **nothing has actually been deployed yet**.

The Pair contract still does **not** exist on the blockchain.

```text
Input Validation ✅

↓

Token Sorting ✅

↓

Pair Doesn't Exist ✅

↓

Creation Code Ready ✅

↓

Salt Ready ✅

----------------------------

No Pair Contract Yet
```

This is the first line that actually creates a new smart contract.

---

## The Moment The Pair Is Created

When the EVM reaches:

```solidity
create2(...)
```

it receives:

* the Pair's creation code,
* the deployment salt,
* and the deployment parameters.

The EVM then deploys a brand-new `UniswapV2Pair` contract.

Conceptually:

```text
Creation Code

+

Salt

↓

CREATE2

↓

New Pair Contract
```

Everything before this line was preparation.

This line performs the deployment.

---

## From Creation Code To Runtime Code

A very important concept is understanding what happens during deployment.

The Factory provides the Pair's **creation code** (also called **init code**) to CREATE2.

The EVM executes that creation code.

During execution, the creation code constructs and returns the contract's **runtime code**.

The runtime code is then permanently stored on-chain.

Finally, the creation code is discarded.

The deployment lifecycle looks like this:

```text
Creation Code

↓

Executed Once

↓

Returns Runtime Code

↓

Runtime Code Stored On-Chain

↓

Creation Code Discarded
```

The creation code never lives on-chain permanently.

It exists only long enough to deploy the contract.

---

## Runtime Code Is What We Interact With

After deployment, every interaction with the Pair contract executes its runtime code.

For example:

```solidity
pair.swap(...);

pair.mint(...);

pair.burn(...);
```

All of these execute the stored runtime bytecode.

The creation code is never executed again.

---

## Storage Is Separate

Another important realization is that contract storage is separate from the contract's runtime code.

Conceptually, a deployed contract consists of:

```text
Contract

├── Runtime Code

├── Storage

└── ETH Balance
```

The creation code is **not** part of the deployed contract.

It disappeared immediately after deployment finished.

---

## Why Inline Assembly?

A natural question is:

> Why didn't Uniswap simply write:

```solidity
new UniswapV2Pair(...)
```

The answer is historical.

Uniswap V2 targets Solidity **0.5.16**.

At that time, Solidity did not support deploying contracts using CREATE2 through high-level syntax.

Instead, developers had to invoke the CREATE2 opcode directly using inline assembly.

Modern Solidity later introduced syntax similar to:

```solidity
new Contract{salt: salt}(...)
```

making CREATE2 deployments possible without assembly.

Since that syntax did not exist when Uniswap V2 was written, inline assembly was the only option.

---

# Understanding `create2(...)`

```solidity
create2(
    0,
    add(bytecode, 32),
    mload(bytecode),
    salt
)
```

The CREATE2 opcode expects four arguments.

Each one has a specific purpose.

---

## Argument 1 — ETH To Send

```solidity
0
```

The first argument specifies how much ETH should be transferred to the newly deployed contract during deployment.

Here:

```solidity
create2(0, ...)
```

means:

```text
Deploy Pair

↓

Send 0 ETH
```

The Pair contract begins with an ETH balance of zero.

Liquidity is supplied later through normal protocol operations, not during deployment.

---

## Argument 2 — Where The Bytecode Starts

```solidity
add(bytecode, 32)
```

`bytecode` is a dynamic `bytes` array stored in memory.

In Solidity, dynamic byte arrays begin with a 32-byte length field.

Conceptually:

```text
Memory

┌──────────────────────┐
│ Length (32 bytes)    │
├──────────────────────┤
│ Creation Code        │
│                      │
└──────────────────────┘
```

Passing `bytecode` directly would point CREATE2 at the length field rather than the actual creation code.

Therefore:

```solidity
add(bytecode, 32)
```

moves the memory pointer forward by one 32-byte word so it points to the first byte of the creation code.

---

## Argument 3 — How Many Bytes To Read

```solidity
mload(bytecode)
```

Once CREATE2 knows where the creation code begins, it also needs to know how many bytes to copy.

`mload(bytecode)` reads the first 32-byte word from memory.

For a dynamic `bytes` array, that first word stores the array's length.

So:

```text
add(bytecode, 32)

↓

Start Reading Here

------------------------

mload(bytecode)

↓

Read This Many Bytes
```

The second and third arguments therefore work together.

---

## Argument 4 — The Salt

```solidity
salt
```

The final argument is the deterministic CREATE2 salt.

Its generation and purpose have already been covered in detail in:

```text
notes/Periphery/Library/Library/UV2Library--PairForAndCreate2.md
```

The same salt previously used to predict the Pair's address is now used to actually deploy the Pair at that deterministic address.

---

## Where Is The Factory Address?

One question naturally arises.

The CREATE2 address formula includes the Factory address.

However, the Factory address is **not** passed as an argument.

Why?

The answer is that the EVM already knows which contract is currently executing.

When the CREATE2 opcode runs, the executing contract is the Factory itself.

The EVM automatically uses the executing contract's address as the deployer when calculating the CREATE2 address.

The Factory address is therefore **implicit**, not an explicit parameter.

---

## Final Realization

Everything before this point prepared the deployment.

This assembly block is the moment the Pair actually comes into existence.

A generic Pair blueprint is transformed into a live smart contract deployed at its deterministic CREATE2 address, ready for initialization in the next step.
---
# 4.2.5 Pair Initialization

```solidity
IUniswapV2Pair(pair).initialize(token0, token1);
```

## First Thought

At first glance, this line may seem unnecessary.

The Pair contract has **already been deployed**.

So a natural question arises:

> **Why do we need to initialize it after deployment?**

Shouldn't the constructor have already received `token0` and `token1`?

---

## What Was Actually Deployed?

Earlier, the Factory deployed the Pair using:

```solidity
type(UniswapV2Pair).creationCode;
```

Notice what was deployed.

It was **not**:

```text
WETH / USDC Pair
```

or

```text
WBTC / ETH Pair
```

Instead, the Factory deployed a completely **generic Pair contract**.

Think of it as a blueprint.

```text
Generic Pair Blueprint

↓

CREATE2

↓

Generic Pair Contract
```

At this moment, the Pair still doesn't know which two tokens it will manage.

---

## The Missing Information

Immediately after deployment, the Pair exists on-chain, but it has not yet been configured.

Conceptually:

```text
New Pair Contract

↓

token0 = ?

token1 = ?
```

The Factory now supplies that missing information by calling:

```solidity
initialize(token0, token1);
```

After initialization:

```text
Generic Pair

↓

Initialize

↓

WETH / USDC Pair
```

or

```text
Generic Pair

↓

Initialize

↓

LINK / DAI Pair
```

The deployment creates the contract.

Initialization gives it its identity.

---

## Why Not Use The Constructor?

A natural question is:

> Why didn't Uniswap simply pass `token0` and `token1` into the constructor?

The reason is that every Pair is deployed from the exact same generic creation code:

```solidity
type(UniswapV2Pair).creationCode;
```

The Factory does not generate a different creation code for every token pair.

Instead, it deploys one generic contract and immediately configures it using `initialize()`.

This allows every Pair to share the exact same deployed code while differing only in the values written to storage.

---

## Is This The Same As Upgradeable Contracts?

Many developers associate `initialize()` with upgradeable contracts.

However, this is a different use case.

In upgradeable contracts:

```text
Constructor

↓

Cannot Be Used

↓

initialize()

Replaces Constructor
```

In Uniswap V2:

```text
Constructor

↓

Still Exists

↓

initialize()

Configures A Newly Deployed Generic Pair
```

Here, `initialize()` is **not** replacing the constructor.

It simply configures the newly deployed Pair after CREATE2 deployment.

The function happens to have the same name, but it serves a different purpose.

---

## Why Use The Interface?

Notice the Factory calls:

```solidity
IUniswapV2Pair(pair).initialize(...);
```

instead of:

```solidity
UniswapV2Pair(pair).initialize(...);
```

The interface tells the compiler which external functions the contract exposes.

The EVM does **not** check whether the deployed Pair inherits from `IUniswapV2Pair`.

It only checks whether a function matching the requested selector exists at the target address.

Using the interface provides compile-time type checking while keeping the interaction based on the Pair's public API rather than its implementation details.

---

## Import Without Directly Importing The Interface

You may also notice that the Factory imports:

```solidity
import "./UniswapV2Pair.sol";
```

instead of:

```solidity
import "./interfaces/IUniswapV2Pair.sol";
```

yet it still uses:

```solidity
IUniswapV2Pair(pair)
```

This works because `UniswapV2Pair.sol` already imports `IUniswapV2Pair.sol`.

The Solidity compiler recursively processes imports, so by importing the Pair contract, the interface also becomes available during compilation.

No additional import is required.

---

## Security Note

One important question remains:

> If `initialize()` is publicly callable, couldn't someone initialize the Pair before the Factory?

The answer lies inside `UniswapV2Pair.sol`.

The Pair contract contains access control ensuring that only the Factory can perform initialization, and only once.

That implementation will be covered when we study the Pair contract itself.

---

## Final Realization

Deployment and initialization are two separate steps.

```text
Deploy Generic Pair

↓

Initialize With token0 & token1

↓

Fully Configured Liquidity Pool
```

The Factory first creates a generic Pair contract using CREATE2, then immediately transforms it into a specific liquidity pool by assigning the two tokens it will permanently manage.
---
# 4.2.6 Pair Registration & Event Emission

```solidity
getPair[token0][token1] = pair;
getPair[token1][token0] = pair;

allPairs.push(pair);

emit PairCreated(
    token0,
    token1,
    pair,
    allPairs.length
);
```

## Registering The Pair

After the Pair has been successfully deployed and initialized, the Factory records it in its internal registry.

The Pair is registered in:

* `getPair` for fast bidirectional lookups.
* `allPairs` for enumeration and counting.

Rather than repeating those discussions here, please refer to:

```text
notes/Factory/2.Factory Storage/P2-getPair&allPair.md
```

That note explains:

* why the Pair is stored under both token orders,
* why the same Pair address appears twice in the mapping,
* why `allPairs` stores each Pair only once,
* why mappings cannot enumerate,
* and the architectural reasoning behind maintaining both storage structures.

---

## Emitting The Event

Finally, the Factory emits:

```solidity
emit PairCreated(
    token0,
    token1,
    pair,
    allPairs.length
);
```

This event announces that a new Pair has been successfully created and registered.

It includes:

* `token0` – The first token in canonical order.
* `token1` – The second token.
* `pair` – The newly deployed Pair contract address.
* `allPairs.length` – The total number of Pairs after this creation.

The event allows off-chain applications, indexers, block explorers, analytics platforms, and frontends to efficiently discover newly created Pair contracts without repeatedly querying the Factory's storage.

A detailed discussion of Solidity events, logs, topics, indexed parameters, and off-chain indexing will be covered separately in the dedicated Events notes.

---

## Final Flow

At this point, the entire Pair creation lifecycle is complete.

```text
Receive Token Addresses

↓

Validate Inputs

↓

Sort Tokens

↓

Ensure Pair Doesn't Exist

↓

Prepare CREATE2 Deployment

↓

Deploy Generic Pair

↓

Initialize Pair

↓

Register Pair

↓

Emit PairCreated Event

↓

Pair Ready For Liquidity
```

With this, the `createPair()` function is complete.
