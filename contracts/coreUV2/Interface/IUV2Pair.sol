// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

/*////////////////////////////////////////////////////////
                   IMPORTS
////////////////////////////////////////////////////////*/
import {IUV2ERC20} from "contracts/coreUV2/Interface/IUV2ERC20.sol";

interface IUV2Pair is IUV2ERC20 {
    /*////////////////////////////////////////////////////////
                       EVENTS
    ////////////////////////////////////////////////////////*/

    event Swap(
        address indexed sender,
        uint256 amount0in,
        uint256 amount1in,
        uint256 amount0out,
        uint256 amount1out,
        address indexed to
    );
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Sync(uint112 reserve_0, uint112 reserve_1);

    /*////////////////////////////////////////////////////////
                       EXTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////*/
    function MINIMUM_LIQUIDITY_LOCKED() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);

    function initialize(address token0, address token1) external;
    function ammKlastSnapshot() external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 lastUpdatedTimeStamp);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function skim(address to) external;
    function sync() external;
}
