# Part 2 — Why Arbitrage is Necessary for AMMs

Now that we understand what arbitrage is, the next question is far more important:

> **Why does Uniswap need arbitrageurs at all?**

At first glance, you might think arbitrage is simply a way for traders to make money.

In reality, arbitrage is **a fundamental component of the AMM design**.

Without arbitrageurs, Uniswap would not be able to maintain prices that reflect the rest of the market.

---

# The Biggest Misconception

One of the most common misconceptions is:

> **"Uniswap always knows the current market price."**

This is completely false.

A Uniswap V2 pair has **no knowledge of the outside world**.

It does **not** know:

* Binance's ETH price
* Coinbase's ETH price
* Kraken's ETH price
* OKX's ETH price
* Chainlink's ETH price
* CoinGecko's ETH price
* The "true" market price

The contract never asks:

> "What is ETH worth right now?"

Because it simply cannot.

Smart contracts cannot magically access external information.

---

# What Information Does a Pair Actually Know?

A Uniswap V2 Pair only stores a few important variables.

The most important are:

```text id="m3k1rx"
reserve0

reserve1
```

That's it.

Everything the pair does is derived from these reserve values.

It doesn't matter whether ETH is worth:

* $1,000
* $3,000
* $10,000

The pair doesn't know.

It only knows how many tokens it currently owns.

---

# Where Does the Price Come From?

Unlike centralized exchanges, Uniswap does **not** store a price.

There is no variable like:

```solidity
uint256 ethPrice = 3000;
```

Instead, the price **emerges naturally** from the reserve ratio.

For a DAI/WETH pool:

```text id="9yz1w2"
Price ≈

DAI Reserve
────────────
WETH Reserve
```

Suppose the pool contains:

```text id="9qepm9"
300,000 DAI

100 WETH
```

The implied price is approximately:

```text id="r6d6ti"
300000 / 100

=

3000 DAI/WETH
```

Notice something important.

Nobody typed "3000" anywhere.

The contract simply derives that value from its reserves.

---

# Prices Change Automatically

Suppose Alice buys WETH.

She pays DAI into the pool.

After the trade, the reserves become:

```text id="a6zy8t"
303,000 DAI

99 WETH
```

Now the implied price becomes:

```text id="2c7ftg"
303000 / 99

≈ 3060.61 DAI/WETH
```

The price increased.

Did someone update it?

No.

Did Chainlink send a transaction?

No.

Did an administrator change anything?

No.

The reserves changed.

Therefore the price changed.

This is one of the defining characteristics of an Automated Market Maker.

---

# What Happens When the Global Market Moves?

Imagine some major news breaks.

Ethereum becomes much more valuable.

Within seconds:

```text id="ursp5n"
Binance

3300 DAI
```

```text id="l4k7dm"
Coinbase

3298 DAI
```

```text id="lf9l5n"
Kraken

3301 DAI
```

Meanwhile...

Nobody has interacted with our Uniswap pool.

Its reserves are still:

```text id="jlwm1d"
300,000 DAI

100 WETH
```

So Uniswap still implies:

```text id="vxjlwm"
3000 DAI/WETH
```

The global market moved.

The Uniswap pool didn't.

---

# Is Uniswap Wrong?

Yes.

At this moment,

Uniswap's price is outdated.

But this isn't a bug.

It's exactly how AMMs are designed.

The contract has absolutely no way of knowing that the external market moved.

Remember:

The contract only knows its reserves.

Nothing else.

---

# So Who Fixes the Price?

This is where arbitrageurs enter the picture.

They observe:

```text id="nmn3wy"
Global Market

3300 DAI
```

```text id="jlwmuh"
Uniswap

3000 DAI
```

Immediately they realize:

> **ETH is underpriced on Uniswap.**

So they begin buying ETH from the pool.

Every purchase changes the reserves.

Example:

Initially:

```text id="r97vc0"
300,000 DAI

100 WETH
```

After arbitrage:

```text id="2eok2z"
310,000 DAI

97 WETH
```

More arbitrage:

```text id="sqjlwm"
320,000 DAI

94 WETH
```

More arbitrage:

```text id="phhh5j"
329,000 DAI

90 WETH
```

Each trade pushes the implied price higher.

Eventually the pool reaches approximately:

```text id="njlwm9"
3300 DAI/WETH
```

At that point,

there is no longer any profit to be made.

So arbitrage naturally stops.

---

# Arbitrage Is the Price Synchronization Mechanism

This is one of the most important ideas in AMMs.

Arbitrageurs are **not merely traders**.

They are the mechanism that synchronizes decentralized liquidity pools with the rest of the market.

Without them:

* every liquidity pool would slowly drift away from reality,
* every DEX would quote different prices,
* users would receive inaccurate exchange rates,
* DeFi markets would become highly inefficient.

Instead,

arbitrage continuously pulls prices back toward market equilibrium.

---

# Why Doesn't Uniswap Simply Use an Oracle?

Many beginners ask:

> **"Why not use Chainlink to update the pool price?"**

This sounds reasonable until you remember how an AMM works.

Suppose Chainlink suddenly says:

```text id="jlwm5m"
ETH

3300 DAI
```

But the pool still contains:

```text id="jlwm8v"
300,000 DAI

100 WETH
```

Those reserves can only support swaps according to the constant product formula.

Simply writing:

```text
ETH = 3300 DAI
```

inside the contract changes nothing.

The reserves remain identical.

The swap calculations remain identical.

The pool would now be displaying a price that its reserves cannot actually support.

That would completely break the AMM.

In Uniswap:

> **The reserves define the price.**

The price never defines the reserves.

---

# The Only Valid Way to Change Price

Within an AMM, price can only change when reserves change.

Reserves change through:

* swaps,
* liquidity additions,
* liquidity removals.

Nothing else.

This is why arbitrage is so important.

Arbitrage changes the reserves.

Changing the reserves changes the price.

---

# Why Arbitrageurs Earn Money

Arbitrageurs are economically rewarded for performing this service.

They:

* discover pricing inefficiencies,
* execute trades,
* restore price accuracy,
* earn the remaining price difference.

Notice something interesting.

The protocol never pays them.

Liquidity providers never pay them.

Instead,

the **market inefficiency itself** becomes their reward.

This creates a beautiful incentive structure.

Whenever prices become inaccurate,

someone is financially motivated to fix them.

---

# An Analogy

Imagine two supermarkets selling identical bottles of water.

```text id="jlwmxx"
Store A

₹20
```

```text id="jlwmxy"
Store B

₹25
```

Customers will naturally buy from Store A.

Eventually Store A begins running low on stock.

Its effective selling price rises.

Meanwhile,

Store B receives more sellers and its price falls.

Eventually both stores converge toward roughly the same price.

Neither store coordinated with the other.

The customers themselves caused the prices to align.

Arbitrageurs play exactly this role in decentralized finance.

---

# Key Takeaways

* A Uniswap V2 Pair has no knowledge of external market prices.
* It derives prices solely from its token reserves.
* External price movements do not automatically update an AMM.
* Arbitrageurs continuously compare AMM prices with other markets.
* Whenever a price difference appears, they trade against the pool.
* Those trades change the reserves.
* Changing the reserves automatically changes the pool price.
* Arbitrage is therefore not just a profit opportunity—it is the mechanism that keeps AMM prices synchronized with the rest of the market.
