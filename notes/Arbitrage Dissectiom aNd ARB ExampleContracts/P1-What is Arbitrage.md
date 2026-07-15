# Part 1 — What is Arbitrage?

## Definition

Arbitrage is the process of **buying an asset in one market where it is priced lower and immediately selling the same asset in another market where it is priced higher**, earning a profit from the price difference.

The important point is that **the asset itself is identical**.

Nothing about the asset changes.

The only thing that changes is **where it is being traded**.

For example:

* 1 WETH on Uniswap is still the exact same 1 WETH on SushiSwap.
* 1 USDC on Binance is the same 1 USDC on Coinbase.
* The token does not gain or lose value simply because it exists on another exchange.

The profit comes solely from the temporary price difference between markets.

---

# Understanding Arbitrage with a Simple Example

Suppose two decentralized exchanges have different prices for WETH.

| Exchange  | Price of 1 WETH |
| --------- | --------------: |
| Uniswap   |    **3000 DAI** |
| SushiSwap |    **3100 DAI** |

Immediately we can observe:

* Uniswap sells WETH cheaper.
* SushiSwap values WETH higher.

An arbitrageur notices this opportunity.

Instead of buying WETH to hold it for months, they perform two trades almost instantly.

### Step 1

Buy 1 WETH on Uniswap.

```text
Spend:

3000 DAI

Receive:

1 WETH
```

### Step 2

Immediately sell that same WETH on SushiSwap.

```text
Spend:

1 WETH

Receive:

3100 DAI
```

Final result:

```text
Started with:

3000 DAI

↓

Bought WETH

↓

Sold WETH

↓

Ended with:

3100 DAI
```

Ignoring fees:

```text
Profit

= 3100 − 3000

= 100 DAI
```

---

# Visualizing the Flow

```text
        3000 DAI
            │
            ▼
      Buy on Uniswap
            │
            ▼
         1 WETH
            │
            ▼
    Sell on SushiSwap
            │
            ▼
        3100 DAI
```

Notice that we end with the **same currency we started with (DAI)**.

The WETH is only an intermediate asset that allows us to exploit the price difference.

---

# Why Does Arbitrage Exist?

A natural question is:

> **"If both exchanges trade the same token, why aren't the prices always identical?"**

The answer is simple.

Every exchange is independent.

For example:

```text
Uniswap

3000 DAI / WETH
```

while

```text
SushiSwap

3100 DAI / WETH
```

Neither exchange communicates with the other.

There is:

* no synchronization,
* no shared order book,
* no central authority,
* no mechanism that instantly forces both prices to match.

As a result, temporary price differences naturally appear.

---

# Arbitrage Exists Because Markets Are Not Perfect

Financial markets are constantly changing.

Prices move every second.

Even if two exchanges started with exactly the same price, many events can cause them to diverge.

For example:

* Someone executes a very large swap on Uniswap.
* Liquidity is added or removed.
* News causes the global market price to change.
* One exchange updates faster than another.
* Different traders execute different transactions.

These events create temporary pricing inefficiencies.

Arbitrageurs exist specifically to exploit these inefficiencies.

---

# Arbitrage Is Not Investing

Many beginners confuse arbitrage with investing.

They are completely different strategies.

### Investing

You buy an asset because you believe its value will increase in the future.

Example:

```text
Buy ETH today.

Wait six months.

Hopefully sell for more.
```

Profit depends on predicting future prices.

---

### Arbitrage

You do **not** care where ETH's price will be tomorrow.

You only care that **right now**:

```text
Exchange A

3000 DAI

Exchange B

3100 DAI
```

You buy and sell almost immediately.

There is usually no intention to hold the asset.

Profit comes from **price differences**, not future appreciation.

---

# Arbitrage Does Not Create New Value

Another common misconception is that arbitrage somehow creates money.

It doesn't.

Imagine two stores selling the exact same laptop.

```text
Store A

$1000

Store B

$1100
```

You buy from Store A.

You sell to Store B.

You earn:

```text
$100
```

Did the laptop become more valuable?

No.

You simply took advantage of inconsistent pricing.

Crypto arbitrage works exactly the same way.

The trader profits because two markets temporarily disagree on what the asset is worth.

---

# Arbitrage Opportunities Do Not Last Long

Suppose many arbitrageurs notice the same opportunity.

Initially:

```text
Uniswap

3000 DAI
```

```text
SushiSwap

3100 DAI
```

Every arbitrageur buys WETH from Uniswap.

This increases Uniswap's price.

At the same time, everyone sells WETH on SushiSwap.

This decreases SushiSwap's price.

Eventually both exchanges converge toward nearly the same price.

For example:

```text
Uniswap

3048 DAI
```

```text
SushiSwap

3050 DAI
```

Now the remaining difference is too small to cover trading fees and gas costs.

The arbitrage opportunity disappears.

This is why arbitrage opportunities are often measured in **seconds**, or even **milliseconds**, on public blockchains.

---

# Real-World Arbitrage

Today, most profitable arbitrage is performed by automated software.

These bots continuously monitor hundreds of exchanges simultaneously.

Whenever they detect a profitable price difference, they:

1. Calculate the expected profit.
2. Include swap fees.
3. Include gas costs.
4. Estimate slippage.
5. Submit a transaction immediately.

The fastest bot usually captures the opportunity.

This is one of the reasons why arbitrage has become closely associated with **MEV (Maximal Extractable Value)**.

---

# Key Takeaways

* Arbitrage means buying an asset where it is cheaper and selling it where it is more expensive.
* The asset itself never changes—only its price differs between markets.
* Arbitrage profits come from temporary pricing inefficiencies.
* Arbitrage is different from investing because it does not rely on predicting future prices.
* Arbitrage does not create value; it exploits existing market inefficiencies.
* Arbitrage opportunities naturally disappear as traders buy from the cheaper market and sell into the more expensive one.
* In modern DeFi, most arbitrage is performed automatically by specialized MEV searchers and arbitrage bots.
