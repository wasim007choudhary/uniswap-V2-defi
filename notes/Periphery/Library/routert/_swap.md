# `_swap()` — The Router's Output Routing Engine

```solidity
function _swap(
    uint256[] memory amounts,
    address[] memory path,
    address _to
) internal virtual
```

---

# 🚨 Before Entering `_swap()`

Before dissecting `_swap()`, there is one extremely important fact you must understand:

```text
The first input token has already arrived
at the first Pair.
```

`_swap()` is **NOT** responsible for collecting tokens from the user.

That work was already completed by the Router before `_swap()` was called.

To fully understand how this happens, study:

```text
swapExactTokensForTokens()

swapTokensForExactTokens()

and other Router entry functions
that internally call _swap()
```

In those functions the Router:

```text
1. Calculates expected outputs.

2. Performs slippage checks.

3. Transfers the initial input tokens
   directly to the first Pair.

4. Finally calls _swap().
```

---

Therefore when entering `_swap()` you should assume:

```text
✓ The first Pair already owns the input tokens.

✓ Pair existence has already been verified.

✓ Output amounts have already been calculated.

✓ Slippage checks have passed.

✓ The Router holds no user funds.
```

The only remaining responsibility of `_swap()` is:

```text
"Route outputs through the swap path
until the final recipient receives
the final token."
```

---

# 🧠 Most Important Mental Model

Before entering `_swap()`:

```text
Collection Phase
────────────────────────────

getAmountsOut()

↓

Slippage Checks

↓

safeTransferFrom()

↓

First Pair Funded
```

After all of that:

```text
Execution Phase
────────────────────────────

_swap()
```

---

Another way to think about it:

```text
getAmountsOut()

=
Pricing Engine

--------------------------------

_swap()

=
Routing Engine
```

---

# 🔥 The Big Question

When entering `_swap()` there is only one important question left:

```text
Pair #1 can output WETH.

Where should that WETH go?
```

Should it go to:

```text
Router?

User?

Pair #2?
```

The answer to that question is essentially the entire purpose of `_swap()`.

---

# 🎯 Running Example Used Throughout The Note

Assume:

```text
Path:

[USDC, WETH, LINK]
```

and:

```text
amounts:

[
    1000,
    0.4,
    950
]
```

Meaning:

```text
1000 USDC
        ↓
0.4 WETH
        ↓
950 LINK
```

---

Before `_swap()` starts:

```text
User
    -1000 USDC

USDC/WETH Pair
    +1000 USDC

WETH/LINK Pair
    unchanged

Recipient
    unchanged
```

Most important realization:

```text
The first Pair is already funded.
```

---

# The Loop

```solidity
for (uint256 i; i < path.length - 1; i++)
```

---

## Q: Why `path.length - 1`?

For:

```text
[USDC, WETH, LINK]
```

we have:

```text
3 Tokens 

= 
2 Pairs

=

2 Swaps

=

2 Loop Iterations
```

Visual:

```text
[USDC] → [WETH] → [LINK]
```

Pairs:

```text
USDC/WETH

WETH/LINK
```

There are only:

```text
2
```

adjacent token pairs.

Therefore:

```text
2
```

swaps.

Therefore:

```text
2
```

loop iterations.

Iteration 0:

```text
USDC → WETH
```

Iteration 1:

```text
WETH → LINK
```

The loop stops because:

```text
i < path.length - 1

↓

i < 2
```

Therefore:

```text
0 < 2 ✓

1 < 2 ✓

2 < 2 ✗
```

Stop.

---

# Current Pair Identification

```solidity
(address input, address output) =
    (path[i], path[i + 1]);
```

For:

```text
path = [USDC, WETH, LINK]
```

Iteration 0:

```text
input  = path[0] = USDC

output = path[1] = WETH
```

Current Pair:

```text
USDC/WETH
```

---

Iteration 1:

```text
input  = path[1] = WETH

output = path[2] = LINK
```

Current Pair:

```text
WETH/LINK
```

---

Q:
Why do we use path again?

Didn't getAmountsOut() already use it?

A:

Yes.

But for a different reason.

```text
getAmountsOut()

=
Pricing
```

while:

```text
_swap()

=
Routing
```

Same path.

Different purpose.

---

# Why sortTokens() Again?

```solidity
(address token0,) =
    UniswapV2Library.sortTokens(
        input,
        output
    );
```

Q:

Didn't we already sort tokens inside:

```text
getReserves()
```

and

```text
getAmountsOut()
```

?

A:

Yes.

But that was for reserve ordering.

This time:

```text
NOT
```

for reserves.

This time we need to prepare for:

```solidity
Pair.swap(
    amount0Out,
    amount1Out,
    ...
)
```

