# 03 - Cumulative Price (`price0CumulativeLast`)

# Part 1.1 — Why Does Uniswap Need Cumulative Price?

In the previous chapter, we derived the mathematical equation for calculating the **Time-Weighted Average Price (TWAP)**.

The equation we arrived at was:

```text
                Σ(ΔT × Price)
TWAP = ─────────────────────────────
             Total Observation Time
```

At this point, a very important question naturally arises.

## Where Does Uniswap Get All Those Historical Prices?

The numerator requires us to know every price that existed during the observation period.

For example:

```text
Price₀

Price₁

Price₂

Price₃

...
```

This immediately raises a question.

**Does Uniswap store every historical price forever?**

Maybe something like this?

```solidity
uint256[] prices;
```

or

```solidity
mapping(uint256 => uint256) historicalPrices;
```

or maybe

```solidity
struct Price {
    uint256 price;
    uint256 timestamp;
}

Price[] history;
```

At first glance this sounds reasonable.

If TWAP needs historical prices, why not simply store every one of them?

## Think About It

Imagine a Pair that has existed for five years.

Suppose it has processed

```text
50,000,000 swaps.
```

If someone now asks:

> "What was the average price between these two timestamps?"

the Pair would need access to millions of historical prices.

That would mean the contract has to permanently store something like:

```text
Price₀

Price₁

Price₂

Price₃

...

Price₅₀₀₀₀₀₀
```

This immediately becomes a problem.

## Storage Is Expensive

Ethereum storage is one of the most expensive operations on-chain.

If every swap stored another historical price, then:

* Every swap would perform another storage write.
* Contract storage would continue growing forever.
* Gas costs would become extremely expensive.

Millions of swaps would eventually produce millions of stored prices.

Clearly, this is not a practical solution.

## Functions Cannot Magically Recreate History

One might think:

> "Maybe a function can simply calculate the old prices whenever we need them."

Unfortunately, this is impossible.

A Solidity function can only work with the information currently stored inside the contract.

If the contract never stored the historical prices, then no function can magically reconstruct them years later.

History that was never recorded is gone.

## The Better Approach

Instead of storing every historical price, Uniswap stores **one number** that continuously grows over time.

Think of the two possible approaches.

### Option A

Store every historical price forever.

```text
Price₀

Price₁

Price₂

Price₃

...

Price₅₀₀₀₀₀₀
```

### Option B

Store only one number that keeps increasing.

```text
Running Total
```

Uniswap chooses **Option B**.

This single running total is called the **Cumulative Price**.

Instead of remembering every individual historical price, Uniswap continuously accumulates each price's contribution into one ever-increasing value.

This idea dramatically reduces storage usage while still allowing TWAP calculations later.

In the next section, we'll see exactly how this running total is built and why it contains all the information required to compute a Time-Weighted Average Price.
