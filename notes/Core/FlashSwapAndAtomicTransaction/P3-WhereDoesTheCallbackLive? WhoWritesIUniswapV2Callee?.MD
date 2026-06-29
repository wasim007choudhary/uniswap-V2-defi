# 3. Where Does The Callback Live? Who Writes `IUniswapV2Callee`?

## First Question

After seeing the following code inside `UniswapV2Pair.swap()`:

```solidity
if (data.length > 0) {
    IUniswapV2Callee(to).uniswapV2Call(
        msg.sender,
        amount0Out,
        amount1Out,
        data
    );
}
```

a very natural question arises.

> **Wait... where is `uniswapV2Call()`?**

We've already read the entire `UniswapV2Pair.sol` contract.

There is no function named:

```solidity
uniswapV2Call(...)
```

inside the Pair contract.

So...

How can the Pair call a function that doesn't even exist inside itself?

---

# The First Realization

The callback **does not live inside the Pair contract.**

Instead...

it lives inside **your contract**.

For example, suppose you want to perform a flash swap.

You might write a contract like this:

```solidity
contract MyFlashSwap is IUniswapV2Callee {

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {

        // Arbitrage

        // Liquidation

        // Repay Pair

    }
}
```

Notice something important.

Who wrote:

```solidity
uniswapV2Call(...)
```

?

**You did.**

Not Uniswap.

---

# Then How Can Uniswap Call My Function?

Later, your contract performs:

```solidity
pair.swap(
    amount0Out,
    amount1Out,
    address(this),
    data
);
```

Notice the third parameter.

```solidity
address(this)
```

Since this code is executing inside your FlashSwap contract,

```text
address(this)

↓

MyFlashSwap Contract
```

So the Pair now remembers:

```text
to

↓

MyFlashSwap Contract
```

Later, the Pair executes:

```solidity
IUniswapV2Callee(to).uniswapV2Call(...)
```

Conceptually, this simply becomes:

```text
Pair

↓

Call

↓

MyFlashSwap.uniswapV2Call(...)
```

The Pair is literally calling a function inside **your contract.**

---

# Wait...

How Does The Pair Know My Contract Has That Function?

The answer is surprisingly simple.

It doesn't.

The Pair simply assumes it exists.

This is exactly the same concept we've already learned with ERC20 interfaces.

For example:

```solidity
IERC20(token).transfer(...)
```

The EVM never checks whether that token inherited from `IERC20`.

It simply attempts to call:

```text
transfer(...)
```

If the function exists,

```text
Continue ✅
```

If the function does not exist,

```text
Call Fails

↓

Transaction Reverts ❌
```

Exactly the same thing happens here.

---

# Child Analogy

Imagine calling a phone number.

You ask:

> "Can you solve this math problem?"

If the person answers...

Great.

If the phone number belongs to a pizza shop...

They're probably going to say:

> "Wrong number."

😂

The EVM behaves in exactly the same way.

It calls the address.

If the requested function exists,

everything continues.

If it doesn't,

the call fails.

---

# The Pair Is Not Calling An Interface

Another common misunderstanding is thinking that the Pair somehow calls the interface itself.

It does not.

The interface exists only for the compiler.

At runtime,

```solidity
IUniswapV2Callee(to).uniswapV2Call(...)
```

is simply telling the EVM:

```text
CALL

↓

Address = to

↓

Function = uniswapV2Call(...)
```

The interface disappears after compilation.

Just like every other Solidity interface we've studied, it provides compile-time type safety, but the EVM ultimately performs an external CALL to the address.

---

# Then Who Wrote `IUniswapV2Callee`?

This naturally leads to another question.

> **Okay... if I write `uniswapV2Call()`, then who wrote the interface?**

The answer is:

**Uniswap did.**

The Uniswap protocol defines the callback interface.

```solidity
interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
```

Think of this interface as a communication contract.

Uniswap is simply saying:

> "If you want us to call your contract during a flash swap, your contract must expose this exact function."

---

# Then What Do I Write?

You simply implement the interface.

```solidity
contract MyFlashSwap is IUniswapV2Callee {

    function uniswapV2Call(...) external override {

        // My custom logic

    }
}
```

Notice the responsibilities.

```text
Uniswap

↓

Defines The Callback Interface

----------------------------

Developer

↓

Implements The Callback
```

The protocol designer defines the communication protocol.

The application developer provides the implementation.

---

# Child Analogy

Imagine Google says:

> "Every applicant must submit a PDF with these fields."

```text
Name

Email

Experience

Resume
```

Google created the template.

You simply fill in the information.

Exactly the same thing happens here.

Uniswap creates the callback interface.

You implement the callback.

---

# This Pattern Exists Everywhere

The callback pattern is not unique to Uniswap.

Once you understand this section, you'll recognize the exact same architecture throughout Solidity.

For example:

* ERC721 → `onERC721Received()`
* ERC1155 → `onERC1155Received()`
* ERC777 → `tokensReceived()`
* Chainlink VRF → `fulfillRandomWords()`
* Chainlink CCIP callbacks
* Cross-chain bridge callbacks

Every one of them follows the same pattern.

```text
Protocol

↓

Calls Your Contract

↓

Your Contract Executes Custom Logic

↓

Protocol Continues Execution
```

---

# Final Mental Model

The callback does **not** belong to the Pair contract.

The callback belongs to **your contract**.

Uniswap simply defines **what function must exist.**

You decide **what that function actually does.**

That is why the Pair can safely execute arbitrary user-defined logic without needing to know anything about your implementation beforehand.