because Pair understands:

```text
token0
token1
```

not:

```text
input
output
```

---

Mental Model:

```text
Router Language

input
output

↓

Pair Language

token0
token1
```

This section acts as a translation layer.

---

Q:

Are we basically making the Pair understand our language?

A:

Yes.

Exactly.

Router thinks in:

```text
USDC → WETH
```

Pair thinks in:

```text
token1 → token0
```

or

```text
token0 → token1
```

depending on ordering.

---

# amountOut

```solidity
uint256 amountOut =
    amounts[i + 1];
```

Q:

Why:

```text
amounts[i + 1]
```

?

A:

Because getAmountsOut() already calculated every output before _swap() started.

_swap() is not calculating outputs.

It is reading outputs.

---

Example:

```text
amounts

[
    1000,
    0.4,
    950
]
```

Iteration 0:

```text
amountOut

=

amounts[1]

=

0.4 WETH
```

Iteration 1:

```text
amountOut

=

amounts[2]

=

950 LINK
```

---

Q:

Is amounts[0] universally known?

A:

Not exactly.

```text
amounts[0]
```

is known because it comes directly from:

```text
amountIn
```

provided by the user.

All remaining entries were calculated by:

```text
getAmountsOut()
```

---

Mental Model:

```text
amounts[0]

=
User Input

--------------------------------

amounts[1...]

=
Calculated Outputs
```

Therefore:

```solidity
amountOut = amounts[i + 1];
```

means:

```text
Read the answer.

Do not calculate the answer.
```

```

```
# amount0Out / amount1Out Translation Layer

At this point we know:

```text
✓ Current Pair

✓ input token

✓ output token

✓ amountOut
```

What we do NOT know yet is:

```text
How to express that output
in Pair language.
```

---

Remember:

Router thinks in:

```text
input

output
```

Pair thinks in:

```text
token0

token1
```

and:

```text
amount0Out

amount1Out
```

---

The Pair contract does NOT ask:

```text
Which token should leave?
```

Instead it asks:

```text
How much token0 should leave?

How much token1 should leave?
```

---

This is why Router performs a translation.

```solidity
(uint256 amount0Out, uint256 amount1Out) =
    input == token0
        ? (uint256(0), amountOut)
        : (amountOut, uint256(0));
```

---

# The Important Realization

At this point:

```text
We do NOT care
which token came in.
```

We only care about:

```text
Which token must leave.
```

Because Pair.swap() needs:

```text
amount0Out

amount1Out
```

---

# Example

Assume:

```text
input  = USDC

output = WETH

token0 = WETH

token1 = USDC
```

and:

```text
amountOut = 0.4 WETH
```

---

Question:

```text
Which token should leave?
```

Answer:

```text
WETH
```

because:

```text
USDC → WETH
```

means:

```text
USDC enters

WETH leaves
```

---

Since:

```text
WETH == token0
```

we need:

```text
amount0Out = amountOut

amount1Out = 0
```

which becomes:

```text
( amountOut , 0 )
```

---

# Why The Condition Uses input == token0

Many people expect:

```solidity
output == token0
```

instead of:

```solidity
input == token0
```

---

But remember:

If:

```text
input = token0
```

then:

```text
output = token1
```

must be true.

---

And if:

```text
input = token1
```

then:

```text
output = token0
```

must be true.

---

Therefore checking:

```solidity
input == token0
```

automatically tells us which output token exists.

---

# Visual Example #1

Assume:

```text
token0 = WETH

token1 = USDC

USDC → WETH
```

Therefore:

```text
input  = token1

output = token0
```

Condition:

```text
input == token0
```

becomes:

```text
FALSE
```

Therefore:

```solidity
(amountOut, 0)
```

Result:

```text
amount0Out = amountOut

amount1Out = 0
```

Perfect.

WETH leaves.

---

# Visual Example #2

Assume:

```text
token0 = WETH

token1 = USDC

WETH → USDC
```

Now:

```text
input  = token0

output = token1
```

Condition:

```text
input == token0
```

becomes:

```text
TRUE
```

Therefore:

```solidity
(0, amountOut)
```

Result:

```text
amount0Out = 0

amount1Out = amountOut
```

Perfect.

USDC leaves.

---

# Child Analogy

Imagine a vending machine with:

```text
Left Slot  = token0

Right Slot = token1
```

The machine asks:

```text
How many items should leave
the Left Slot?

How many items should leave
the Right Slot?
```

It does NOT ask:

```text
Which item do you want?
```

You must translate your request into:

```text
Left Slot

or

Right Slot
```

language.

That is exactly what Router is doing.

---

# Common Confusion

Q:

Are we determining the input token here?

A:

No.

The input token was already known.

We are only determining:

