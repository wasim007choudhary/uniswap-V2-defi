// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

interface IUV2Pair {
    /*////////////////////////////////////////////////////////
                       EVENTS
    ////////////////////////////////////////////////////////*/
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Swap(
        address indexed sender,
        uint256 amount0in,
        uint256 amount1in,
        uint256 amount0out,
        uint256 amount1out,
        address indexed to
    );
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint112 reserve_0, uint112 reserve_1);

    function MINIMUM_LIQUIDITY_LOCKED() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);

    function initialize(address token0, address token1) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 lastUpdatedTimeStamp);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function sync() external;
}
