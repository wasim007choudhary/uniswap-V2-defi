# Missing Pairs, Non-Existent Contracts, CREATE2 Addresses & ABI Decode Reverts

## The Original Question

While studying:

```solidity
amounts = getAmountsOut(factory, amountIn, path);
```

a question came up:

> What happens if the pair in the path does not exist?

Example:

```text
Path:

USDC -> WETH
```

but:

```text
USDC/WETH Pair

DOES NOT EXIST
```

Will:

```solidity
safeTransferFrom(...)
```

already happen?

Will:

```solidity
_swap(...)
```

run?

Will tokens get stuck?

Will the EVM revert?

What error actually occurs?

---

# The First Mental Model (Wrong)

Initially it is natural to think:

```text
Router
    ↓
Search Factory
    ↓
Find Pair
    ↓
Use Pair
```

Therefore if pair doesn't exist:

```text
Factory says:
"No Pair Found"
```

and transaction reverts.

This is NOT how Uniswap V2 works.

---

# Uniswap Never Searches For Pairs

One of the most important insights:

```text
Uniswap V2 never searches for pairs.
```

There is:

* No loop
* No lookup table search
* No scan through factory pairs

Instead Uniswap uses:

```text
CREATE2
```

and deterministic address calculation.

---

# What pairFor() Actually Does

Consider:

```solidity
pairFor(factory, USDC, WETH)
```

Many developers imagine:

```text
pairFor()
    ↓
Ask Factory
    ↓
Find Pair
```

Wrong.

Actual flow:

```text
pairFor()
    ↓
Pure Math
    ↓
Calculate Address
```

using:

* Factory Address
* Token0
* Token1
* INIT_CODE_HASH

Example:

```text
Factory = X
Token0  = USDC
Token1  = WETH
```

Produces:

```text
0xABC...
```

No storage read.

No external call.

No verification.

Only mathematics.

---

# Important Distinction

```text
pairFor()
=
Address Calculation
```

NOT

```text
pairFor()
=
Pair Search
```

---

# So When Does Uniswap Learn Whether The Pair Exists?

Only here:

```solidity
IUniswapV2Pair(
    pairFor(factory, tokenA, tokenB)
).getReserves();
```

After substitution:

```solidity
IUniswapV2Pair(
    0xABC...
).getReserves();
```

Now the protocol actually interacts with the calculated address.

This is the moment pair existence gets verified.

---

# If Pair Exists

Flow:

```text
pairFor()
    ↓
Calculates Address
    ↓
Contract Exists
    ↓
getReserves()
    ↓
Returns Data
    ↓
Success
```

---

# If Pair Does NOT Exist

Flow:

```text
pairFor()
    ↓
Calculates Address
    ↓
No Contract Exists
    ↓
getReserves()
    ↓
Failure
```

But this raises another question:

> How can the EVM even call a contract that doesn't exist?

---

# The Real Mental Blockage

Natural thought:

```text
If contract isn't deployed yet,

how can the EVM call it?

Shouldn't it say:

"Address not found"
```

Answer:

No.

Ethereum does NOT have the concept of:

```text
Invalid Address
```

---

# Ethereum's Address Model

Many people imagine Ethereum as:

```text
Address Book

0x111 -> Exists
0x222 -> Exists
0x333 -> Exists

0xABC -> Doesn't Exist
```

and think:

```text
Call 0xABC

↓

Address Not Found
```

Ethereum does not work this way.

---

# Every Address Is Valid

Every Ethereum address is simply:

```text
160 bits
```

Examples:

```text
0x0000000000000000000000000000000000000001

0x0000000000000000000000000000000000000002

0xABCDEF1234567890...
```

The EVM considers ALL of them valid addresses.

---

# House Analogy

Think of Ethereum like a city.

```text
House #1
House #2
House #3
...
House #10,000,000
```

Some houses have people.

Some houses are empty.

But every house number is still valid.

You can mail:

```text
House #5000
```

even if nobody lives there.

Ethereum addresses work similarly.

---

# Address ≠ Contract

This is a critical insight:

```text
Address
≠
Contract
```

Possible states:

```text
Address Exists
Code Exists?
```

| State                      | Code |
| -------------------------- | ---- |
| EOA                        | No   |
| Future CREATE2 Address     | No   |
| Destroyed Contract Address | No   |
| Deployed Contract          | Yes  |

---

# What Happens When The EVM Calls A Non-Contract Address?

Suppose:

```solidity
target.call(data);
```

The EVM roughly does:

```text
Go To Address
    ↓
Check Code
    ↓
Execute Code
```

---

# If Code Exists

```text
code.length > 0
```

Execute contract.