```text
Which output slot
should contain amountOut.
```

---

Q:

Why do we set one value to zero?

A:

Because in a normal swap:

```text
Only ONE token leaves.
```

---

If token0 leaves:

```text
amount0Out = amountOut

amount1Out = 0
```

---

If token1 leaves:

```text
amount0Out = 0

amount1Out = amountOut
```

---

Exactly one side is non-zero.

---

# Biggest Realization

Q:

So are we basically making the Pair understand our language?

A:

Yes.

Exactly.

Router thinks in:

```text
input

output
```

Pair thinks in:

```text
token0

token1
```

This line acts as a translation layer between the two systems.

---

# Final Mental Model

```text
Router Language

USDC → WETH

↓

Pair Language

token1 → token0

↓

amount0Out = amountOut

amount1Out = 0
```

At this point Router has finished determining:

```text
✓ Which Pair

✓ Which output token

✓ How much output

✓ Which output slot
```

The next question becomes:

```text
Where should that output go?
```

That is answered by:

```solidity
address to =
    i < path.length - 2
        ? pairFor(...)
        : _to;
```

which is the famous routing line of `_swap()`.

# The Routing Magic — `address to`

We have now reached the most important line in `_swap()`.

```solidity id="fjuqcy"
address to =
    i < path.length - 2
        ? UniswapV2Library.pairFor(
            factory,
            output,
            path[i + 2]
          )
        : _to;
```

This single line is responsible for the entire:

```text id="2x5tnk"
Pair #1
    ↓
Pair #2
    ↓
Pair #3
    ↓
Recipient
```

routing mechanism.

---

# The Big Question

Before understanding this line, remember the question we carried from the beginning:

```text id="zr4mnz"
The current Pair can output tokens.

Where should those tokens go?
```

For example:

```text id="88kkgb"
USDC → WETH → LINK
```

Suppose:

```text id="jm98mq"
USDC/WETH Pair
```

is about to output:

```text id="mnhhvp"
WETH
```

Where should that WETH go?

```text id="o9v4s8"
Router?

User?

WETH/LINK Pair?
```

The answer is:

```text id="j1dbj4"
WETH/LINK Pair
```

because the swap is not finished yet.

---

# Running Example

We continue using:

```text id="8a0vct"
path

[
    USDC,
    WETH,
    LINK
]
```

---

Length:

```text id="ejy5gl"
path.length = 3
```

---

# Iteration #1

Current iteration:

```text id="8a4bqb"
i = 0
```

Current swap:

```text id="0r23vt"
USDC → WETH
```

Current Pair:

```text id="uxgv17"
USDC/WETH
```

---

Now evaluate:

```solidity id="l4mwbb"
i < path.length - 2
```

Substitute:

```text id="z3q6u0"
0 < (3 - 2)

↓

0 < 1

↓

TRUE
```

---

Since TRUE:

Router chooses:

```solidity id="i4y6w5"
pairFor(
    factory,
    output,
    path[i + 2]
)
```

---

Substitute values:

```text id="j7c7jy"
output

=

WETH
```

and:

```text id="8pl9w7"
path[i + 2]

=

path[2]

=

LINK
```

Therefore:

```solidity id="2grfzi"
pairFor(
    factory,
    WETH,
    LINK
)
```

returns:

```text id="3bzd7s"
WETH/LINK Pair
```

---

Result:

```text id="rwpj6v"
to = WETH/LINK Pair
```

---

# Huge Realization

This means:

```text id="l0ct7n"
USDC/WETH Pair
```

will send its output:

```text id="nsq3w8"
WETH
```

directly to:

```text id="p4uzjd"
WETH/LINK Pair
```

---

Not:

```text id="5o7vyd"
Router
```

---

Not:

```text id="h23qnm"
User
```

---

Directly:

```text id="7gzt56"
Pair #1

↓

Pair #2
```

---

# Why This Is Beautiful

Because:

```text id="eh9lht"
Router never holds tokens.
```

and:

```text id="v0e9wy"
User never touches
intermediate tokens.
```

---

Visual:

```text id="4r5pk3"
User
    ↓

USDC/WETH Pair
    ↓ WETH

WETH/LINK Pair
```

The WETH never touches:

```text id="euywr9"
Router
```

or

```text id="h1mkgq"
User
```

---

# The Look Ahead Trick

Q:

How does Pair #1 know where to send WETH?

A:

Router looks ahead.

---

Current position:

```text id="xxn3g9"
USDC

↓

WETH

↓

LINK
```

---

Router already knows:

```text id="3dkdta"
Current Token

=

WETH
```

---

It simply looks:

```text id="6q1sgu"
One token ahead
```

and sees:

```text id="cc8dkm"
LINK
```

