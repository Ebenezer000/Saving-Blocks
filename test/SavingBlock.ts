import { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { SavingBlock } from '../typechain-types/contracts/SavingBlock.sol/SavingBlock';

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
        const _signupFee = 10;      

        const _savingBlock = await ethers.getContractFactory("SavingBlock");

        const SavingBlock = _savingBlock.deploy(admin.toString(), _usdt, decimal, _signupFee);

        return { SavingBlock, admin, _usdt, decimal, _signupFee, user1, user2, user3, user4 };
    }

    it("It should be successful during signup and give referrals", async function() {
        const [SavingBlock, admin, user1, user2] = await loadFixture(deploySavingBlockFixture);

        

    });
});