---

# If No Code Exists

```text
code.length == 0
```

Execute...

nothing.

Literally nothing.

---

# What Does The EVM Return?

Result:

```text
success    = true
returndata = ""
```

This surprises many developers.

---

# Why Doesn't The EVM Revert?

From the EVM's perspective:

```text
Call completed successfully.

There was simply no code to execute.
```

No error occurred.

---

# Important Insight

The EVM Call Succeeds.

The problem happens later.

---

# What Actually Happens In Uniswap

Suppose:

```solidity
IUniswapV2Pair(
    0xABC
).getReserves();
```

but:

```text
0xABC
```

contains no contract code.

The EVM executes:

```text
STATICCALL
```

Result:

```text
success    = true
returndata = ""
```

---

# Solidity Now Expects Data

The code expects:

```solidity
(
    uint112 reserve0,
    uint112 reserve1,
    uint32 timestamp
)
```

Internally Solidity attempts:

```solidity
abi.decode(
    returndata,
    (uint112,uint112,uint32)
);
```

But receives:

```text
0 bytes
```

instead of:

```text
96 bytes
```

required for:

```text
(uint112,uint112,uint32)
```

---

# Where The Revert Actually Happens

NOT here:

```text
EVM Call
```

The call succeeded.

Revert occurs here:

```text
ABI Decoder
```

Flow:

```text
STATICCALL
    ↓
success = true
returndata = ""
    ↓
Solidity ABI Decoder
    ↓
Not Enough Data
    ↓
Revert
```

---

# What Error Will Be Seen?

Depends on:

* Compiler version
* Solidity version
* Foundry
* Hardhat
* Remix

Examples:

```text
abi.decode: data too short
```

or

```text
function returned an unexpected amount of data
```

or

```text
Error decoding returned data
```

or simply:

```text
EvmError: Revert
```

---

# Is This A Low-Level EVM Error?

No.

This is better described as:

```text
ABI Decode Failure
```

rather than:

```text
Low-Level EVM Failure
```

The EVM call itself succeeded.

---

# Does safeTransferFrom() Ever Execute?

No.

This was another important confusion.

Many developers think:

```text
getAmountsOut()
    ↓
safeTransferFrom()
    ↓
_swap()
```

and assume the transfer already happened.

It didn't.

---

# Actual Flow

```text
swapExactTokensForTokens()
        ↓
getAmountsOut()
        ↓
getReserves()
        ↓
pairFor()
        ↓
Address Calculated
        ↓
getReserves()
        ↓
ABI Decode Failure
        ↓
REVERT
```

Transaction dies here.

Never reaches:

```solidity
safeTransferFrom(...)
```

Never reaches:

```solidity
_swap(...)
```

Never reaches:

```solidity
Pair.swap(...)
```

---

# What About A Pair With Zero Liquidity?

Different scenario.

Contract EXISTS.

But:

```text
reserve0 = 0
reserve1 = 0
```

Then:

```solidity
getAmountOut(
    amountIn,
    reserveIn,
    reserveOut
)
```

hits:

```solidity
require(
    reserveIn > 0 &&
    reserveOut > 0,
    "INSUFFICIENT_LIQUIDITY"
);
```

Again:

```text
getAmountsOut()
    ↓
REVERT
```

before:

```text
safeTransferFrom()
```

can execute.

---

# CREATE2 And Future Contract Addresses

Another important insight.

Suppose:

```text
Future Pair Address

0xABC...
```

Contract not deployed yet.

Can we still know the address?

Yes.

That's exactly what CREATE2 enables.

---

# Can Tokens Be Sent To A Future Contract Address?

Yes.

Example:

```solidity
USDC.transfer(
    0xABC,
    1000e6
);
```

Even if:

```text
0xABC
```

has no code.

The tokens simply sit at that address.

Later:

```solidity
new Pair{salt: ...}()
```

deploys to:

```text
0xABC
```

and the newly deployed contract immediately owns those tokens.

---

# Final Mental Model

```text
pairFor()
=
Address Calculation
```

```text
getReserves()
=
Pair Existence Verification
```

```text
Address
≠
Contract
```

```text
Every 160-bit value
is a valid Ethereum address
```

```text
Calling a non-contract address
does not fail at the EVM level
```

```text
The EVM returns:

success = true
returndata = ""
```

```text
The revert happens later
when Solidity attempts to decode
the expected return values.
```

---

# One-Line Summary

If a Uniswap V2 pair does not exist, `pairFor()` still successfully calculates the address, the EVM successfully performs the call, but Solidity later reverts during ABI decoding because `getReserves()` expected reserve data and received empty return data from an address with no contract code.
