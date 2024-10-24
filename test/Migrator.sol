//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.20;

import {IERC20} from "./ERC20.sol";

contract Migrator{

    IERC20 public tokenToMigrate;

    constructor(address _token){
        tokenToMigrate = IERC20(_token);
    }

    function migrate(IERC20 token) external returns (IERC20){
        uint256 amount = token.allowance(msg.sender,address(this));
        token.transferFrom(msg.sender,address(this),amount);
        require(tokenToMigrate.balanceOf(address(this))>= amount,"notEnoughTokenToMigrate");
        tokenToMigrate.transfer(msg.sender,amount);
        return tokenToMigrate;
    }
}