# Step 6 — Handling The Small Numbers

At this point, we have completely understood the Babylonian Method.

However, there is still one small part of the function left.

```solidity
} else if (y != 0) {
    z = 1;
}
```

At first glance, this looks like a tiny piece of code.

In reality, it handles all of the small numbers that **do not need** the Babylonian Method.

---

# Let's Look At The Entire Structure

The function is organized like this.

```solidity
if (y > 3) {
    // Babylonian Method
} else if (y != 0) {
    z = 1;
}
```

Think of it as a decision tree.

```
                    Is y > 3 ?

                  YES          NO
                   │            │
                   ▼            ▼

          Babylonian Method   Is y != 0 ?

                                 │
                          YES            NO
                           │              │
                           ▼              ▼

                      Return 1        Return 0
```

The function has only two possible paths.

1. Run the Babylonian Method.
2. Handle the small numbers directly.

---

# Case 1 — `y = 100`

Suppose

```
y = 100
```

The first condition asks

```
100 > 3 ?
```

Answer

```
YES
```

So the Babylonian Method runs.

Eventually,

the function returns

```
10
```

---

# Case 2 — `y = 2`

Suppose

```
y = 2
```

First condition

```
2 > 3 ?
```

Answer

```
NO
```

So the algorithm skips the Babylonian Method.

Now the second condition is checked.

```solidity
else if (y != 0)
```

Substitute the value.

```
2 != 0
```

Question

```
Is 2 different from 0?
```

Answer

```
YES
```

Therefore,

the function executes

```solidity
z = 1;
```

The returned value becomes

```
1
```

This is correct because

```
√2 ≈ 1.414213...

↓

1
```

The decimal part is discarded because the function returns a `uint`.

---

# Case 3 — `y = 3`

Suppose

```
y = 3
```

First condition

```
3 > 3 ?
```

Answer

```
NO
```

Second condition

```
3 != 0 ?
```

Answer

```
YES
```

Execute

```solidity
z = 1;
```

Correct because

```
√3 ≈ 1.732...

↓

1
```

---

# Case 4 — `y = 1`

Suppose

```
y = 1
```

First condition

```
1 > 3 ?
```

Answer

```
NO
```

Second condition

```
1 != 0 ?
```

Answer

```
YES
```

Execute

```solidity
z = 1;
```

Correct because

```
√1 = 1
```

---

# Why Doesn't Uniswap Write Three Separate Conditions?

Someone might ask

> Why not simply write

```solidity
if (y == 1)
```

or

```solidity
if (y == 2)
```

or

```solidity
if (y == 3)
```

That would certainly work.

However,

notice something interesting.

```
√1

↓

1
```

```
√2

↓

1
```

```
√3

↓

1
```

All three values return exactly the same integer.

Instead of writing three separate conditions,

Uniswap combines all three into one simple condition.

```solidity
else if (y != 0)
```

This single line automatically handles

```
1

2

3
```

making the code cleaner and shorter.

---

# But What About Zero?

Now comes a question that surprises many people.

Suppose

```
y = 0
```

First condition

```
0 > 3 ?

↓

False
```

Second condition

```
0 != 0 ?

↓

False
```

Neither block executes.

So how does the function return

```
0
```

when we never wrote

```solidity
z = 0;
```

---

# The Hidden Solidity Rule

Remember the function header.

```solidity
function sqrt(uint y) internal pure returns (uint z)
```

Notice something.

We never explicitly initialized `z`.

There is no line like

```solidity
uint z = 0;
```

So why doesn't Solidity complain?

Because Solidity automatically initializes variables to their default values.

For a `uint`,

the default value is

```
0
```

That means before the function executes any code,

Solidity has already done something conceptually similar to

```
z = 0;
```

You never see this in the source code,

but it happens automatically.

---

# Let's Follow `y = 0`

Suppose

```
y = 0
```

Before the function begins,

```
z = 0
```

automatically.

Now execute the code.

First condition

```
0 > 3

↓

False
```

Second condition

```
0 != 0

↓

False
```

Nothing changes.

The function reaches the end.

What is stored inside `z`?

Still

```
0
```

Therefore,

the function returns

```
0
```

Exactly what we want because

```
√0 = 0
```

---

# Complete Execution Flow

Let's put everything together.

Suppose someone calls

```solidity
Math.sqrt(y);
```

The algorithm follows this path.

```
                    Start

                      │
                      ▼

             Receive Input y

                      │
                      ▼

               Is y > 3 ?

             YES            NO
              │              │
              ▼              ▼

     Babylonian Method    Is y != 0 ?

                              │
                       YES            NO
                        │              │
                        ▼              ▼

                    Return 1       Return 0
```

---

# Complete Babylonian Flow

When

```
y > 3
```

the algorithm performs these steps.

```
Receive Number

        │
        ▼

Initial Guess

z = y

        │
        ▼

Second Guess

x = y / 2 + 1

        │
        ▼

Is New Guess Better?

while (x < z)

        │
        ▼

YES

        │
        ▼

Promote New Guess

z = x

        │
        ▼

Generate Even Better Guess

x = (y / x + x) / 2

        │
        ▼

Repeat

        │
        ▼

Eventually

x = z

        │
        ▼

No More Improvement

        │
        ▼

Return z
```

---

# Complete Example (`√100`)

Let's trace every important value one last time.

```
Input

y = 100
```

Initial guess

```
z = 100
```

Second guess

```
x = 100 / 2 + 1

=

51
```

Loop begins.

```
51 < 100

↓

YES
```

Promote new guess.

```
z = 51
```

Generate another guess.

```
x = (100 / 51 + 51) / 2

=

26
```

Continue.

```
26 < 51

↓

YES
```

Promote.

```
z = 26
```

Generate again.

```
x = (100 / 26 + 26) / 2

=

14
```

Continue.

```
14 < 26

↓

YES
```

Promote.

```
z = 14
```

Generate again.

```
x = (100 / 14 + 14) / 2

=

10
```

Continue.

```
10 < 14

↓

YES
```

Promote.

```
z = 10
```

Generate again.

```
x = (100 / 10 + 10) / 2

=

10
```

Now check.

```
10 < 10

↓

NO
```

The loop stops.

Return

```
10
```

---

# Final Mental Model

The Babylonian Method is **not** trying to magically calculate the square root in one step.

Instead, it behaves like a person making better and better guesses.

```
Wrong Guess

↓

Slightly Better Guess

↓

Better Guess

↓

Very Good Guess

↓

Perfect Guess

↓

Stop
```

Every iteration makes the guess closer to the correct answer.

Once the guess can no longer be improved,

the algorithm finishes.

---

# Key Takeaways

- Solidity does **not** have a built-in square root function.
- Uniswap implements square root using the **Babylonian Method**.
- `y` is the original number and never changes.
- `z` stores the current best guess and eventually becomes the returned answer.
- `x` stores the newly computed guess.
- The algorithm begins with a rough guess (`z = y`).
- It immediately creates a better guess (`x = y / 2 + 1`).
- Every iteration compares the new guess with the current best guess.
- If the new guess is better, it becomes the new best guess.
- A new guess is generated by averaging the current guess with `y / currentGuess`.
- The process repeats until the guess can no longer be improved.
- Values `1`, `2`, and `3` return `1` directly.
- Value `0` returns `0` because `uint` variables are automatically initialized to zero.

---

# The Entire Algorithm In One Sentence

> **Start with a rough guess, repeatedly improve that guess by averaging it with `y / guess`, and stop when the guess no longer improves.**