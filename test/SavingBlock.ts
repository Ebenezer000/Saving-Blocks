import { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';

describe("Saving Block Contract", function () {
    
    async function deploySavingBlockFixture() {

        const [ admin, user1, user2, user3, user4 ] = await ethers.getSigners();

        const initialSupply = 100000;
        const tokenName = "USDT";
        const symbol = "USDT";
        const decimal = 6;

        const _token = await ethers.getContractFactory("Token")
        const Token = _token.deploy(initialSupply, tokenName, symbol, decimal);

        const _usdt = (await Token).address;
        const _decimal = (await Token).decimals();
        const _signupFee = 10;      

        const _savingBlock = await ethers.getContractFactory("SavingBlock");

        const SavingBlock = _savingBlock.deploy(admin.toString(), _usdt, _decimal, _signupFee)

        
        
    }
});