# Savings Block

This is a basic Savings platform that Extends a Multi Level Marketing System for referrals 
Users can act as guarrantors for other users and Take Loans from the Vault of the smart contract

### Public Functions
- ##### Signup
    /**
    * @dev external function to track and manage user signup
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param _referrer array [referrer which are the addresses of the referrals the user has]
    * REQUIREMENTS: 
    *   The user / msg.sender must hold the equivalent signup fee of $10
    *   The user cannot be referred by the Dead address
    *   The user cannot already be signed up
    *   The referree must be a signed up user
    *   The user must have enough USDT to pay for sign up
    *   The user must have granted usdt allowance
    *   The user cannot refer themselves
    */
    
- ##### Save
- ##### LendWithReferrals
- ##### LendWithGuarrantors
- ##### UserWithdraw
- ##### AdminWithdraw

## Tasks

This Project was initialised using HardHat 
You can try running some of the folloeing tasks

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
