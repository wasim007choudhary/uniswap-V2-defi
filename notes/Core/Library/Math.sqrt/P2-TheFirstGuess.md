# Step 2 — The First Guess

The next line is

```solidity
z = y;
```

At first glance, this line looks completely wrong.

Suppose

```
y = 100
```

The code becomes

```solidity
z = 100;
```

But we already know

```
√100 = 10
```

So why would Uniswap intentionally store the **wrong answer**?

This is the most important idea of the Babylonian Method.

The algorithm does **not** know the answer yet.

Instead,

it starts with a guess.

---

# Think Like A Human

Imagine I ask you

> What is my age?

You have absolutely no idea.

So you make a guess.

```
100?
```

I reply,

> Nope.

You think again.

```
50?
```

Still wrong.

Again,

```
30?
```

Closer.

Again,

```
24?
```

Correct.

Notice something important.

Your very first guess was completely wrong.

But that was perfectly okay.

Why?

Because it gave you somewhere to start.

Without an initial guess,

there would be no way to improve your answer.

The Babylonian Method works exactly the same way.

---

# The Algorithm Needs A Starting Point

The computer does not magically know

```
√100 = 10
```

It has to discover it.

To discover something,

it first needs a starting point.

That starting point is

```solidity
z = y;
```

Think of this line as saying

> "I don't know the answer yet."

> "I'll simply use the original number as my first guess."

---

# Example

Suppose

```
y = 100
```

Execute

```solidity
z = y;
```

Now

```
z = 100
```

Current situation

```
Question (y)

100

↓

Current Guess (z)

100
```

Is the guess correct?

No.

Not even close.

But that is okay.

The algorithm will improve it.

---

# Why Doesn't The Algorithm Start With The Correct Answer?

Someone might ask

> Why not simply start with

```
10
```

instead of

```
100
```

The answer is simple.

If the computer already knew

```
√100 = 10
```

there would be no need for the `sqrt()` function.

The whole purpose of the algorithm is to **discover** the answer.

It cannot start with something it doesn't know.

---

# Why Choose `y`?

Someone else might ask

> Why not start with

```
1
```

or

```
5
```

or

```
50
```

or any other number?

The interesting thing about the Babylonian Method is that it can start with almost **any positive guess**.

Uniswap simply chooses

```solidity
z = y;
```

because it is

- extremely simple,
- guaranteed to be positive (remember this line only executes when `y > 3`),
- and guaranteed to be **greater than or equal to** the real square root.

Let's see that.

| `y` | Real √y | Initial Guess (`z = y`) |
|----:|---------:|------------------------:|
| 4 | 2 | 4 |
| 9 | 3 | 9 |
| 25 | 5 | 25 |
| 100 | 10 | 100 |

Notice something interesting.

The initial guess is **always much larger** than the real answer.

That is perfectly fine.

The Babylonian Method is designed to keep making the guess smaller until it reaches the correct answer.

---

# Think Of Climbing Down Stairs

Imagine the correct answer is

```
10
```

But you are standing here.

```
100
```

The algorithm does not magically jump from

```
100

↓

10
```

Instead,

it walks down.

Something like

```
100

↓

51

↓

26

↓

14

↓

10
```

Each step gets closer.

Eventually,

it reaches the answer.

So

```
100
```

is not supposed to be correct.

It is simply the first step.

---

# What Does `z` Represent?

Earlier we learned

```solidity
returns (uint z)
```

which made it seem like `z` only stores the final answer.

That is only partially true.

During the algorithm,

`z` stores the **current best guess**.

At the very end,

that current best guess becomes the final answer.

So `z` actually has two jobs.

During the algorithm,

```
z

↓

Current Best Guess
```

At the end,

```
z

↓

Final Answer
```

---

# Think Of Solving A Math Problem

Imagine your teacher asks

> Find √100

You first write

```
100
```

Then you realise

> That's way too high.

So you erase it.

Now you write

```
51
```

Then

```
26
```

Then

```
14
```

Finally

```
10
```

Notice something.

The paper always contains **your best answer so far**.

You keep replacing the previous answer with a better one.

That is exactly what `z` does.

---

# Current Mental Model

Right now,

don't think about the Babylonian formula yet.

Just remember this.

```
User asks

Find √100

          │
          ▼

y = 100

(Original Number)

          │
          ▼

z = 100

(First Guess)

          │
          ▼

Algorithm Starts Improving It...
```

At this point,

nothing intelligent has happened yet.

The algorithm has simply created its first guess.

The next line will create a **second guess**.

---

# Step 3 — Creating A Better Guess

The next line is

```solidity
uint x = y / 2 + 1;
```

This introduces another variable called `x`.

Most beginners immediately ask

> "We already have `z`.

> Why do we need another variable?"

That question is exactly what we'll answer next.