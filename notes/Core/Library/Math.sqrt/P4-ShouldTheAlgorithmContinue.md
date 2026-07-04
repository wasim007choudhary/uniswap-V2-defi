# Step 4 — Should The Algorithm Continue?

The next line is

```solidity
while (x < z) {
```

This is one of the most important lines in the entire function.

At first glance, it looks like an ordinary `while` loop.

However, this condition is actually asking a much deeper question.

Instead of reading it as

> **"Loop while `x` is smaller than `z`."**

you should think of it as

> **"Keep looping as long as my new guess is better than my previous best guess."**

Once you understand this idea, the rest of the Babylonian Method becomes much easier.

---

# Let's Continue Our Example

From the previous section we had

```
y = 100

z = 100

x = 51
```

Remember the jobs of the variables.

```
y

↓

Original Number
```

```
z

↓

Current Best Guess
```

```
x

↓

New Guess
```

Now the algorithm asks

```solidity
while (x < z)
```

Substitute the values.

```
while (51 < 100)
```

Question

```
Is 51 smaller than 100?
```

Answer

```
YES
```

Therefore,

the loop begins.

---

# But Why Compare `x` And `z`?

Remember what each variable represents.

```
z

↓

Current Best Guess
```

```
x

↓

New Guess
```

The Babylonian Method is designed so that every new guess should be **better** than the previous one.

In this implementation,

a better guess is always a **smaller** guess.

Let's see that.

```
Old Guess

100

↓

New Guess

51
```

Clearly,

```
51
```

is a much better estimate than

```
100
```

So the algorithm says

> Great!

> Keep going.

---

Now suppose later we have

```
Old Guess

51

↓

New Guess

26
```

Again,

```
26
```

is better.

Continue.

---

Later

```
26

↓

14
```

Better.

Continue.

---

Later

```
14

↓

10
```

Better.

Continue.

As long as the new guess is getting smaller,

the algorithm knows

> I'm still improving.

---

# Think Of Walking Down Stairs

Imagine the correct answer is

```
10
```

But you are standing on stair

```
100
```

The Babylonian Method walks down the staircase.

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

Every step moves you closer to the correct answer.

Now imagine you reach

```
10
```

You try once more.

Your next guess is

```
10
```

again.

Nothing changed.

You are no longer moving.

There is no reason to keep walking.

The algorithm has reached its destination.

---

# Why Doesn't The Loop Run Forever?

Every loop needs a condition that eventually becomes false.

Otherwise,

the program would run forever.

The condition is

```solidity
while (x < z)
```

Initially,

```
51 < 100

↓

True
```

Continue.

Later,

```
26 < 51

↓

True
```

Continue.

Later,

```
14 < 26

↓

True
```

Continue.

Later,

```
10 < 14

↓

True
```

Continue.

Finally,

```
10 < 10

↓

False
```

Now the loop stops.

The function has found the answer.

---

# Why Not Use

Someone might ask

> Why didn't Uniswap write

```solidity
while (x != z)
```

instead?

That seems reasonable.

However,

the Babylonian Method is designed so that every new guess becomes **smaller and smaller**.

The moment the new guess is **no longer smaller**, the algorithm has converged.

Checking

```solidity
x < z
```

is enough.

As soon as

```
x

=

z
```

the algorithm knows

> I can't improve the answer anymore.

Stop.

---

# Let's Watch The Entire Journey

Initially

```
z = 100

x = 51
```

Question

```
51 < 100 ?
```

```
YES
```

Continue.

---

Later

```
z = 51

x = 26
```

Question

```
26 < 51 ?
```

```
YES
```

Continue.

---

Later

```
z = 26

x = 14
```

Question

```
14 < 26 ?
```

```
YES
```

Continue.

---

Later

```
z = 14

x = 10
```

Question

```
10 < 14 ?
```

```
YES
```

Continue.

---

Finally

```
z = 10

x = 10
```

Question

```
10 < 10 ?
```

```
NO
```

The loop stops.

The answer is

```
10
```

---

# Child Analogy

Imagine you are trying to guess how many candies are inside a jar.

Your guesses become

```
100

↓

60

↓

30

↓

15

↓

12

↓

12
```

Notice the last two guesses.

```
12

↓

12
```

Nothing changed.

You are no longer improving.

Would you continue guessing forever?

Of course not.

You would say

> I think this is the answer.

That is exactly what the Babylonian Method does.

---

# What This Line Really Means

When you first read

```solidity
while (x < z)
```

it is easy to think

> Loop while `x` is smaller.

That explanation is technically correct,

but it completely misses the purpose of the line.

A much better way to read it is

> **"Keep looping as long as every new guess is better than my previous best guess."**

The moment the new guess is **not** better,

the algorithm stops.

---

# Current Mental Model

At this point,

our algorithm looks like this.

```
Question

Find √100

          │
          ▼

Original Number

y = 100

          │
          ▼

Current Best Guess

z = 100

          │
          ▼

Create Better Guess

x = 51

          │
          ▼

Is The New Guess Better?

YES

          │
          ▼

Keep Improving...

          │
          ▼

Eventually

z = 10

x = 10

          │
          ▼

No More Improvement

          │
          ▼

Stop
```

---

# The First Line Inside The Loop

The first statement inside the loop is

```solidity
z = x;
```

This line is much more important than it looks.

It simply says

> **"The new guess was better than the previous best guess, so promote it to become the new current best guess."**

Without this line,

the algorithm would never remember that it had found a better estimate.