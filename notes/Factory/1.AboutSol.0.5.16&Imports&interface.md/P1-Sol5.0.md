# 1.1 Solidity Version

```solidity
pragma solidity =0.5.16;
```

## First Thought

At first glance, this line appears unimportant.

Most readers immediately skip over it.

However, it provides important historical context.

---

## Discussion

Uniswap V2 was originally written using **Solidity `0.5.16`**, which was the stable compiler version available at the time.

Throughout these notes, we often compare the original implementation with our modern Solidity (0.8+) implementation.

This is important because several language behaviors have changed significantly since Uniswap V2 was released.

---

## Solidity 0.5 vs Solidity 0.8+

Some notable differences include:

* Arithmetic overflow and underflow now revert automatically.
* `unchecked` is required when wraparound behavior is intentionally desired.
* Many SafeMath usages are no longer necessary.
* The language syntax and available features have evolved considerably.

---

## Throughout These Notes

Whenever a Solidity version difference affects Uniswap's implementation, it will be discussed **at the exact line where it matters**, rather than here.

Examples include:

* Timestamp overflow inside `_update()`.
* Arithmetic overflow vs
