## ensure(deadline)

Child Explanation

Imagine I tell a shop:

"I want to buy this toy, but only if you sell it to me within 5 minutes."

After 5 minutes I don't want the deal anymore.

The deadline is that time limit.

---

Technical Explanation

Users submit transactions to the blockchain.

Transactions may sit in the mempool for some time before being executed.

During that time:

- prices may change
- liquidity may change
- market conditions may change

The deadline ensures the transaction is only valid until a specific timestamp.

Implementation:

require(deadline >= block.timestamp)

If current block time is greater than deadline:

- transaction reverts
- swap does not execute

Protection:

amountOutMin -> protects price

deadline -> protects time

Example:

Current Time:
12:00

User Deadline:
12:05

If mined at:
12:03

Swap executes.

If mined at:
12:06

Swap reverts with EXPIRED.ß