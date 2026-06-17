//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library UV2Library {
    error UV2Library__getAmountOut__InsufficientInputAmount();
    error UV2Library__getAmountOut__InsufficientLiquidity();

    /**
     * @notice This function getAmountoutput() is mainly for outputAmount for single swap between one pair and  is also the mathematical  heart of uniswap v2 swapping mechanism and other tied to it.
     * ex - USDC in--> WETH out
     */
    function getAmountOut(uint256 inputAmount, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 outputAmount)
    {
        if (inputAmount <= 0) {
            revert UV2Library__getAmountOut__InsufficientInputAmount();
        }
        if (reserveIn <= 0 || reserveOut <= 0) {
            revert UV2Library__getAmountOut__InsufficientLiquidity();
        }
        /**

* @dev Understanding Where Uniswap V2's  calculation  dx = (X₀ * dy * 0.997) / (Y₀ + dy * 0.997)
*
* ---
* Example Values
* ---
*
* Assume:
*
* ```
  reserveIn  (X₀) = 100 ETH
  ```
* ```
  reserveOut (Y₀) = 200000 USDC
  ```
* ```
  inputAmount   (dx) = 10 ETH
  ```
* ```
  fee              = 0.3%
  ```
*
* ---
* Step 1: Original Formula
* ---
*
* Uniswap's swap output formula is:

        
        Y₀ × dx × 0.997
*  dy = -----------------
         X₀ + dx × 0.997


* Substitute the numbers:
  
        200000 × 10 × 0.997
*  dy = -------------------
        100 + 10 × 0.997

* Calculate:

       1,994,000
* dy = ---------
        109.97

* dy ≈ 18,132.22
  

* ---
* Step 2: Solidity Cannot Use 0.997
* ---
*
* Solidity only works with integer arithmetic.
*
* Therefore Uniswap rewrites:

           997
* 0.997 = ----
          1000
*
* Substituting:

        200000 × 10 × (997/1000)
  dy = --------------------------
        100 + 10 × (997/1000)
*
* ---
* Step 3: Remove the Fraction
* ---
*
* We do not want `/1000` inside the denominator.
*
* Therefore multiply BOTH numerator and denominator by 1000.
*
* Remember:

       a      a × 1000
*     ---  = -----------
       b      b × 1000

*
* This does NOT change the value.
*
* Therefore:

           200000 × 10 × (997/1000) × 1000
*     dy = ---------------------------------
           (100 + 10 × (997/1000)) × 1000
*
* ---
* Numerator --
* ---
*
* The 1000 cancels:
*
  200000 × 10 × (997/1000) × 1000 
  
  = 200000 × 10 × 997

  = 1,994,000,000
  
*
* Notice:
*

  THIS is where the numerator's 1000 went. It cancelled.
*
* ---
* Denominator --
* ---

*  (100 + 10 × (997/1000)) × 1000
  
* Distribute the 1000: Apply the distributive property : (a+b)c = ac+bc

*  (100 × 1000) + (10 × 997) = 100000 + 9970 = 109970 
 
*
* ---
* Final Form
* ---
*
* We now have:
        200000 × 10 × 997
*  dy = ----------------------
        100 × 1000 + 10 × 997

*
* Numerically:

        1,994,000,000
*  dy = ---------------
        109,970
   
*   dy ≈ 18,132.22
*
* Exactly the same answer as before.
*
* ---
* Compare To Uniswap V2 Code
* ---
*
* Solidity:

*  uint inputAmountWithFee = inputAmount * 997;
  
* Using our numbers:

*  10 * 997 = 9970
  ---
* Solidity:

*  uint numerator = inputAmountWithFee * reserveOut;

* Using our numbers:

* 9970 * 200000 = 1,994,000,000

 ---
* Solidity:

*  uint denominator = reserveIn * 1000 + inputAmountWithFee;
  ```
*
* Using our numbers:

  100 * 1000 + 9970 = 109970
* ---
*
* Solidity:

*  amountOut = numerator / denominator;

* Using our numbers:

*  1,994,000,000 / 109970 ≈ 18,132.22
  
*
* ---
* Key Insight
* ---
*
* The `1000` is NOT an extra fee.
*
* It appears because Uniswap replaced:
*
* ```
  0.997
  ```
*
* with:
*
* ```
  997/1000
  ```
*
* and then multiplied the ENTIRE fraction by 1000 to eliminate decimal
* arithmetic.
*
* The numerator's 1000 disappears because it cancels with the `/1000`
* from `997/1000`.
*
* The denominator's 1000 survives as:
*
* reserveIn * 1000
  
* which is why Uniswap's implementation contains:
*
* reserveIn.mul(1000).add(inputAmountWithFee)
*
* and NOT:
  reserveOut.mul(1000)

  Note We will directly use signs for multiply and add unlike in the natspec as uniswap needed to check overflow and 
  underflow but we are doing with solidity version 0.8+ so it automatically does it for us!
 */
 
 // go through the above natspec completly befreo going any further to the caluclations or you will get lost
    uint256 numerator  = inputAmountWithFee * reserveOut;
    uint256 denominator  = inputAmountWithFee + (reserveIn * 1000); 
 outputAmount = numerator / denominator;


    }
    function getAmountsOut(uint256 inputAmount, address[] memory path)
        internal
        pure
        returns (uint256[] memory outputAmounts)
    {}
}
