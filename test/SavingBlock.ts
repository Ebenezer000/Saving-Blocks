import { expect } from 'chai';
import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { SavingBlock, DepositSuccessfulEvent } from '../typechain-types/contracts/SavingBlock.sol/SavingBlock';

describe("Saving Block Contract", function () {
    
    async function deploySavingBlockFixture() {

        const [ admin, user1, user2, user3, user4 ] = await ethers.getSigners();

        const initialSupply = 100000;
        const tokenName = "USDT";
        const symbol = "USDT";
        const decimal = 6;

        const _token = await ethers.getContractFactory("Token")
        const Token = await _token.deploy(initialSupply, tokenName, symbol, decimal);
        await Token.deployed();

        const _usdt = Token.address;
        const _signupFee = 10;      

        const _savingBlock = await ethers.getContractFactory("SavingBlock");

        const SavingBlock = await _savingBlock.deploy(admin.toString(), _usdt, decimal, _signupFee);
        await SavingBlock.deployed();

        return { SavingBlock, admin, _usdt, decimal, _signupFee, user1, user2, user3, user4 };
    }

    it("It should be successful during signup and give referrals", async function() {
        const { SavingBlock, user1, user2 }  = await loadFixture(deploySavingBlockFixture);
        
        expect(
            await SavingBlock.connect(user1).SignUp(user2.toString())
        ).to.true;

    });

    it("It should recieve savings and take away referral bonus", async function() {
        const {SavingBlock, user1, user2 } = await loadFixture(deploySavingBlockFixture);

        expect(
            (await SavingBlock.connect(user1).Save(50))
        ).to.true;
    });

    it("It should complete a lending transaction with only referrals as payback", async function() {
        const { SavingBlock, user1 } = await loadFixture(deploySavingBlockFixture);

        expect(
            await SavingBlock.connect(user1).LendWithReferrals(50, 100)
        ).to.true;
    });

    it("it should complete a referrals transaction with guarantors as payback", async function() {
        const { SavingBlock, user1, user2, user3, user4 } = await loadFixture(deploySavingBlockFixture);

        const ONE_DAY_IN_SECS = 24 * 60 * 60;
        expect(
            await SavingBlock.connect(user1).LendWithGuarrantors(
                    90, [user2.toString(), user3.toString(), user4.toString()], ONE_DAY_IN_SECS)
        ).to.true;
    });

    it ("It should Allow user withdraw successfully", async function () {
        const { SavingBlock, user1 } = await loadFixture(deploySavingBlockFixture);

        expect(
            await SavingBlock.connect(user1).UserWithdraw(40)
        ).to.true;
    });

    it ("It should allow Admin to withdraw successfully", async function() {
        const { SavingBlock, user1 } = await loadFixture(deploySavingBlockFixture);

        expect(
            await SavingBlock.connect(user1).AdminWithdraw(50)
        ).to.true;
    });
});