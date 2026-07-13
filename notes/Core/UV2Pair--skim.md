# `skim()` — Recovering Extra Tokens

Unlike `mint()`, `burn()`, or `swap()`, the `skim()` function is **not**
part of Uniswap's normal liquidity workflow.

It exists for a very specific edge case.

Sometimes the Pair contract may accidentally receive more tokens than
its reserves record.

`skim()` simply removes those extra tokens.

---

# The Function

```solidity
function skim(address to) external lock {
    address _token0 = token0;
    address _token1 = token1;

    _safeTransfer(
        _token0,
        to,
        IERC20(_token0).balanceOf(address(this)) - reserve0
    );

    _safeTransfer(
        _token1,
        to,
        IERC20(_token1).balanceOf(address(this)) - reserve1
    );
}
```

---

# What Does `skim()` Do?

In one sentence:

> **`skim()` transfers any tokens that exist above the recorded reserves
> to a specified address.**

Notice the important words:

```text
Above The Recorded Reserves
```

It does **not** calculate LP ownership.

It does **not** mint LP tokens.

It does **not** update reserves.

It simply removes any excess tokens.

---

# Understanding The Difference Between Balances And Reserves

Suppose the Pair currently has:

```text
Reserves

100 ETH

200,000 USDC
```

Normally the Pair should also physically contain:

```text
Balances

100 ETH

200,000 USDC
```

Everything matches.

---

# Someone Accidentally Transfers Tokens

Now suppose Bob accidentally sends:

```solidity
USDC.transfer(pair, 5_000);
```

He does **not** use the Router.

He does **not** call:

- `mint()`
- `swap()`
- `sync()`

He simply transfers tokens directly.

Now the Pair physically owns:

```text
Balances

100 ETH

205,000 USDC
```

But the reserves are still:

```text
Reserves

100 ETH

200,000 USDC
```

There are now:

```text
5,000 Extra USDC
```

inside the Pair.

---

# How Does `skim()` Find The Extra Tokens?

The function simply calculates:

```text
balance

-

reserve
```

For Token0:

```text
100

-

100

=

0
```

For Token1:

```text
205,000

-

200,000

=

5,000
```

Only the extra amount is transferred.

Afterwards:

```text
Balances

100 ETH

200,000 USDC

=

Reserves
```

Everything matches again.

---

# Child Analogy

Imagine your toy box is supposed to contain:

```text
10 Toys
```

One day your friend accidentally drops:

```text
2 More Toys
```

inside your toy box.

Now:

```text
Actual Toys

12

----------------

Expected Toys

10
```

Your mom says:

> "Take the extra two toys out."

She doesn't empty the box.

She removes **only** the extras.

That is exactly what `skim()` does.

---

# Why Does This Function Exist?

ERC-20 tokens can always be transferred directly.

Anyone can execute:

```solidity
token.transfer(pair, amount);
```

The Pair cannot prevent that transfer.

Sometimes those transfers are:

- accidental,
- mistaken,
- dust,
- leftovers,
- unexpected token transfers.

`skim()` simply cleans up those extra tokens.

---

# Doesn't Those Extra Tokens Benefit LPs?

This is an excellent question.

At first it seems like they should.

Suppose:

```text
Reserves

100 ETH

200,000 USDC
```

Someone accidentally sends:

```text
5,000 USDC
```

Now the Pair physically owns:

```text
Balances

100 ETH

205,000 USDC
```

The Pair is physically richer.

However...

Uniswap does **not** immediately consider those extra tokens part of the
liquidity pool.

Why?

Because nobody:

- added liquidity,
- minted LP tokens,
- updated the reserves.

Liquidity is represented by:

```text
LP Tokens

+

Recorded Reserves
```

Not simply by whatever tokens happen to sit inside the contract.

---

# What Happens If Nobody Calls `skim()`?

Nothing.

The extra tokens simply remain inside the Pair.

For example:

```text
Balances

100 ETH

205,000 USDC

Reserves

100 ETH

200,000 USDC
```

The extra:

```text
5,000 USDC
```

continues sitting inside the Pair.

---

# Can Anyone Take Those Extra Tokens?

Yes.

Suppose Alex calls:

```solidity
pair.skim(alex);
```

The Pair calculates:

```text
205,000

-

200,000

=

5,000 USDC
```

Then executes:

```solidity
_safeTransfer(token1, alex, 5000);
```

Alex receives:

```text
5,000 USDC
```

Notice something important.

Alex:

- does **not** need LP tokens,
- does **not** need to be a Liquidity Provider,
- does **not** need any ownership of the pool.

Anyone can call:

```solidity
skim(anyAddress);
```

---

# Is Alex Stealing?

Not really.

Those tokens were never recognized as liquidity.

Nobody:

- added liquidity,
- minted LP tokens,
- updated the reserves.

From Uniswap's perspective, they are simply excess tokens sitting inside
the Pair.

---

# Why Doesn't The Pair Return Them To Bob?

Because the Pair has no idea who accidentally sent them.

It only knows:

```text
Current Balance

Current Reserve
```

It does **not** know:

```text
Who Sent The Extra Tokens?
```

So it cannot automatically refund the sender.

Instead, `skim()` simply transfers the excess to whatever address the
caller specifies.

---

# What If Someone Calls `sync()` Instead?

This is the biggest difference between `skim()` and `sync()`.

Suppose someone accidentally sends:

```text
5,000 USDC
```

Now there are two possible futures.

---

## Future 1 — Someone Calls `skim()`

```text
Extra Tokens

↓

Transferred Away

↓

Balances

=

Reserves
```

The pool returns to its original state.

LPs receive **no benefit**.

---

## Future 2 — Someone Calls `sync()`

`sync()` updates the reserves.

```text
Reserves

↓

205,000 USDC
```

Now the extra tokens become the official pool state.

If someone later calls:

```text
skim()
```

the calculation becomes:

```text
balance

-

reserve

↓

205,000

-

205,000

=

0
```

There are no extra tokens left.

The donation has now permanently increased the pool's reserves.

All Liquidity Providers benefit from those additional assets.

---

# The Biggest Difference

`skim()` trusts the reserves.

It says:

> **"The reserves are correct. Remove anything above them."**

`sync()` trusts the balances.

It says:

> **"The balances are correct. Update the reserves to match them."**

This is the easiest way to remember the difference.

---

# Child Analogy

Imagine a donation box that is supposed to contain exactly:

```text
100 Marbles
```

Someone accidentally drops:

```text
10 More Marbles
```

inside.

Now there are:

```text
110 Marbles
```

Two things can happen.

### Option 1 — `skim()`

Someone removes the extra:

```text
10 Marbles
```

The box returns to:

```text
100 Marbles
```

---

### Option 2 — `sync()`

The manager updates the official inventory.

Now the official count becomes:

```text
110 Marbles
```

Those extra marbles now officially belong to the box forever.

---

# Summary

`skim()` is a rarely used utility function.

It is **not** called by:

- `mint()`
- `burn()`
- `swap()`
- any Router function.

Instead, it exists to recover tokens that were transferred directly to
the Pair without becoming official liquidity.

Its entire job is simply:

```text
Extra Tokens Exist

↓

Transfer Only The Extras

↓

Balances

=

Reserves
```

Unlike `sync()`, `skim()` never updates the reserves.

It trusts the recorded reserves and removes any excess tokens until the
Pair's balances once again match the stored reserve snapshot.