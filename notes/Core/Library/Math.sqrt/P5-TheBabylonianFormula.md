# Step 5 — Creating An Even Better Guess (The Babylonian Formula)

The next line is

```solidity
x = (y / x + x) / 2;
```

This is the heart of the Babylonian Method.

At first glance,

this line looks like magic.

```
(y / x + x) / 2
```

looks like a random mathematical formula.

It is not.

Every part of this formula has a purpose.

Let's understand where it comes from.

---

# Forget The Formula For A Moment

Pretend this line doesn't exist.

Suppose I ask you

> Find √100

You don't know the answer.

So you guess

```
100
```

I tell you

> Too high.

So you improve it.

```
51
```

Better.

Now imagine I ask

> Can you make an even better guess?

The obvious question is

> **How?**

How do we improve a guess?

That is exactly what this formula teaches us.

---

# The Goal

Suppose your current guess is

```
20
```

How can you check whether it is correct?

Simple.

Multiply it by itself.

```
20 × 20 = 400
```

Oops.

Way too large.

Now suppose your guess is

```
5
```

Check it.

```
5 × 5 = 25
```

Now it is too small.

The correct answer

```
10
```

must be somewhere between

```
5

and

20
```

But how do we find that middle point?

---

# A Very Clever Observation

Suppose we are trying to calculate

```
√100
```

Imagine your current guess is

```
10
```

Now divide

```
100 ÷ 10
```

The answer is

```
10
```

Interesting.

Both numbers are exactly the same.

---

Now suppose your guess is

```
20
```

Instead of multiplying,

divide.

```
100 ÷ 20

=

5
```

Now we have two numbers.

```
20

and

5
```

Notice something.

One number is

```
Too Large
```

The other is

```
Too Small
```

The real answer

```
10
```

must be somewhere between them.

---

# Another Example

Suppose your guess is

```
25
```

Compute

```
100 ÷ 25

=

4
```

Now we have

```
25

and

4
```

Again,

one number is much too large.

The other is much too small.

The correct answer

```
10
```

must lie somewhere between them.


---

# A Different Way To Understand `y / x` (Rectangle Intuition)

There is another beautiful way to understand why the Babylonian Method uses

```solidity
y / x
```

instead of some random mathematical operation.

Imagine that the original number (`y`) represents the **area of a rectangle**.

For example,

```
y = 100
```

means

```
Area = 100 square units
```

Now suppose our current guess (`x`) is

```
20
```

Think of this guess as the **width** of the rectangle.

We already know the formula for the area of a rectangle.

```
Area = Width × Height
```

We already know

```
Area = 100
```

and

```
Width = 20
```

So how do we find the height?

Simple.

```
Height = Area ÷ Width
```

Substitute the values.

```
Height = 100 ÷ 20

=

5
```

Now our rectangle looks like this.

```
            Width = 20

+----------------------------+
|                            |
|                            |
|                            |  Height = 5
|                            |
+----------------------------+
```

Notice something important.

This is **not a square**.

The width is

```
20
```

but the height is

```
5
```

A square must have **equal sides**.

```
Width = Height
```

For example,

```
10 × 10 = 100
```

```
+----------+
|          |
|          | 10
|          |
+----------+

     10
```

The area is still

```
100
```

but now both sides are equal.

That is exactly what we want.

Our current rectangle has sides

```
20

and

5
```

One side is too large.

One side is too small.

How can we move both sides toward each other?

The simplest idea is to take the average.

```
(20 + 5) / 2

=

12
```

Now our next guess becomes

```
12
```

Let's repeat the process.

Current guess

```
12
```

Other side

```
100 ÷ 12

=

8
```

Now the rectangle is

```
Width = 12

Height = 8
```

Notice what happened.

Originally we had

```
20

and

5
```

Now we have

```
12

and

8
```

The two sides became much closer together.

Repeat once more.

Current guess

```
10
```

Other side

```
100 ÷ 10

=

10
```

Now both sides are equal.

```
Width = 10

Height = 10
```

The rectangle has become a perfect square.

```
+----------+
|          |
|          | 10
|          |
+----------+

     10
```

The side length of that square is

```
10
```

which is exactly

```
√100
```

This is the beautiful idea behind the Babylonian Method.

Every iteration starts with a rectangle.

```
Width = Current Guess

Height = y ÷ Current Guess
```

If the rectangle is not a square,

the algorithm averages the two sides to make them closer together.

```
Large Side

↓

Average

↑

Small Side
```

After repeating this process several times,

both sides eventually become equal.

At that moment,

the rectangle has become a square,

and that common side length is the square root.

This is exactly why the Babylonian formula is

```solidity
x = (y / x + x) / 2;
```

