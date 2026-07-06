// SPDX-Lisense-Identifeir: MIT

pragma solidity ^0.8.20;

import {IUV2ERC20} from "contracts/coreUV2/Interface/IUV2ERC20.sol";

contract UniswapV2ERC20 is IUV2ERC20 {
   
    string public constant name = "Uniswap-V2 LP Token";
    string public constant symbol = "UV2-LP";
    uint8 public constant decimal = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    //BASICALLY hash of the permit function with the args, not value tho, computer language of what the functio looks like
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

      event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    mapping(address => uint256) public nounces;

    constructor() {
        uint256 chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            keccak256(bytes(name)),
            keccak256(bytes('1')),
            chainId,
            address(this)
        ));
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value; 
        emit Transfer(from, to, value);
    }
       function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);

    }
    function _mint(address to, uint256 value) private {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }
    function _burn(address from, uint256 value) private {
        totalSupply -= value;
        balanceOf[from] -= value;
        emit Transfer(from, address(0), value);
    }

 
function transfer(address to, uint256 value) external returns(bool){
    _transfer(msg.sender, to, value);
    return true;
}

function approve( address spender, uint256 value) external returns(bool) {
    _approve(msg.sender, spender, value);
    return true;
}





    
}
