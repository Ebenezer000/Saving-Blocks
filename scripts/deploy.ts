import { ethers } from "hardhat";

async function main() {
  const admin = await ethers.getSigners();

  const _usdt = "0x60F81573976c62313484B0406ff28c685Eb9c48F";
  const _signupFee = "10";      
  const decimal = "6";

  const _savingBlock = await ethers.getContractFactory("SavingBlock");

  const SavingBlock = await _savingBlock.deploy(admin.toString(), _usdt, decimal, _signupFee);
  await SavingBlock.deployed();

  console.log(`Saving Block has been deployed with address ${SavingBlock.address} and admin ${admin} `);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