It is simply taking the average of the rectangle's two sides until they become equal.

---

# So What Should We Do?

Imagine two children are guessing your age.

Child A says

```
20
```

Child B says

```
5
```

Neither child is correct.

How could we create a better guess?

The simplest idea is

> Take the average.

Average means

```
(20 + 5) / 2
```

which equals

```
12
```

Notice something.

```
12
```

is much closer to

```
10
```

than

```
20
```

---

# That Is The Entire Babylonian Method

There is no hidden magic.

The algorithm simply says

> Take your current guess.

↓

Find another number by dividing the original number by your guess.

↓

Average the two numbers.

↓

That average becomes your next guess.

That is all the Babylonian Method is doing.

---

# Now Match It To The Code

The code is

```solidity
x = (y / x + x) / 2;
```

Let's separate it into pieces.

First

```solidity
y / x
```

This creates another number based on your current guess.

---

Second

```solidity
x
```

This is your current guess.

---

Third

```solidity
y / x + x
```

Now you have both numbers.

---

Finally

```solidity
(y / x + x) / 2
```

This simply computes

> The average.

Nothing more.

---

# Let's Calculate Everything By Hand

Suppose

```
y = 100

Current Guess

x = 51
```

Compute

```
100 / 51
```

Remember,

Solidity performs integer division.

```
100 / 51

=

1
```

not

```
1.960784...
```

because the decimal part is discarded.

Now compute

```
1 + 51

=

52
```

Now divide by two.

```
52 / 2

=

26
```

The new guess becomes

```
26
```

Notice what happened.

```
Old Guess

51

↓

New Guess

26
```

The guess became much better.

---

# Next Iteration

Current guess

```
26
```

Compute

```
100 / 26
```

Remember,

integer division.

```
100 / 26

=

3
```

Now average.

```
(26 + 3) / 2

=

29 / 2

=

14
```

The new guess becomes

```
14
```

Again,

the guess improved.

---

# Next Iteration

Current guess

```
14
```

Compute

```
100 / 14

=

7
```

Average

```
(14 + 7) / 2

=

21 / 2

=

10
```

New guess

```
10
```

Now we are extremely close.

---

# One More Time

Current guess

```
10
```

Compute

```
100 / 10

=

10
```

Average

```
(10 + 10) / 2

=

10
```

The guess did not change anymore.

The algorithm has reached the answer.

---

# Complete Journey

Let's write every guess in order.

```
Question

√100
```

First guess

```
100
```

Second guess

```
51
```

Third guess

```
26
```

Fourth guess

```
14
```

Fifth guess

```
10
```

Sixth guess

```
10
```

Nothing changed.

The algorithm stops.

---

# Why Does This Formula Always Work?

Suppose your guess is much too large.

For example

```
50
```

Now compute

```
100 / 50

=

2
```

Notice something interesting.

```
50
```

is very large.

```
2
```

is very small.

The average naturally moves toward the middle.

```
(50 + 2) / 2

=

26
```

Much closer.

---

Now suppose your guess is

```
26
```

Compute

```
100 / 26

=

3
```

Average

```
(26 + 3) / 2

=

14
```

Closer again.

Every time,

the average pulls the guess toward the correct answer.

---

# Child Analogy

Imagine two children are pulling on a rope.

One child is standing here.

```
2
```

The other child is standing here.

```
20
```

Where is the middle?

```
11
```

The Babylonian Method always walks toward the middle.

Each time,

it gets closer to the correct answer.

Eventually,

both sides meet.

---

# Another Way To Think About It

Imagine throwing darts at a target.

First throw

```
100
```

Way too far.

Second throw

```
51
```

Better.

Third throw

```
26
```

Better.

Fourth throw

```
14
```

Very close.

Fifth throw

```
10
```

Bullseye.

The Babylonian Method keeps correcting itself after every throw.

---

# What This Line Really Means

When you first see

```solidity
x = (y / x + x) / 2;
```

it is tempting to read it like this.

> Divide.

> Add.

> Divide again.

That is technically correct.

But it completely misses the purpose.

A much better way to read it is

> **Take my current guess, compare it with the number obtained by dividing the original value by that guess, then average the two numbers. That average becomes my next, better guess.**

That single sentence explains the entire Babylonian Method.

---

# Mental Model

```
Current Guess

↓

Compute

y / Guess

↓

Now You Have

A Large Number

and

A Small Number

↓

Take Their Average

↓

You Get A Better Guess

↓

Repeat

↓

Eventually

No More Improvement

↓

Answer Found
```

This is the only mathematically "clever" part of the entire algorithm.

Every other line in the function simply prepares for this formula or checks whether the algorithm should continue using it.