### 3.2.2 `price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;`

```solidity
price1CumulativeLast +=
    uint(
        UQ112x112.encode(_reserve0).uqdiv(_reserve1)
    ) * timeElapsed;
```

After spending a significant amount of time understanding:

```solidity
price0CumulativeLast +=
    uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0))
    * timeElapsed;
```

the next line suddenly looked much less intimidating.

At first glance, it appears to repeat almost the exact same logic.

Naturally, our first question became:

> Are we really doing everything again?

---

#### First Observation

Comparing both lines:

```solidity
price0CumulativeLast +=
    uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0))
    * timeElapsed;
```

and

```solidity
price1CumulativeLast +=
    uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1))
    * timeElapsed;
```

the only difference is:

```text
reserve0

↓

reserve1

and

reserve1

↓

reserve0
```

Everything else is identical.

---

#### Question

Why maintain two cumulative prices?

Wouldn't one be enough?

---

#### Discussion

The first accumulator stores:

```text
Token1

────────

Token0
```

which answers:

> "How many Token1 units is one Token0 worth?"

The second accumulator stores:

```text
Token0

────────

Token1
```

which answers:

> "How many Token0 units is one Token1 worth?"

These are inverse prices.

Both are useful because different protocols may want to price different assets.

---

#### Example

Suppose the pool contains:

```text
10 ETH

20,000 USDC
```

One accumulator records:

```text
USDC

────

ETH

=

2,000
```

The other records:

```text
ETH

──────

USDC

=

0.0005
```

Both describe the same exchange rate,

but from opposite perspectives.

---

#### Realization

Everything discussed in the previous subsection still applies.

- Same fixed-point arithmetic.
- Same encoding.
- Same division.
- Same multiplication by time.
- Same cumulative accounting.

Only the direction of the price changes.

Rather than repeating the entire discussion, this line simply mirrors the previous one.

---

### 3.2.3 `reserve0 = uint112(balance0);`

```solidity
reserve0 = uint112(balance0);
```

At first,

this line looks almost trivial.

Simply copy one variable into another.

However,

after our earlier discussion,

another question immediately appeared.

---

#### Question

Why cast again?

Didn't we already verify earlier that:

```solidity
balance0 <= uint112(-1)
```

Why perform another conversion?

---

#### Discussion

Earlier,

the overflow check only **verified** that the conversion is safe.

It did **not** actually perform the conversion.

This line finally performs it.

Conceptually,

earlier we asked:

> "Can this value fit?"

Now we actually say:

> "Store it."

---

#### Mental Model

Think of the first line as checking whether a box is large enough.

```text
Can It Fit?

↓

Yes
```

Only after that do we actually place the object inside.

```text
Put It In The Box
```

That is exactly what happens here.

---

#### Another Question

Why not simply store:

```solidity
uint256 reserve0;
```

and avoid casting altogether?

---

#### Discussion

We already answered this earlier.

Uniswap intentionally stores:

```text
reserve0

reserve1

blockTimestampLast
```

inside a single storage slot.

```text
112

+

112

+

32

=

256 Bits
```

Using:

```solidity
uint256 reserve0;
```

would destroy this storage packing,

increasing gas costs forever.

---

#### Biggest Realization

Notice something important.

Before this line,

the Pair contract's reserves still represent the **old** state.

```text
Reserves

=

Old Reality
```

Meanwhile,

```text
balance0
```

already represents the **new** state after the swap.

This line synchronizes them.

Conceptually,

```text
Old Reserve

↓

Current Balance

↓

New Reserve
```

The Pair finally updates its memory to match reality.

---

### 3.2.4 `reserve1 = uint112(balance1);`

```solidity
reserve1 = uint112(balance1);
```

Everything discussed for:

```solidity
reserve0
```

applies here as well.

The Pair simply synchronizes the second reserve.

After both assignments,

the Pair's remembered reserves now exactly match its actual token balances.

At this point,

the reserve synchronization is complete.

---

### 3.2.5 `blockTimestampLast = blockTimestamp;`

```solidity
blockTimestampLast = blockTimestamp;
```

At first,

this line also seems extremely simple.

However,

its placement is very intentional.

---

#### Question

Why update the timestamp **last**?

Why not update it immediately after calculating:

```solidity
timeElapsed
```

---

#### Discussion

Remember,

earlier we computed:

```solidity
timeElapsed =
blockTimestamp -
blockTimestampLast;
```

That calculation depended on the **old** timestamp.

Only after finishing every oracle update can we safely replace it.

Conceptually,

```text
Old Timestamp

↓

Calculate Elapsed Time

↓

Update Oracle

↓

Store New Timestamp
```

If we overwrote the timestamp earlier,

we would lose the reference point needed for the oracle calculations.

---

#### Mental Model

Think of starting and stopping a stopwatch.

You first calculate:

```text
Finish

−

Start
```

Only after recording the elapsed time do you reset the stopwatch for the next race.

That is exactly what this line does.

It prepares `_update()` for the next interaction.

---

### 3.2.6 `emit Sync(reserve0, reserve1);`

```solidity
emit Sync(reserve0, reserve1);
```

This is the final line inside `_update()`.

Unlike every previous statement,

this line does **not** modify contract storage.

Instead,

it broadcasts information to the outside world.

---

#### Question

Why emit an event?

Why not simply let external applications read the reserves directly?

---

#### Discussion

They certainly can.

However,

continuously reading blockchain storage is expensive and inconvenient.

Instead,

frontends,

indexers,

analytics platforms,

and other applications simply listen for:

```text
Sync
```

events.

Whenever reserves change,

they immediately receive a notification.

---

#### Examples

Applications that commonly listen for these events include:

- Blockchain explorers
- Portfolio trackers
- DEX analytics dashboards
- Indexers such as The Graph
- Trading bots
- Arbitrage bots

Rather than repeatedly asking:

> "Have the reserves changed yet?"

they receive an event the moment synchronization occurs.

---

#### Important Observation

Events are **logs**.

They are **not** contract storage.

Emitting an event does **not** change the Pair's state.

The state was already updated by the previous assignments.

The event merely announces:

> "Synchronization has completed."

---

#### Final Mental Model

Think of `_update()` as the Pair finishing its bookkeeping.

```text
Swap Happens

↓

Balances Change

↓

Verify Balances Fit uint112

↓

Calculate Time Elapsed

↓

Update Oracle

↓

Synchronize reserve0

↓

Synchronize reserve1

↓

Save Timestamp

↓

Announce Synchronization (Sync Event)

↓

Ready For Next Interaction
```

---

## `_update()` Final Realization

At the beginning of this chapter,

we assumed `_update()` simply copied balances into reserves.

After dissecting every line,

we discovered it performs far more than that.

`_update()` is responsible for:

- Verifying reserve values safely fit into storage.
- Maintaining Uniswap's cumulative price oracle.
- Recording elapsed time.
- Synchronizing reserves with actual balances.
- Saving the new timestamp.
- Broadcasting the update through an event.

In other words,

`_update()` is not merely a reserve update function.

It is the function that commits the Pair contract's new state, maintains its on-chain oracle, and prepares the pool for the next interaction.