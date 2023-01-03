import { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';

describe("Saving Block Contract", function () {
    
    async function deploySavingBlockFixture() {

        const [ admin, user1, user2, user3, user4 ] = await ethers.getSigners();

        const _usdt = "";
        const _decimal = "";
        const _signupFee = "";      

        const _savingBlock = await ethers.getContractFactory("SavingsBlock");

        const SavingBlock = _savingBlock.deploy()
        
    }
});