># 🏗   Uniswap V2 Contract Architecture

Now that we understand the **constant product invariant**, we must understand **how the protocol enforces it on-chain**.

Uniswap V2 is not a single contract.

Instead, the system is composed of **three core contracts**, each responsible for a different part of the system.

```
Factory
Pair
Router
```

These contracts together create a **modular architecture** that improves security and composability.

---

# 🏭 1️⃣ Factory Contract

## Concept

The **Factory contract** is responsible for creating **Pair contracts**.

A Pair contract represents a **liquidity pool for a specific token pair**.

Examples:

```
ETH / USDT
DAI / ETH
DAI / MKR
USDC / WBTC
```

Each pair corresponds to **one pool contract**.

---

## Responsibilities of the Factory

The factory performs three main roles:

```
Deploy pair contracts
Record pair addresses
Prevent duplicate pools
```

Important detail:

The Factory **does not hold tokens**.

It **does not perform swaps**.

It only **creates pools and tracks them**.

---

## Why Does the Factory Exist?

Without a factory contract:

• Anyone could deploy arbitrary liquidity pools  
• Multiple pools could exist for the same token pair  
• Liquidity would fragment  
• Routers would not know which pool to use  

The factory ensures **a canonical pair exists for each token pair**.

---

## Deterministic Pair Creation

When a pair is created, tokens are:

```
sorted
hashed
deployed via CREATE2
```

This produces a **deterministic pair address**.

Meaning:

Anyone can compute the pair address **before deployment**.

This property enables many DeFi integrations.

---

## What Happens If Someone Tries to Create the Same Pair Twice?

The factory checks whether the pair already exists.

If a pair exists:

```
createPair(tokenA, tokenB)
```

will **revert**.

This ensures:

```
One pair per token combination
```

---

## Question Everything

Who calls the factory?

```
Users
Routers
Other smart contracts
```

---

What happens if someone deploys a fake pair outside the factory?

They technically can.

But:

```
Routers ignore it
Frontends ignore it
LPs ignore it
```

Therefore it becomes economically irrelevant.

---

Why sort tokens?

Sorting prevents duplicate pair permutations.

Without sorting:

```
ETH/DAI
DAI/ETH
```

would create two pools.

Sorting enforces **a canonical ordering**.

---

## Attack Thinking

What if the factory allowed duplicate pairs?

Liquidity fragmentation would occur.

Different pools would have different prices.

Arbitrage would constantly shift liquidity.

The protocol would lose efficiency.

---

# 🔒 2️⃣ Pair Contract

## Concept

The **Pair contract** is the **core of the AMM**.

It is the contract that:

```
holds tokens
tracks reserves
executes swaps
mints LP tokens
burns LP tokens
```

This contract enforces the invariant:

```
x * y = k
```

---

## What the Pair Contract Stores

A pair contract maintains:

```
token0 reserve
token1 reserve
LP token supply
price accumulators (for TWAP)
```

The reserves represent the **current state of the AMM curve**.

---

## Main Functions of the Pair Contract

The pair contract performs four fundamental operations.

### 1️⃣ Mint

Liquidity providers deposit tokens.

The contract mints **LP tokens** representing ownership.

---

### 2️⃣ Burn

LP tokens are burned.

Liquidity providers receive their share of reserves.

---

### 3️⃣ Swap

Traders exchange tokens.

The invariant must remain satisfied.

---

### 4️⃣ Sync

Reserves are updated to match the contract's token balances.

---

## Why Separate Pair from Router?

Security.

If the router held funds:

• Router upgrades could steal funds  
• Complex logic increases attack surface  

Separating the pair ensures:

```
Funds remain in minimal logic contracts
```

---

## Invariant Enforcement

After every swap, the pair verifies:

```
new_reserve_x * new_reserve_y >= previous_k
```

If this condition fails:

```
transaction reverts
```

This prevents draining liquidity.

---

## Question Everything

Who interacts with Pair contracts?

```
Router
Advanced users
Smart contracts
```

---

Why don't normal users call Pair directly?

Direct interaction requires:

• manual output calculations  
• manual invariant checks  
• precise reserve accounting  

Router abstracts this complexity.

---

What if reserves are updated incorrectly?

The invariant may break.

