// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title  Token
 * @author Ebenezer Akpas
 * @notice Simple contract to implement ERC 20 standards 
 *         This contract creates a simple ERC20 token to act as USDT in SAVING BLOCK Tests
 */

contract Token is ERC20, Ownable{
    // unsigned integer to hold decimal value of token
    uint8 decimal; 

    /**
    * @dev add new token details during deployment
    * Params:
    *       @param initialSupply Admin address for owner contract
    *       @param name usdt address of token
    *       @param symbol shows the decimal value of the chosen USDT token
    *       @param _decimal holds the fee each user pays on signup
    */
    constructor(uint256 initialSupply, string memory name, string memory symbol, uint8 _decimal) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        decimal = _decimal;
    }

    //overide openzepplin default 18 decimal value with custom value
    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }
    
}