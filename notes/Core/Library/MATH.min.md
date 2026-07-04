# Understanding `Math.min()`

The `min()` function is one of the simplest functions in the `Math` library.

```solidity
function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
}
```

Its only job is to return the **smaller** of two numbers.

---

# Think Like a Child

Imagine your teacher writes two numbers on the board:

```
8      5
```

Then asks,

> **"Which number is smaller?"**

You immediately answer:

```
5
```

That is exactly what `min()` does.

It compares two numbers and returns the smaller one.

---

# Function Parameters

```solidity
function min(uint x, uint y)
```

The function accepts two numbers.

```
x = First Number

y = Second Number
```

For example,

```
x = 8

y = 5
```

---

# Return Value

```solidity
returns (uint z)
```

The result is stored in a variable named `z`.

Think of `z` as the answer box.

```
x = 8

y = 5

↓

z = 5
```

---

# The Main Logic

```solidity
z = x < y ? x : y;
```

At first glance this looks confusing, but it is actually very simple.

This is called the **Ternary Operator**.

Its general form is:

```solidity
condition ? value_if_true : value_if_false;
```

Read it like this:

```
Is the condition true?

YES → Take the first value.

NO  → Take the second value.
```

---

# Understanding the Condition

The condition is

```solidity
x < y
```

This simply asks:

> **"Is x smaller than y?"**

There are only two possible answers.

```
YES

or

NO
```

---

# Example 1

```
x = 8

y = 5
```

Question:

```
Is 8 < 5 ?
```

Answer:

```
No
```

Since the answer is **No**, the function chooses the value after the colon (`:`).

```
z = y

z = 5
```

Final Answer:

```
5
```

---

# Example 2

```
x = 2

y = 10
```

Question:

```
Is 2 < 10 ?
```

Answer:

```
Yes
```

Since the answer is **Yes**, the function chooses the value after the question mark (`?`).

```
z = x

z = 2
```

Final Answer:

```
2
```

---

# Example 3

```
x = 100

y = 100
```

Question:

```
Is 100 < 100 ?
```

Answer:

```
No
```

The function chooses `y`.

```
z = 100
```

Even though it picked `y`, both numbers are the same, so the answer is still correct.

---

# The Same Code Using `if...else`

The ternary operator is just a shorter way of writing an `if...else` statement.

Instead of writing:

```solidity
if (x < y) {
    z = x;
} else {
    z = y;
}
```

the developer wrote:

```solidity
z = x < y ? x : y;
```

Both pieces of code do **exactly the same thing**.

---

# Real-Life Example

Imagine you have two apples.

```
🍎 Small Apple

🍏 Big Apple
```

Your mom says,

> "Give me the smaller apple."

You compare them.

If the left apple is smaller,

```
Take the left apple.
```

Otherwise,

```
Take the right apple.
```

That is exactly how `min()` works.

---

# Another Real-Life Example

Suppose Rahul is 15 years old and Ali is 12 years old.

```
Rahul = 15

Ali = 12
```

Question:

```
Is Rahul younger?

15 < 12 ?
```

Answer:

```
No
```

So we choose Ali's age.

```
12
```

---

# Why Does Uniswap Need `min()`?

Many calculations in Uniswap produce two values.

Sometimes the protocol needs to use **whichever value is smaller**.

Instead of writing an `if...else` statement every time, the developers simply call:

```solidity
Math.min(a, b)
```

For example,

```solidity
Math.min(500, 420)
```

returns

```
420
```

---

# Key Takeaways

- `min()` compares two numbers.
- It always returns the **smaller** number.
- It uses the **ternary operator (`? :`)**, which is simply a shorter version of an `if...else`.
- It is a small helper function that makes the rest of the Uniswap code cleaner and easier to read.