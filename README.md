# Savings Block

This is a basic Savings platform that Extends a Multi Level Marketing System for referrals 
Users can act as guarrantors for other users and Take Loans from the Vault of the smart contract

### Public Functions
- ##### Signup
    * @dev external function to track and manage user signup
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param _referrer [referrer which is the address of the referrer the user has]

    * REQUIREMENTS: 
    *   The user / msg.sender must hold the equivalent signup fee of $10
    *   The user cannot be referred by the Dead address
    *   The user cannot already be signed up
    *   The referree must be a signed up user
    *   The user must have enough USDT to pay for sign up
    *   The user must have granted usdt allowance
    *   The user cannot refer themselves
    

- ##### Save
    * @dev external function to Save with reentrancy guard to control _save function
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is the total amount of usdt in the transaction]
    
    * REQUIREMENTS: 
    *   The user / msg.sender must hold the equivalent usdt sent to contract


- ##### LendWithReferrals
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]

    * REQUIREMENTS: 
    *   The user / msg.sender must have collateral equal or more than the amout wanted
    *   The user cannot be the Dead address

- ##### LendWithGuarrantors
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]

    * REQUIREMENTS: 
    *   The user / msg.sender must have collateral equal or more than the amout wanted
    *   The user cannot be the Dead address

- ##### UserWithdraw
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]

    * REQUIREMENTS: 
    *   The user / msg.sender must own the amount about to be collected
    *   The user cannot be the Dead address

- ##### AdminWithdraw
    * @dev external function to Withdraw admin USDT
    * @param amount[_amount which is amount of usdt the user wants to withdraw from the system]

    * REQUIREMENTS: 
    *   The user / msg.sender must be an accepted admin address
    *   The user cannot be the Dead address

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
