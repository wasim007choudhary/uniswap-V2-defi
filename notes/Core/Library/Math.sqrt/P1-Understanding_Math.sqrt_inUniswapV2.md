# Understanding `Math.sqrt()` in Uniswap V2

The `sqrt()` function is one of the most important helper functions in the Uniswap V2 codebase.

Unlike addition (`+`), subtraction (`-`), multiplication (`*`), or division (`/`), Solidity **does not provide a built-in square root function**.

If a smart contract needs to calculate the square root of a number, the developer must implement the algorithm manually.

That is exactly what Uniswap has done.

The implementation uses an ancient algorithm called the **Babylonian Method**, which repeatedly improves a guess until it reaches the correct integer square root.

The implementation is shown below.

```solidity
function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}
```

Before trying to memorize the code, our goal is to understand **why every single line exists**.

By the end of this chapter, you should be able to explain every line yourself and even reimplement the algorithm from memory.

---

# Function Header

```solidity
function sqrt(uint y) internal pure returns (uint z)
```

Ignore `internal` and `pure`.

We already know what those mean.

Let's focus only on these two variables.

```solidity
uint y
```

and

```solidity
uint z
```

---

# What Is `y`?

`y` is simply the number whose square root we want to calculate.

Think of `y` as **the question**.

For example,

```
y = 100
```

The question becomes

> Find √100

Another example,

```
y = 25
```

The question becomes

> Find √25

Another example,

```
y = 81
```

The question becomes

> Find √81

Notice something very important.

Throughout the entire function,

```
y
```

**never changes.**

It always remains the original number.

Think of it like a math exam.

At the top of the paper the teacher writes

```
Find √100
```

The number

```
100
```

never changes.

It is simply the question you are trying to answer.

That is exactly what `y` is.

---

# What Is `z`?

```solidity
returns (uint z)
```

`z` is where the function will eventually store the answer.

Think of `z` as the **Answer Box**.

For example,

```
Question

y = 100

↓

Answer

z = 10
```

Another example,

```
Question

y = 25

↓

Answer

z = 5
```

Another,

```
Question

y = 49

↓

Answer

z = 7
```

You can visualize the function like this.

```
Input

y

↓

Algorithm Thinks...

↓

Output

z
```

So remember the roles.

```
y = Original Number

z = Final Answer
```

---

# Why Doesn't The Computer Already Know The Answer?

Suppose I ask you

> Find √100

You immediately answer

```
10
```

Humans recognize many square roots instantly.

Computers do not.

The computer only understands instructions.

It has to calculate the answer step by step.

Imagine asking a five-year-old

> What is √100?

They probably don't know.

So they might start guessing.

```
50?

↓

No.

20?

↓

Closer.

12?

↓

Very close.

10?

↓

Correct.
```

Notice something.

The child did **not** know the answer immediately.

Instead,

they started with a guess,

then kept improving that guess.

That is exactly what the Babylonian Method does.

It starts with a guess,

improves the guess,

improves it again,

and keeps repeating until the answer can no longer be improved.

---

# The First Decision

The first line of the algorithm is

```solidity
if (y > 3) {
```

At first glance, this looks like an ordinary `if` statement.

However, one very important question immediately appears.

> **Why does Uniswap check if `y` is greater than `3`?**

Why not

```
0
```

or

```
1
```

or

```
10
```

There must be a reason.

Let's discover it.

---

# Let's Look At Small Numbers

Suppose

```
y = 0
```

Question

```
√0 = ?
```

Easy.

The answer is

```
0
```

No algorithm is needed.

---

Now suppose

```
y = 1
```

Question

```
√1 = ?
```

Easy.

The answer is

```
1
```

Again,

no algorithm is needed.

---

Now suppose

```
y = 2
```

The real mathematical answer is

```
√2 = 1.414213...
```

However,

this function returns

```solidity
uint
```

A `uint` cannot store decimal values.

So Solidity removes everything after the decimal point.

```
1.414213...

↓

1
```

Therefore,

```
sqrt(2)

returns

1
```

---

Now suppose

```
y = 3
```

The real answer is

```
√3 = 1.732...
```

Again,

Solidity cannot store the decimal part.

So

```
1.732...

↓

1
```

Therefore,

```
sqrt(3)

returns

1
```

---

# Summary

Let's place everything into one table.

| `y` | Real Square Root | Returned `uint` |
|-----:|-----------------:|----------------:|
| 0 | 0 | 0 |
| 1 | 1 | 1 |
| 2 | 1.414... | 1 |
| 3 | 1.732... | 1 |

Now look carefully.

For every number from

```
1

↓

3
```

the answer is already known.

```
1 → 1

2 → 1

3 → 1
```

There is no need to run an expensive algorithm.

No guessing.

No loops.

Nothing.

The answer can be returned immediately.

---

# What Happens At 4?

Now suppose

```
y = 4
```

```
√4 = 2
```

Fine.

Now think about every number larger than four.

```
5

6

7

8

9

10

...

100

...

1,000,000
```

The computer cannot hardcode answers for all of these numbers.

Now it actually needs an algorithm.

That is why Uniswap writes

```solidity
if (y > 3)
```

Read it like this.

> **If the number is larger than 3, then it is worth running the Babylonian algorithm.**

Otherwise,

the answer is already simple enough that we can handle it separately.

---

# Let's Test It

Suppose

```
y = 1
```

The code asks

```
1 > 3 ?
```

Answer

```
False
```

The Babylonian algorithm is skipped.

---

Suppose

```
y = 2
```

Question

```
2 > 3 ?
```

Answer

```
False
```

Again,

the algorithm is skipped.

---

Suppose

```
y = 3
```

Question

```
3 > 3 ?
```

Answer

```
False
```

Still skipped.

---

Suppose

```
y = 100
```

Question

```
100 > 3 ?
```

Answer

```
True
```

Now the function says

> This number is large enough.

> I need to start the Babylonian Method.

This is where the real algorithm begins.