Liquidity providers could lose funds.

---

What if tokens have transfer fees?

The amount received by the pair becomes smaller than expected.

This can break invariant calculations.

---

## Attack Thinking

Potential vulnerabilities include:

```
fee-on-transfer tokens
incorrect reserve updates
reentrancy attacks
precision rounding issues
```

Protocols integrating AMMs must account for these.

---

# 🧭 3️⃣ Router Contract

## Concept

The **Router contract** is the **user-facing interface** of Uniswap.

Instead of interacting with pairs directly, users call the router.

The router orchestrates interactions across pairs.

---

## Router Responsibilities

The router performs:

```
addLiquidity
removeLiquidity
swapExactTokensForTokens
swapExactETHForTokens
swapTokensForExactTokens
```

These functions allow users to interact with pools safely.

---

## Why the Router Exists

Without the router, users would need to:

```
calculate swap outputs manually
approve tokens correctly
call pair contracts directly
handle multi-hop routing
```

This would be extremely error-prone.

The router simplifies interaction.

---

## Multi-Hop Swaps

Often a token pair does not have direct liquidity.

Example:

```
ETH → MKR
```

No direct pool may exist.

Router performs:

```
ETH → DAI
DAI → MKR
```

This is called **multi-hop routing**.

---

## Why Multi-Hop Routing Works

Many tokens share **liquidity bridges**.

Common intermediaries include:

```
WETH
USDC
DAI
```

These assets form the **core liquidity graph of DeFi**.

---

## Question Everything

Who calls the router?

```
Users
Arbitrage bots
DeFi protocols
Aggregators
```

---

Why not allow users to call pairs directly?

Because mistakes are easy.

Sending tokens without calling swap can permanently lock funds.

---

Who calculates swap outputs?

The router or frontend typically computes expected output using reserve data.

---

What happens if router logic fails?

Funds remain safe in pair contracts.

---

## Attack Thinking

Possible attack surfaces include:

```
malicious tokens
front-running attacks
sandwich attacks
incorrect slippage parameters
```

These occur at the **user interaction layer**.

---

# 🔄 4️⃣ Full System Flow

Understanding how these contracts interact is crucial.

---

## Creating a Pool

```
User
 ↓
Router
 ↓
Factory
 ↓
Pair contract deployed
```

---

## Adding Liquidity

```
User
 ↓
Router
 ↓
Pair
 ↓
LP tokens minted
```

---

## Swapping Tokens

```
User
 ↓
Router
 ↓
Pair contract(s)
 ↓
Reserves updated
 ↓
Invariant checked
```

---

# 🧠 Mastery Questions

You should be able to answer:

1️⃣ Why is the factory necessary?

2️⃣ What happens if multiple pools exist for the same token pair?

3️⃣ Why does the pair contract hold funds instead of the router?

4️⃣ Why is the router only an orchestration layer?

5️⃣ How do multi-hop swaps enable liquidity across the ecosystem?

---

# 👶 Child Analogy Story

Imagine a **toy trading city**.

Three important roles exist.

---

### 🏭 The Factory

The factory builds **toy trading booths**.

Each booth trades two toys.

Examples:

```
Lego ↔ Cars
Cars ↔ Dinosaurs
Dinosaurs ↔ Robots
```

The factory ensures:

```
Only ONE booth exists for each pair.
```

Otherwise kids would get confused.

---

### 🧺 The Pair (Trading Booth)

Each booth has a **box of toys**.

Kids trade toys with the box.

But the booth has a magical rule:

```
toyA × toyB must stay constant
```

If someone adds cars:

The booth removes some Lego.

---

### 🧭 The Router (Helper)

Kids are bad at math.

So the city hires a helper.

The helper says:

```
Give me your toy.
I will handle the trades.
```

If a kid wants:

```
Lego → Robots
```

But no booth exists:

The helper performs:

```
Lego → Cars
Cars → Dinosaurs
Dinosaurs → Robots
```

Then gives the final toy.

---

# Key Takeaway

Uniswap separates responsibilities:

```
Factory → creates pools
Pair → holds liquidity and enforces invariant
Router → simplifies user interaction
```

This architecture keeps funds secure while enabling composable DeFi markets.


---
---
---