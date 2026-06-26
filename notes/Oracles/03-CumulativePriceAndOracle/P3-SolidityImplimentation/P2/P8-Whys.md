### 3.2.1.8 Why `+=`? Why Doesn't Uniswap Calculate The TWAP Directly?

After understanding how Uniswap calculates the fixed-point price,

another question naturally appeared.

The final line is:

```solidity
price0CumulativeLast +=
    currentPrice * timeElapsed;
```

Why:

```solidity
+=
```

instead of:

```solidity
=
```

Wouldn't storing the newest value always keep us updated?

---

#### First Thought

Initially,

it seemed much simpler to write:

```solidity
price0CumulativeLast =
    currentPrice * timeElapsed;
```

After all,

that always stores the latest information.

So why keep adding forever?

---

#### Discussion

The answer is simple.

Uniswap isn't interested in remembering **only the latest price**.

It wants to remember **every price that has ever existed**, together with **how long that price existed**.

Every update adds another piece of history.

Conceptually,

```text
Current Contribution

=

Price

×

Time Elapsed
```

Instead of replacing history,

Uniswap appends new history.

```text
Previous History

+

New History

=

Updated History
```

That is exactly what:

```solidity
+=
```

does.

---

#### Live Example

Suppose the pool behaves like this.

| Time | Price | Duration |
|------|-------|----------|
| 0s   | 2     | 10s      |
| 10s  | 4     | 10s      |
| 20s  | 6     | 10s      |

Initially,

```text
price0CumulativeLast = 0
```

---

After the first interval,

```text
0

+

(2 × 10)

=

20
```

Now,

```text
price0CumulativeLast = 20
```

---

After the second interval,

```text
20

+

(4 × 10)

=

60
```

Now,

```text
price0CumulativeLast = 60
```

---

After the third interval,

```text
60

+

(6 × 10)

=

120
```

Now,

```text
price0CumulativeLast = 120
```

Notice something important.

The cumulative value never decreases.

It only keeps growing.

---

#### Biggest Realization

The Pair contract is **not** storing every historical price.

Instead,

it stores one continuously increasing accumulator.

Conceptually,

```text
0

↓

20

↓

60

↓

120

↓

180

↓

...
```

Every update simply pushes the accumulator further forward.

---

#### Another Question

If the Pair contract only stores:

```text
120
```

how can anyone later calculate:

> "What was the average price between 10 seconds and 30 seconds?"

The Pair contract no longer remembers:

```text
20

or

60
```

Those values have already been replaced.

Initially,

this felt impossible.

---

#### Discussion

This was one of the biggest realizations during our discussion.

The Pair contract **does not calculate TWAP.**

Instead,

it continuously provides the raw data required to calculate a TWAP.

Someone else must remember earlier observations.

---

#### Who Calculates The TWAP?

Initially,

it is very easy to assume:

> Uniswap calculates the TWAP.

It doesn't.

Uniswap only maintains:

```text
Running Cumulative Price
```

Protocols such as:

- Aave
- Lending protocols
- Other DeFi applications
- Oracle consumers

take snapshots whenever they want.

---

#### Snapshot Example

Suppose a protocol wants a

```text
30 Minute TWAP.
```

At

```text
12:00
```

it reads:

```text
price0CumulativeLast

=

1,500,000
```

and stores it.

Later,

at

```text
12:30
```

it reads again.

```text
price0CumulativeLast

=

1,650,000
```

Now the protocol has two observations.

```text
Start

=

1,500,000

End

=

1,650,000
```

It computes

```text
ΔCumulative

=

1,650,000

−

1,500,000

=

150,000
```

Then

```text
TWAP

=

ΔCumulative

────────────

ΔTime
```

Notice something important.

Uniswap never performed that calculation.

The external protocol did.

---

#### Another Question

During our discussion we asked something important.

> What if Aave forgets to take the first snapshot?

Suppose it only knows

```text
price0CumulativeLast

=

1,650,000
```

Can it still calculate the TWAP?

No.

It only knows:

```text
End Value
```

It has no idea what the cumulative value was

30 minutes earlier.

Without:

```text
Start Snapshot
```

there is no

```text
ΔCumulative
```

Without:

```text
ΔCumulative
```

there is no TWAP.

---

#### Example

Suppose the accumulator currently shows:

```text
1,000,000
```

Someone asks:

> What was the average price during the previous hour?

Impossible.

Why?

Because we don't know whether one hour ago the accumulator was:

```text
900,000
```

or

```text
950,000
```

or

```text
999,000
```

The current cumulative value alone is insufficient.

The protocol must have remembered an earlier observation.

---

#### Another Realization

The Pair contract stores only:

```text
Current Running Total
```

It does **not** store:

- Every historical price.
- Every historical cumulative value.
- Every historical timestamp.

Those are the responsibility of whoever consumes the oracle.

---

#### Odometer Analogy

During our discussion,

the best analogy turned out to be a car's odometer.

Suppose your car currently displays:

```text
15,842 km
```

Can someone determine how far you drove yesterday?

No.

They first need yesterday's reading.

Suppose yesterday it displayed:

```text
15,622 km
```

Now,

```text
15,842

−

15,622

=

220 km
```

Exactly the same idea applies here.

The Pair contract continuously exposes the latest cumulative value.

Consumers compare two observations to determine what happened during the interval between them.

---

#### Final Mental Model

```text
Pool Updates

↓

Current Price

↓

Price × Time

↓

Running Cumulative Value

↓

External Protocol Takes Snapshot

↓

Wait

↓

Take Another Snapshot

↓

ΔCumulative

÷

ΔTime

↓

TWAP
```

---

#### Biggest Realization

One of the biggest misconceptions we had at the beginning was believing:

> Uniswap computes the TWAP.

That isn't how the system works.

Uniswap continuously maintains a running cumulative price.

It is the responsibility of external protocols to:

- decide which interval they care about,
- store the required snapshots,
- subtract the cumulative values,
- divide by elapsed time,
- and finally compute the TWAP.

The Pair contract provides the raw ingredients.

The consumer performs the final calculation.