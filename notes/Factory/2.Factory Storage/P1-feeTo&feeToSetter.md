# 2.1 feeTo & feeToSetter

```solidity
address public feeTo;
address public feeToSetter;
```

## Mental Model Before Reading

Unlike the Pair contract, the Factory does **not** perform swaps.

It does **not** hold liquidity.

It does **not** update reserves.

It does **not** calculate prices.

Instead, think of the Factory as the protocol's **global control center**.

```text
Factory

↓

Global Configuration

↓

Deploy Pair Contracts

↓

Store Pair Registry

↓

Governance

↓

Every Pair Reads From It
```

These two variables are the first example of that philosophy.

---

## First Thought

At first glance these look like two ordinary addresses.

```solidity
address public feeTo;
address public feeToSetter;
```

Nothing complicated.

Just two storage variables.

However, they actually represent two completely different responsibilities.

One receives protocol fees.

The other controls who receives those protocol fees.

Understanding why these responsibilities are separated is one of the Factory's first architectural decisions.

---

# feeTo

```solidity
address public feeTo;
```

## What Is It?

`feeTo` simply stores an Ethereum address.

For example:

```text
feeTo

↓

0x7A3F...
```

Nothing more.

The important question is:

**Whose address is this?**

It stores the address that should receive **Uniswap Protocol Fees**.

---

## Important Clarification

When most people hear:

> Uniswap charges a **0.3% fee**

they usually assume:

```text
0.3%

↓

Uniswap
```

That is **not** how Uniswap V2 works.

Normally:

```text
Swap

↓

0.3% Fee

↓

Liquidity Providers (LPs)
```

Not:

```text
Swap

↓

feeTo
```

`feeTo` is only used when **protocol fees are enabled**.

The exact mechanism is implemented inside `_mintFee()` and will be covered in detail later.

For now, simply think of `feeTo` as:

```text
Global Protocol Fee Recipient
```

---

## First Question

Why is `feeTo` stored inside the Factory?

The Pair is where:

```text
✓ Swaps happen

✓ Liquidity lives

✓ Reserves are updated

✓ Prices are calculated
```

The Factory does none of those things.

So why doesn't every Pair simply store:

```solidity
address public feeTo;
```

instead?

---

## Alternative Design

Suppose every Pair stored its own fee recipient.

Would it work?

Yes.

Would it be a good design?

Not really.

Imagine Uniswap has:

```text
50,000 Pair Contracts
```

Now every Pair stores:

```text
reserve0

reserve1

...

feeTo
```

again...

and again...

and again...

```text
50,000 Copies
```

Instead, Uniswap stores:

```text
1 Copy

↓

Factory

↓

Every Pair Reads It
```

Immediately we reduce duplicated storage.

---

## Governance

Now imagine governance decides:

```text
Treasury A

↓

Treasury B
```

If every Pair stored its own `feeTo`, governance would need to update thousands of contracts.

Instead:

```text
Factory

↓

Update Once

↓

Every Pair Immediately Uses
The New Address
```

One storage write.

Done.

---

## Single Source Of Truth

Another advantage is consistency.

Instead of every Pair deciding its own fee recipient:

```text
Pair A

↓

Treasury A

--------------------

Pair B

↓

Treasury B

--------------------

Pair C

↓

Treasury C
```

Every Pair simply asks:

```text
Factory

↓

Who receives protocol fees?
```

The Factory becomes the protocol's **single source of truth**.

---

## Why Is It An Address?

Eventually someone must receive protocol fees.

That recipient could be:

```text
Treasury Wallet

↓

DAO Treasury

↓

Multisig

↓

Governance Contract

↓

Any Ethereum Address
```

Instead of hardcoding the destination,

Uniswap stores it as an address.

---

## One Variable, Two Jobs

A very elegant design choice appears here.

Initially you might expect something like:

```solidity
bool protocolFeeEnabled;

address feeRecipient;
```

Two variables.

Instead Uniswap uses only one.

```text
feeTo == address(0)

↓

Protocol Fee Disabled

-------------------------

feeTo != address(0)

↓

Protocol Fee Enabled
```

The address itself becomes the switch.

---

# feeToSetter

```solidity
address public feeToSetter;
```

## First Thought

This looks almost identical.

Another address.

But it has an entirely different purpose.

It does **not** receive protocol fees.

Instead, it controls protocol configuration.

---

## First Question

Who should be allowed to change:

```text
feeTo
```

Should anyone call:

```solidity
setFeeTo(...)
```

Obviously not.

Otherwise anyone could redirect protocol fees to themselves.

There must be an administrator.

That administrator is:

```text
feeToSetter
```

---

## Why Not Let feeTo Change Itself?

Initially this sounded reasonable.

Suppose:

```text
feeTo

↓

Treasury Wallet
```

Why not let that address update itself?

During our discussion we discovered this mixes two completely different responsibilities.

Receiving protocol fees

≠

Managing protocol governance.

Those are separate concerns.

---

## Important Discovery

Changing:

```text
feeTo
```

does **NOT** change:

```text
feeToSetter
```

They are completely independent storage variables.

Example:

Initially:

```text
feeTo

↓

Treasury A

--------------------

feeToSetter

↓

Admin
```

Later:

```solidity
setFeeTo(TreasuryB);
```

Result:

```text
feeTo

↓

Treasury B

--------------------

feeToSetter

↓

Admin
```

Only the recipient changed.

The administrator remained exactly the same.

---

## Can They Be The Same Address?

Yes.

Suppose both are:

```text
0xABC...
```

That is perfectly valid.

The address now has two responsibilities.

```text
Receive Protocol Fees

+

Manage Protocol Configuration
```

Nothing breaks.

The variables remain completely independent.

---

## Then Why Separate Them?

Because they represent different roles.

```text
feeTo

↓

Economic Role

------------------------

feeToSetter

↓

Administrative Role
```

Sometimes those roles belong to the same entity.

Sometimes they do not.

For example:

```text
feeTo

↓

Treasury Multisig

------------------------

feeToSetter

↓

DAO Timelock
```

The treasury receives protocol fees.

The DAO decides whether that treasury should change.

Separating responsibilities gives governance much greater flexibility.

---

## Child Analogy

Imagine a company.

```text
Company

↓

CEO

↓

Chooses Payroll Account

-------------------------

Employees

↓

Receive Salary
```

Receiving money does **not** mean you should control company payroll.

Likewise,

receiving protocol fees does **not** automatically mean controlling protocol governance.

---

## Mental Model

```text
feeTo

↓

Economic Role

Receives Protocol Fees

--------------------------------

feeToSetter

↓

Administrative Role

Controls Protocol Configuration
```

One receives value.

The other controls the protocol.

---

## Final Realization

Although these appear to be two simple address variables, they establish one of the Factory's most important architectural principles.

The Factory acts as the protocol's global configuration layer.

Rather than duplicating administrative state across thousands of Pair contracts, Uniswap stores a single global configuration inside the Factory.

Every Pair reads from that single source of truth.

By separating the protocol fee recipient (`feeTo`) from the protocol administrator (`feeToSetter`), Uniswap also separates **economic responsibility** from **governance responsibility**, making the system simpler, more efficient, and significantly easier to manage.