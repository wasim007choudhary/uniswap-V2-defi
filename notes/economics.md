# Introduction to Constant Product AMMs

> Just a slight peek rest will be broken along with the functions and in their notes with every conceot attached to it GGs

We begin by analyzing the **constant product Automated Market Maker**, which is the fundamental mechanism used by Uniswap V2 to facilitate decentralized trading.

Unlike traditional exchanges that rely on **order books**, AMMs use **mathematical invariants** to determine pricing and trade outcomes.

Instead of matching buyers and sellers:

• Liquidity providers deposit tokens into a pool  
• Traders interact directly with the pool  
• A mathematical rule determines how tokens move  

This rule ensures that **every trade preserves a specific invariant**.

---

# ⚙️ 1️⃣ What Is a Constant Product AMM?

An **Automated Market Maker (AMM)** is:

> A smart contract that holds two tokens and allows users to trade between them using a mathematical rule instead of an order book.

The rule used by Uniswap V2 is the **constant product invariant**:

```
x * y = L²
```

Where:

```
x = reserve of token X
y = reserve of token Y
L = liquidity constant
```

Many resources write the formula differently:

```
x * y = k
```

Where:

```
k = constant product
k = L²
```

Both represent the **same invariant**.

Uniswap documentation usually uses the form:

```
x * y = k
```

---

# 🔍 Why Does This Rule Exist?

If a trader sends tokens into the pool:

• How do we determine how many tokens leave?

There must be **a rule that governs every trade**.

Without such a rule:

• Traders could withdraw arbitrary amounts  
• Liquidity providers would lose funds  
• Markets would collapse

The invariant acts as a **mechanical law of the pool**.

---

# 🧠 2️⃣ Why Multiply Reserves?

Now we question everything.

Why does the AMM multiply reserves?

Why not use simpler rules?

Possible alternatives might include:

```
x + y = constant
```

or

```
x − y = constant
```

or even

```
fixed price trading
```

Let’s test one alternative.

### Suppose we used:

```
x + y = constant
```

Example pool:

```
x = 100
y = 100
```

Total:

```
x + y = 200
```

Now imagine a trader removes all X.

The pool could become:

```
x = 0
y = 200
```

No resistance exists.

The entire asset could be drained.

---

### Why Multiplication Works

Multiplication creates **curvature**.

Curvature creates **price resistance**.

Price resistance creates **slippage**.

Slippage protects liquidity providers.

Large trades become increasingly expensive.

This property is what prevents pools from being drained easily.

---

# 📈 3️⃣ What Does The AMM Curve Represent?

The equation

```
x * y = k
```

forms a **hyperbolic curve**.

Every point on this curve represents a **valid state of the liquidity pool**.

---

### Example Pool

Initial state:

```
x = 200
y = 200
```

Then:

```
x * y = 40,000
```

Thus:

```
k = 40,000
```

Any valid reserve state must satisfy:

```
x * y = 40,000
```

Examples of valid states include:

```
200 , 200
100 , 400
50  , 800
400 , 100
```

Every one of these satisfies:

```
x * y = 40,000
```

Each point represents a **different reserve composition**.

---

# 🔄 4️⃣ Trade Walkthrough — Step by Step

Now we simulate a trade.

Initial pool:

```
x = 200
y = 200
k = 40,000
```

A trader sends:

```
+200 Y
```

New Y reserve becomes:

```
y₁ = 400
```

But the invariant must still hold:

```
x₁ * 400 = 40,000
```

Solving:

```
x₁ = 100
```

New pool state:

```
x = 100
y = 400
```

Now we calculate the output.

Initial X:

```
200
```

Final X:

```
100
```

Tokens removed from pool:

```
200 − 100 = 100
```

The trader receives:

```
100 X
```

---

# 💰 5️⃣ How Does The Curve Determine Price?

The AMM itself **does not set prices**.

There is no oracle.

There is no administrator.

Price emerges automatically from reserves.

Approximate price formula:

```
price ≈ y / x
```

---

### Initial price

```
200 / 200 = 1
```

---

### After trade

```
400 / 100 = 4
```

Price increased dramatically.

This change during a trade is known as **slippage**.

---

# 🌊 6️⃣ What Is Liquidity (L)?

