In here we will disection the sxap mechanocs which will incflude all tje swap realted functions and internal functons and logic involded ok. I tis for my future refrerence and I WILL NOTE HERE WHENRE I GOT STUCK AND WHA I UNDERTSTOOD! LEETS GO --

NOTE - If we want to perform multiple swaps, we'll need another contract beyond the UniswapV2Pair contract, which is where the router contract comes in. It's useful for multi-hop swaps.

# FUNCTION swapExactTokensForTokens()
This function is used like in this way - say we want to swap 500 weth for maximum amount of other token we can can for that 500 you feel me !


 a quick mental blockage , i WAS WONDERING WHY WAS THEY USING VIRUTUAL OVERIDE THO AS THEY JUST IMPORTING FROM INTERFACES WITH NO MATRIALS ISNDIE I MEAN DUH BUT NOW LETS SEE -## virtual + override on Router functions

Initial confusion:

Why does Router01/Router02 use `virtual override`
when the parent is only an interface and contains
no implementation?

Understanding:

- Interface functions are implicitly virtual.
- `override` does NOT mean replacing existing code.
- `override` means fulfilling a function declaration
  inherited from an interface or parent contract.
- The interface defines the API contract.
- Router provides the actual implementation.

Example:

IUniswapV2Router01
    ↓
swapExactTokensForTokens()

Router01
    ↓
swapExactTokensForTokens() override

Meaning:

"I am implementing the interface requirement."

Why `virtual`?

- Allows child contracts to override the implementation again.
- Useful for inheritance chains like:

IUniswapV2Router01
        ↓
Router01
        ↓
Router02
        ↓
FutureRouter

Key insight:

`override` is about satisfying an inherited declaration,
not necessarily replacing existing code.
The most important line to remember is:

Override does not mean "replace code". It means "provide an implementation for an inherited declaration."
ALSO - swapExactTokensForTokens()

Router01 and Router02 implementations are effectively identical.

Router02 exists primarily to add fee-on-transfer token support through additional swap functions.

The standard swapExactTokensForTokens() implementation remains unchanged.

The added `virtual` keyword allows future inheritance but does not affect runtime behavior.
New protocol versions do not always change existing logic. Sometimes they just extend the API with new capabilities.


////
while coding i used block.stimesap instead of uint256 deadline why, beacuse In though  the trsaction sending timke was the user time but it was a huge mistake beacuse it was not the user decided time like you feel what i aM SAYING IT WEILL REVERT AS THE MOEMNGT THE TRANSTION IS ENT FOR THE SWAP AND A SECOND PASSES THEN BOOM FAILED. GET THAT IN YOUR BRAIN WASIM! GGs