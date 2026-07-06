// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

interface IUV2ERC20 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimal() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);

        function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function approve(address from, address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
  
}