Liquidity describes **how much capital is in the pool**.

From the invariant:

```
x * y = L²
```

Higher liquidity means:

• Larger curve  
• Flatter price movement  
• Lower slippage  

---

# 📊 Liquidity Example

Suppose the pool begins with:

```
x = 400
y = 400
```

Then:

```
k = 160,000
```

Now a trader adds:

```
+200 X
```

New X reserve:

```
x₁ = 600
```

Solve for Y:

```
600 * y₁ = 160,000
```

Thus:

```
y₁ = 266.6667
```

Tokens removed:

```
400 − 266.6667 = 133.3333
```

Compared with the smaller pool:

Traders receive **more output for the same input**.

This is why **deep liquidity produces better market prices**.

---

# ❓ Question Everything

Who moves the pool along the curve?

```
Traders
```

---

Who determines the next point on the curve?

```
The invariant equation
```

---

Who enforces the invariant?

```
The smart contract
```

---

What happens if the invariant is not enforced?

```
The pool can be drained
```

Liquidity providers lose funds.

---

What happens if a trader sends extremely large input?

The opposite reserve approaches zero **asymptotically**.

---

Can reserves reach zero?

```
Mathematically: No
Practically: They can approach extremely small values
```

---

# 🧨 Attack Thinking

We must think adversarially.

What if:

A token charges transfer fees?

Reserve accounting may break.

---

What if:

A token allows reentrancy?

Swap execution could be manipulated.

---

What if:

Reserves are updated incorrectly?

The invariant may decrease.

---

What if:

Integer rounding reduces k?

Liquidity providers lose value.

---

Critical safety condition:

```
new_x * new_y ≥ old_k
```

If violated:

```
Transaction reverts
```

---

# 🧠 Mastery Check

Answer these before moving forward:

##### ***1️⃣ Why does multiplication create slippage?***
>Because Multiplication creates curve curvature which creates price maupilation and thus price manupilation creates slippage. 
(***Note*** - What is slippage? => Slippage is the realized difference between expected and executed price)

##### ***2️⃣ Why does larger liquidity reduce price impact?***
> Because large liquidity creates  more output with same input. Thus larger liquidity means a larger  curve which which enables a Flatter price movement and thus creating a Lower slippage reducing the price impact.

##### ***3️⃣ Why can the AMM not maintain a fixed price?***
> Because of its core function is to facilitate trading through a mathematical formula *( x * y = L2 or K)* based on relative supply and demand.

##### ***4️⃣ Why does the curve approach zero but never reach it?***
> Because can *1/x* can never be zero can it, x will be infinity, as price is derived by *y/x* thus mathematically it can never reach zero. Try it bruh! But the value will become crazy small hence in most they output as zero but is never zero!

##### ***5️⃣ What would happen if the invariant was not enforced?***
> If the invariant 
*𝑥
⋅
𝑦
=
𝑘*
  were not enforced, a trader could input a tiny amount of one token and withdraw a huge amount of the other, because nothing would restrict the exchange ratio.

This would allow attackers or arbitrage bots to drain the liquidity pool instantly, causing liquidity providers to lose their funds and breaking the AMM’s pricing mechanism.
---

# 👶 Child Analogy Story

Imagine a magical playground seesaw.

On one side are **apples** 🍎  
On the other side are **oranges** 🍊

The playground has a rule:

```
apples × oranges = 40,000
```

No one can break the rule.

If a kid adds oranges to the seesaw:

The seesaw automatically removes apples.

No teacher decides.

No referee intervenes.

The **rule enforces balance automatically**.

---

If the seesaw holds a huge pile of fruit:

Adding one orange barely tilts it.

But if there are only a few fruits left:

Adding one orange tilts the seesaw dramatically.

That tilt is **slippage**.

Liquidity is like the **weight of the fruit piles**.

Heavy piles move slowly.

Small piles move quickly.

That is exactly how AMMs behave.

---


Now that we understand:

• The constant product invariant  
• Liquidity depth  
• Trade movement along the curve  

----
># 🔬 Section  — Swap Formula Derivation (Constant Product AMM)

Now that we understand the AMM invariant and contract architecture, we must answer the most important question:

> When a trader sends tokens into the pool, how does the protocol determine how many tokens come out?

This is governed by the **swap formula derived directly from the invariant**.

# ⚙️  Starting Point — The AMM Invariant

Every Uniswap V2 pool must always satisfy:

```
X * Y = k
```

Where:

```
X = reserve of token X
Y = reserve of token Y
k = constant product
```

This rule must hold:

```
Before a swap
After a swap
```

No transaction may violate this invariant.

---

# 📍 2️⃣ Initial Pool State

Before the trade occurs, assume the pool reserves are:

```
X = X₀
Y = Y₀
```

Therefore the invariant is:

```
X₀ * Y₀ = k
```

This point represents the current position on the AMM curve.

---

# 🔄 3️⃣ Trader Initiates Swap

Suppose Alice wants to trade.

She sends:

```
dx = amount of token X
```

to the pool.

After the deposit:

```
X₁ = X₀ + dx
```

But if X increases, something must change.

Otherwise:

```
(X₀ + dx) * Y₀ > k
```

which violates the invariant.

Therefore the pool must send some **Y tokens out**.

---

# 📤 4️⃣ Token Output

Let:

```
dy = amount of token Y Alice receives
```

After the swap:

```
Y₁ = Y₀ - dy
```

So the new pool state becomes:

```
(X₀ + dx , Y₀ - dy)
```

This point must still satisfy the invariant.

---

# 🧮 5️⃣ Apply The Invariant

The invariant must hold after the trade:

```
(X₀ + dx) * (Y₀ - dy) = k
```

But we already know:

```
k = X₀ * Y₀
```

Substitute:

```
X₀Y₀ = (X₀ + dx)(Y₀ - dy)
```

This equation defines the trade.

---

# ✏️ 6️⃣ Expand the Equation

Multiply the right side:

```
(X₀ + dx)(Y₀ - dy)
```

Expands to:

```
X₀Y₀ - X₀dy + Y₀dx - dxdy
```

So the equation becomes:

```
X₀Y₀ = X₀Y₀ - X₀dy + Y₀dx - dxdy
```

---

# ➖ 7️⃣ Simplify

Cancel the common term:

```
X₀Y₀
```

We get:

```
0 = -X₀dy + Y₀dx - dxdy
```

Rearrange:

```
Y₀dx = X₀dy + dxdy
```

Factor out dy:

```
Y₀dx = dy (X₀ + dx)
```

---

# 🧾 8️⃣ Solve For dy

Divide both sides by:

```
X₀ + dx
```

Final formula:

```
dy = (Y₀ * dx) / (X₀ + dx)
```

This formula determines how many tokens leave the pool.

---

# 📊 Numerical Example

Suppose the pool contains:

```
X₀ = 200
Y₀ = 200
```

Trader sends:

```
dx = 200
```

Plug into formula:

```
dy = (200 * 200) / (200 + 200)
```

```
dy = 40000 / 400
```

```
dy = 100
```

So the trader receives:

```
100 Y tokens
```

---

# 💰 9️⃣ Incorporating the Swap Fee

Uniswap V2 charges a **0.3% fee** on swaps.

This means:

```
0.3% goes to liquidity providers
```

Only **99.7% of the input tokens affect the invariant**.

Therefore we define:

```
dx_effective = dx * 0.997
```
or we can also say fee as `1-f` where `f` is that `0.3%` and it doesnt matter if it changes too!

>**Hence QUICKL NOTE**
>- in place of `0.997`, we can write `1-f` and it will look cool too lol. But here we wont do that ok. Just keep that in mind!

The invariant equation becomes:

```
(X₀ + dx * 0.997)(Y₀ - dy) = k
```

Solving again gives the **fee-adjusted formula**:

```
dy = (Y₀ * dx * 0.997) / (X₀ + dx * 0.997)
```

---

# 🧮 Solidity Implementation

In Uniswap V2 code, the calculation is implemented using integer math.

```
inputAmountWithFee = inputAmount * 997

numerator = inputAmountWithFee * reserveOut

denominator = reserveIn * 1000 + inputAmountWithFee

amountOut = numerator / denominator
```

This is the famous **997 / 1000 formula**.

---

# 📉 Economic Meaning of the Formula

Observe the denominator:

```
X₀ + dx
```

As dx becomes larger:

The denominator grows.

Therefore:

```
dy decreases
```

Meaning:

Large trades receive worse prices.

This is **slippage**.

---

# 🔎 Edge Case Thinking

### What happens if dx is extremely small?

The formula approximates:

```
dy ≈ (Y₀ / X₀) * dx
```

Which equals the **spot price**.

---

### What happens if dx becomes extremely large?

```
dy → Y₀
```

But it never equals Y₀.

The pool can **never be completely drained via swaps**.

---

### Why?

Because:

```
x * y = k
```

If Y becomes zero:

```
x * 0 = 0
```

But k must remain positive.

Thus the curve approaches zero **asymptotically**.

---

# ❓ Question Everything

Who calculates the swap output?

```
The pair contract
```

---

Why does dx appear in the denominator?

Because the invariant must remain constant.

Adding tokens changes the balance of the curve.

---

Why does slippage increase for large trades?

Because the curve steepens as reserves shift.

---

What if the invariant wasn't enforced?

A trader could:

```
send small input
withdraw large output
```

draining the pool.

---

# 🧨 Attack Thinking

What if tokens charge transfer fees?

The pair may receive fewer tokens than expected.

Reserve accounting can break.

---

What if rounding errors reduce k?

Liquidity providers lose value.

---

What if a malicious contract performs reentrancy?

Swap execution order could be manipulated.

---

These are key security concerns in AMM implementations.

---

# 🧠 Mastery Check

You should now understand:

1️⃣ Why the invariant determines trade output.

2️⃣ Why dy depends on both reserves.

3️⃣ Why slippage increases with trade size.

4️⃣ Why the pool cannot be drained via swaps.

5️⃣ Why the 997/1000 constant appears in the code.

---

# 👶 Child Analogy Story

Imagine a magical fruit machine.

Inside the machine are:

```
apples = X
bananas = Y
```

The machine follows one rule:

```
apples × bananas must stay constant
```

Now Alice inserts apples.

To maintain the rule, the machine must remove some bananas.

But the machine becomes more protective as bananas run out.

The more apples Alice inserts:

The harder it becomes to get bananas.

Eventually:

You can get **almost all bananas**

But never the last one.

The machine always protects the balance.

That protective behavior is exactly what the swap formula models.

---
-------------
----------------
------------

# 🔜 Next Section


Now that we understand:

• The invariant  
• Swap derivation  
• Fee-adjusted formula  

We will analyze **swap direction symmetry and reserve asymptotics**.

This explains:

```
X → Y swaps
Y → X swaps
why reserves never reach zero
```

># 🔁 Section 4 — Swap Direction & Reserve Asymptotics

So far we derived the swap formula assuming:

```
Trader inputs token X
Trader receives token Y
```

But in reality **either token can be the input**.

Uniswap pools are **symmetric**.

This means:

```
X → Y swaps
Y → X swaps
```

both follow the same invariant.

---

# ⚙️ 1️⃣ Two Possible Swap Directions

Assume a pool:

```
X = ETH
Y = USDC
```

Two swap types exist.

---

## Case A — Input X, Receive Y

Trader sends:

```
dx ETH
```

Pool returns:

```
dy USDC
```

Swap formula:

```
dy = (Y₀ * dx) / (X₀ + dx)
```

With fee:

```
dy = (Y₀ * dx * 0.997) / (X₀ + dx * 0.997)
```

---

## Case B — Input Y, Receive X

Trader sends:

```
dy USDC
```

Pool returns:

```
dx ETH
```

Mirror formula:

```
dx = (X₀ * dy) / (Y₀ + dy)
```

With fee:

```
dx = (X₀ * dy * 0.997) / (Y₀ + dy * 0.997)
```

---

# 🔍 Why The System Is Symmetric

The invariant:

```
X * Y = k
```

does not distinguish between tokens.

Both tokens are simply **variables of the same equation**.

Thus the AMM treats both directions identically.

There is no concept of:

```
buy
sell
bid
ask
```

The system only sees:

```
token in
token out
```

---

# 📊 Example Trade (Realistic Scenario)

Pool reserves:

```
100 ETH
200,000 USDC
```

Implied price:

