### Part 1.6 — Historical Snapshots, Where Did `n-1` Go, And Why The Pair Alone Cannot Answer Old TWAP Queries

At this point, we've discovered one of the biggest ideas behind the Uniswap V2 oracle.

Instead of storing every historical price,

Uniswap continuously builds one running total called the **Cumulative Price**.

We also discovered something amazing.

```text
Cₙ - Cₖ
```

automatically gives us the exact numerator we wanted.

Earlier we derived the TWAP numerator as

```text
Σ(ΔT × Price)
```

Now we've realized

```text
Σ(ΔT × Price)

=

Cₙ - Cₖ
```

This is not a new equation.

It is simply another way of writing exactly the same thing.

---

# A Natural Question

At this point, one question naturally comes to mind.

> If Uniswap only stores one cumulative value, can I ask:

> "What was the TWAP between 4:00 AM and 5:00 AM two years ago?"

Unfortunately,

**No.**

Not by using the Pair contract alone.

---

# Why Can't The Pair Answer That?

Suppose today is

```text
2026
```

and you ask

> "What was the TWAP from 4:00 AM to 5:00 AM on January 15, 2024?"

Can the Pair answer?

No.

Why?

Because although the Pair stores the cumulative price,

it only stores the **latest** cumulative value.

It does **not** store every previous cumulative value.

For example, it does NOT store

```text
Yesterday's cumulative price

Last week's cumulative price

Last month's cumulative price

Last year's cumulative price
```

Those historical cumulative values are gone unless somebody recorded them.

---

# Child Analogy — Your Bank Balance

Imagine opening your banking app.

It shows

```text
Current Balance

₹150,000
```

Question.

Can you determine exactly how much money you had

```text
2 years ago

at

4:00 PM
```

Just from today's balance?

No.

You would have needed a bank statement from that time.

Exactly the same thing happens with cumulative prices.

The Pair only knows the **current total.**

It does not remember every previous total.

---

# Another Analogy — A Car's Odometer

Imagine your car's odometer shows

```text
150,000 km
```

Question.

Can you determine how many kilometers you drove

between

```text
2:00 PM

and

3:00 PM

last Tuesday?
```

No.

Unless you had written down

```text
2:00 PM

↓

149,800 km
```

and

```text
3:00 PM

↓

149,860 km
```

Then you could simply subtract

```text
149,860

-

149,800

=

60 km
```

The cumulative price works exactly like an odometer.

It continuously increases.

If you want history,

someone must periodically record snapshots.

---

# So Who Stores Historical Snapshots?

The Pair contract does **not**.

Instead,

another contract,

automation,

or an off-chain backend periodically records them.

For example,

```text
9:00

↓

Read Pair

↓

Store Snapshot
```

Later,

```text
10:00

↓

Read Pair

↓

Store Snapshot
```

Later,

```text
11:00

↓

Read Pair

↓

Store Snapshot
```

Now,

if someone asks

> "What is the TWAP between 9:00 and 11:00?"

The oracle simply computes

```text
(Cumulative₁₁

-

Cumulative₉)

/

(Time₁₁

-

Time₉)
```

Done.

---

# Does The Pair Decide When To Store Snapshots?

No.

The Pair never wakes itself up.

It never says

> "It's 10:00 AM. Let me store a snapshot."

Smart contracts cannot execute by themselves.

They only run when someone sends them a transaction.

This is exactly the same reason why Uniswap doesn't continuously update reserves.

Something external must interact with the contract.

---

# Who Can Trigger Snapshot Storage?

Many different systems can do this.

For example,

### Another Smart Contract

A lending protocol could periodically call

```solidity
saveSnapshot();
```

which internally reads

```solidity
pair.price0CumulativeLast();
```

and stores the value.

---

### Automation Services

Examples include

* Chainlink Automation
* Gelato
* OpenZeppelin Defender

These services periodically submit transactions on behalf of the protocol.

---

### Off-Chain Servers

A backend server can simply run

```text
Every Hour

↓

Read Pair

↓

Store Snapshot
```

Very common.

---

# Do All Protocols Store Snapshots At The Same Frequency?

No.

There is no fixed rule.

Some protocols may record

```text
Every minute.
```

Others may choose

```text
Every 5 minutes.
```

or

```text
Every hour.
```

or even

```text
Once per day.
```

It depends entirely on:

* The desired oracle accuracy.
* The amount of gas the protocol is willing to spend.

More snapshots generally produce more flexible and more frequently updated TWAP observations,

but they also require more storage.

---

# Where Did The `n-1` Go?

Earlier,

our TWAP numerator was written as

```text
             n−1
             Σ
i = k
ΔTᵢPᵢ
```

Notice that the summation stopped at

```text
n−1
```

Later,

we replaced the numerator with

```text
Cₙ - Cₖ
```

A natural question is:

> "Where did the `n−1` go?"

The answer is:

**It never disappeared.**

It is already built into the definition of

```text
Cₙ
```

Remember,

by definition

```text
             n−1
Cₙ = Σ ΔTᵢPᵢ
      i=0
```

which expands to

```text
ΔT₀P₀

+

ΔT₁P₁

+

...

+

ΔTₙ₋₁Pₙ₋₁
```

Notice that the final term is already

```text
ΔTₙ₋₁Pₙ₋₁
```

The upper limit

```text
n−1
```

is already inside the definition of

```text
Cₙ.
```

That is why we no longer write it separately.

---

# Think Of It Like A Variable

Suppose we define

```text
A

=

1 + 2 + 3 + 4 + 5
```

Later,

we write

```text
A - 3
```

Do we rewrite

```text
1 + 2 + 3 + 4 + 5
```

again?

No.

The variable

```text
A
```

already represents the entire expression.

Exactly the same thing happens here.

The summation hasn't disappeared.

It has simply been replaced by its variable name:

```text
Cₙ
```

---

# Part 1 Summary

At this point we have answered several important questions.

✅ Why doesn't Uniswap store every historical price?

✅ Why is storing every price expensive?

✅ What is a cumulative price?

✅ What does the letter `C` mean?

✅ Why does `C₀` start at zero?

✅ Why can't we immediately calculate `Price × Time`?

✅ Why does Uniswap wait until the next reserve update?

✅ Why doesn't it continuously update?

✅ Why does the cumulative value continuously grow?

✅ Why does subtracting two cumulative values automatically remove old history?

✅ Why does

```text
Cₙ - Cₖ
```

produce the exact numerator required for TWAP?

✅ Why can't the Pair answer historical TWAP queries by itself?

✅ Who stores historical snapshots?

✅ Where did the `n−1` go?

Everything we've learned so far has been **intuition**.

In the next part,

we'll move from intuition to formal mathematics.

We'll formally define

```text
             j−1
Cⱼ = Σ ΔTᵢPᵢ
      i=0
```

prove mathematically why

```text
Cₙ - Cₖ
```

works,

derive the complete TWAP equation,

and finally solve the full numerical example from the Uniswap documentation.