---

Then computes:

```text id="daz2hz"
WETH/LINK Pair
```

using:

```solidity id="mny9z8"
pairFor(
    factory,
    output,
    path[i + 2]
)
```

---

This is often called:

```text id="6b9uk0"
Look-Ahead Routing
```

because Router peeks into the future route.

---

# Iteration #2

Now:

```text id="tnvjlwm"
i = 1
```

Current swap:

```text id="fqqczk"
WETH → LINK
```

Current Pair:

```text id="gdd1ah"
WETH/LINK
```

---

Evaluate:

```solidity id="q3y33s"
i < path.length - 2
```

Substitute:

```text id="ic5x2j"
1 < (3 - 2)

↓

1 < 1

↓

FALSE
```

---

Since FALSE:

Router chooses:

```solidity id="7t16sx"
_to
```

instead.

---

Result:

```text id="l67yva"
to = _to
```

---

# Why?

Because there are:

```text id="r8s1vl"
No more hops.
```

---

We have reached:

```text id="w90j6t"
LINK
```

which is the final token.

---

Therefore:

```text id="crz2bi"
WETH/LINK Pair
```

sends LINK directly to:

```text id="c6q7n3"
Recipient
```

---

# Complete Flow

```text id="8v6cku"
User
    ↓

USDC/WETH Pair
    ↓ WETH

WETH/LINK Pair
    ↓ LINK

Recipient
```

---

# Common Confusion

Q:

Didn't getAmountsOut() already use the path?

A:

Yes.

But for pricing.

```text id="z39ubq"
getAmountsOut()

=
Pricing
```

---

while:

```text id="rxq64j"
_swap()

=
Routing
```

---

Same path.

Different purpose.

---

Q:

Why doesn't Pair #1 send WETH to Router?

A:

Because Router is not a custodian.

Intermediate tokens move directly:

```text id="n3n4uk"
Pair #1

↓

Pair #2
```

without touching Router.

---

Q:

Why doesn't the User receive WETH first?

A:

Because the swap is not finished.

WETH is merely:

```text id="f8djlwm"
An intermediate asset.
```

It is immediately forwarded into the next Pair.

---

Q:

What is the most important thing this line does?

A:

It determines:

```text id="hlylzh"
Destination of current Pair output.
```

---

# Final Mental Model

```text id="pjlwm2"
If another hop exists

↓

Send output
to next Pair

--------------------------------

If no hop exists

↓

Send output
to final recipient
```

That is the entire routing mechanism of `_swap()`.

At this point Router has determined:

```text id="4llqlf"
✓ Current Pair

✓ Current output token

✓ Output amount

✓ Output slot

✓ Output destination
```

Only one line remains:

```solidity id="khj48u"
IUniswapV2Pair(
    pairFor(factory, input, output)
).swap(
    amount0Out,
    amount1Out,
    to,
    new bytes(0)
);
```

This is where Router stops preparing and the actual swap execution begins inside the Pair contract.

For a complete dissection of what happens after this call, see:

```text id="dkk7v8"
notes/Core/Pair/UV2Pair--swap.md
```
## Final Step of Router._swap()

```solidity
IUV2Pair(
    UV2Library.pairFor(
        i_factory,
        input,
        output
    )
).swap(
    amount0Out,
    amount1Out,
    to,
    new bytes(0)
);
```

### Purpose

At this point the Router has finished its job.

The Router has already:

* Determined the swap path
* Calculated all output amounts
* Determined the destination (`to`) address
* Moved the initial input tokens into the first Pair(which happend before we entered _swap btw as I mention before at top)

The only remaining task is to tell the Pair:

```text
"Execute the swap."
```

This line transfers control from:

```text
Router

↓

Pair
```

---

### Mental Model

```text
Router
=
Planning Phase

--------------------------------

Pair
=
Execution Phase
```

The Router calculates what should happen.

The Pair verifies that it can legally happen.

---

### Why `new bytes(0)`?

```solidity
new bytes(0)
```

means:

```text
No Flash Swap
```

Since the data is empty:

```text
data.length == 0
```

the Pair skips the flash swap callback.

This is the standard swap path.

---

### What Happens Next?

The Pair receives:

```solidity
swap(
    amount0Out,
    amount1Out,
    to,
    new bytes(0)
);
```

and begins:

* Liquidity checks
* Output transfers
* Balance accounting
* Input reconstruction
* Fee verification
* K invariant verification
* Reserve updates

For a complete line-by-line breakdown see:

```text
Core/Pair/UV2Pair--swap.md
```

---

### Mental Model(In short)

```text
Router._swap()

↓

Find Pair

↓

Call Pair.swap()

↓

Router's Job Complete

↓

Pair Takes Over
```