```
2000 USDC / ETH
```

---

## Scenario 1 — User Buys ETH

Trader sends:

```
4000 USDC
```

USDC reserve increases:

```
200000 → 204000
```

To maintain the invariant:

ETH reserve must decrease.

Trader receives some ETH.

---

## Scenario 2 — User Sells ETH

Trader sends:

```
2 ETH
```

ETH reserve increases:

```
100 → 102 ETH
```

To maintain invariant:

USDC reserve must decrease.

Trader receives USDC.

---

# 📉 2️⃣ Why Reserves Never Reach Zero

This property confuses many developers.

Let's analyze mathematically.

Swap formula:

```
dy = (Y₀ * dx) / (X₀ + dx)
```

Now imagine extremely large input:

```
dx → infinity
```

Then:

```
dy → Y₀
```

But it never equals Y₀.

Meaning:

```
Y never becomes exactly zero
```

---

# 🧮 Numerical Example

Pool reserves:

```
X₀ = 100
Y₀ = 200
```

Trader sends:

```
dx = 1,000,000
```

Plug into formula:

```
dy ≈ (200 * 1,000,000) / (100 + 1,000,000)
```

Result:

```
dy ≈ 199.98
```

Remaining reserve:

```
Y ≈ 0.02
```

Even with enormous input, the pool still retains some tokens.

---

# 📈 Mathematical Reason

The invariant requires:

```
X * Y = k
```

If Y becomes zero:

```
X * 0 = 0
```

But k must remain positive.

Therefore:

```
Y cannot reach zero
```

The curve approaches the axis **asymptotically**.

---

# 🧠 Economic Meaning

As reserves shrink:

Price rises dramatically.

Example:

If only **1 ETH remains in the pool**:

The cost to buy it becomes extremely large.

Example intuition:

```
0.5 ETH → millions of USDC
0.9 ETH → tens of millions
0.99 ETH → hundreds of millions
```

Eventually it becomes economically irrational to continue.

---

# ⛓ On-Chain Reality (Integer Math)

Smart contracts do not use floating point numbers.

They use:

```
integer arithmetic
```

Tokens also have minimum units:

```
ETH → 1 wei
USDC → 0.000001
```

Because of rounding:

Reserves can approach:

```
1 wei
2 wei
```

Which is practically zero.

But **never exactly zero through swaps**.

---

# ⚠️ Important Distinction

Two different mechanisms exist:

### Swaps

Cannot drain the pool.

The invariant prevents full depletion.

---

### Liquidity Withdrawal

Liquidity providers can remove all funds.

Example:

```
burn LP tokens
withdraw reserves
```

This is how pools legitimately reach zero.

---

# ❓ Question Everything

Why does the AMM not distinguish between buy and sell?

Because the invariant only tracks reserves.

---

Why does price explode as reserves shrink?

Because the curve steepens near the axes.

---

Why can't the last token be removed?

Because that would violate:

```
x * y = k
```

---

Why does integer math matter?

Rounding errors can affect reserve accounting.

---

# 🧨 Attack Thinking

Even though swaps cannot drain pools mathematically, other vulnerabilities exist.

Possible attack vectors include:

```
flash loan manipulation
oracle manipulation
reentrancy bugs
fee-on-transfer tokens
incorrect reserve updates
```

These must be considered when integrating AMMs.

---

# 🧠 Mastery Check

You should now understand:

1️⃣ Why swaps work in both directions.

2️⃣ Why AMMs do not need buy/sell logic.

3️⃣ Why reserves approach zero but never reach it.

4️⃣ Why price increases exponentially as reserves shrink.

5️⃣ Why liquidity providers (not traders) can remove all tokens.

---

# 👶 Child Analogy Story

Imagine a magical candy jar.

Inside the jar are:

```
red candies
blue candies
```

The jar has a rule:

```
red × blue must stay constant
```

Kids can:

```
put red candies in
take blue candies out
```

or

```
put blue candies in
take red candies out
```

The jar does not care which direction.

But as blue candies run out:

The jar demands **more and more red candies**.

Eventually the jar becomes extremely protective.

You can get:

```
almost all candies
```

But never the **last one**.

Unless you own the jar and open the lid.

That is what liquidity providers can do.
