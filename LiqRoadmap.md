# Liq Bitch

# Part I — Conceptual & Mathematical Foundations

> Understand **why** Uniswap V2 liquidity works before reading any Solidity.

```text
1. What is Liquidity?

↓

2. Liquidity Providers (LPs)

↓

3. Pool Shares (Single Asset)

↓

4. Mint Share Formula

↓

5. Burn Share Formula

↓

6. Why Uniswap Needs Two Tokens

↓

7. Why Deposits Must Preserve Price
   (dy/dx = y/x)

↓

8. What Is Liquidity?
   (F(x, y))

↓

9. Why √(xy)?
   (Pool Value)

↓

10. Uniswap LP Share Formula
```

---

# Part II — Code / Implementation

> Understand **how** Uniswap V2 implements everything learned in Part I.

```text
11. Contract Call Flow

↓

12. Router._addLiquidity()

↓

13. Router.addLiquidity()

↓

14. Router.addLiquidityETH()

↓

15. Pair.mint()

↓

16. _mintFee()

↓

17. Pair.burn()

↓

18. Router.removeLiquidity()

↓

19. Router.removeLiquidityETH()

↓

20. Permit Variants
(if present in our implementation)
```

---

# Workflow

For every **main section**:

- Start with the intuition.
- Discuss naturally.
- Questions and confusions drive the discussion.
- **Do not predefine subsections.**
- Let subsections emerge naturally during the discussion (e.g., `1.1`, `1.2`, etc.).
- Do not move to the next main section until the current one is fully understood.
- After completing a main section, generate **one comprehensive `.md`** containing:
  - Complete conceptual explanation.
  - Our entire discussion.
  - Every important question and confusion that arose.
  - Detailed answers.
  - Worked examples.
  - Diagrams / execution flows (where useful).
  - Mathematical derivations (only after intuition).
  - Common misconceptions.
  - Connections to previous and upcoming sections.
  - Biggest Realization.

---

# Goal

Build the theory first.

Only after the complete conceptual and mathematical foundation is finished do we move to the Solidity implementation.

The objective is that by the time we read `Router.addLiquidity()` and `Pair.mint()`, every equation and every line of code already makes intuitive sense.