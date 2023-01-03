// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    ///@notice Show transfer event between users
    event Transfer(address indexed from, address indexed to, uint256 value);

    ///@notice Show approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    ///@notice Check balance of user address
    function balanceOf(address account) external view returns (uint256);

    ///@notice Transfer ERC 20 tokens Between Users
    function transfer(address to, uint256 amount) external returns (bool);

    ///@notice  Check total Approved token of address
    function allowance(address owner, address spender) external view returns (uint256);

    ///@notice  Approve ERC 20 transfer from Address by contract
    function approve(address spender, uint256 amount) external returns (bool);

    ///@notice Delegate tranfer function to third party
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title  SavingsBlock
 * @author Ebenezer Akpas
 * @notice Savings Block is a contract to help facilitate user
 *         savings stictly in Usdt
 *         A sign up fee is required to use the service 
 *         It supports SignUp, Withdrawal and Loaning
 */
contract SavingBlock is ReentrancyGuard{
    using SafeMath for uint;
    address Dead = 0x000000000000000000000000000000000000dEaD;

    IERC20 public USDT; // Address of primary exchange token of contract
    address public Admin;
    uint public Decimal;
    uint public SignUpFee;

    /**
     * @dev structs of user personal finances in system
     * @notice User finance must be accessed by mapping 
     *         USERFINANCE
     * */
    struct UserFinance{
        ///@notice Total savings in user savings block account 
        uint totalSavings;

        ///@notice Total savings user has access to (90%)
        uint Savings;

        ///@notice Total amout earned through referrals
        uint totalReferralEarned;

        ///@notice Total amount of Usdt a user has borrowed from the system
        uint totalUSDTBorrowed;

        ///@notice Total amount of Usdt a user still owes the system
        uint totalUSDTOwed;

        ///@notice Total amount of Usdt a user has payed back to the system
        uint totalPayed;
    }

    /**
     * @dev structs of user data in the system
     * @notice User finance must be accessed by mapping 
     *         USERDATABASE
     * */
    struct UserDatabase{
        ///@notice Address of users Direct Upline
        address DirectUpline;

        ///@notice Array storage of downline addresses
        address [] downlineAdresses;

        ///@notice Total approved lenders on users upline
        uint approvedLenders;

        ///@notice Total Number of approved lenders
        address [] allApprovedLenders;

        ///@notice Total amount saved by all approved lenders
        uint totalLenderbalance;

        ///@notice Flag to check when a user is signed Up False when they are not
        bool signedUp;
    }

    /**
     * @dev struct to confirm user recieved a grant from another 
     * @notice GuarantorChecker must be accessed by mapping 
     *         GUARANTORCHECKER
     * */
    struct GuarantorChecker{
        ///@notice Address of user to act as guarrantor
        address [] guarantorAddress;

        ///@notice Total number of guarantors
        uint totalguarantors;

        mapping (address => mapping (address => guarantor_details)) GuarantorDetails;
    }

    struct guarantor_details{
        uint amountGuaranteed;
        uint paymentDeadLine;
        bool Paid;

    }

    /**
     * @dev struct to act as public database of users 
     * @notice AdminData is initialised as ADMINDATA
     * */
    struct AdminData{
        ///@notice Total amount of users registered to the system
        uint totalUsers; //Total amount of users registered to the system

        ///@notice 
        uint totalUSDTSaved; // Total amount of USDT saved to the system

        ///@notice 
        uint totalUSDTWithdrawn; // Total amount of USDT withdrawn from the system

        ///@notice 
        uint totalUSDTLended; // Total amount of USDT lended to users

        ///@notice 
        uint totalAdminBonus; // Total amout of USDT earned by Admin Referrals

    }

    ///@notice mapping to access UserFinance struct
    mapping(address => UserFinance) public USERFINANCE;

    ///@notice mapping to access userDatabase struct
    mapping(address => UserDatabase) public USERDATABASE;

    ///@notice mapping to access guarantor list
    mapping(address => GuarantorChecker) public GUARANTORCHECKER;

    ///@notice instantiation of adminData struct
    AdminData public ADMINDATA;

    /// @notice Event emitted when a new User has Signed Up
    ///Params:
    ///     @param userAccountNumber holds the address of the new user that signed up
    ///     @param DirectUpline holds the address of the referee as the direct upline
    event NewUserAdded(address userAccountNumber, address DirectUpline);

    /// @notice Event emitted when a user makes a Deposit
    ///Params:
    ///     @param userAccountNumber holds the address of the user that made a deposit
    ///     @param totalDeposit holds ammount of money the user put in during his saving
    ///     @param depositAfterFee holds the amount of money that was charged as fee for the savings
    event DepositSuccessful(address userAccountNumber,uint totalDeposit, uint depositAfterFee);

    /// @notice Event emitted When a user burrows successfully
    ///Params:
    ///     @param borrowerAccount holds the address of the burrower
    ///     @param AmountBorrowed holds ammount of money burrowed by the user during this transaction
    event BorrowingSuccessful(address borrowerAccount, uint AmountBorrowed);

    /// @notice Event emitted when a user makes a withdrawal and closes their account 
    ///Params:
    ///     @param withdrawAccount holds the address of the withdrawer
    ///     @param withdrawAmount holds ammount of money withdrawn by the user during this transaction
    event UserWithdrawCompleted(address withdrawAccount, uint withdrawAmount);

    /// @notice Event emitted when admin makes a withdrawal
    ///Params:
    ///     @param AdminAddress holds the address of the withdrawer
    ///     @param Amount holds ammount of money withdrawn by the user during this transaction
    event AdminWithdrawCompleted(address AdminAddress, uint Amount);


    /**
    * @dev add addmin Owner address and Usdt contract address
    * @notice for security admin address is private and not public
    * Params:
    *       @param _admin Admin address for owner contract
    *       @param _usdt usdt address of token
    *       
    */
    constructor(
        address _admin, 
        IERC20 _usdt, 
        uint _decimal, 
        uint _signupFee
        ){
        Admin = _admin;
        USDT = _usdt;
        Decimal = 10**_decimal;
        SignUpFee = _signupFee.mul(Decimal);
    }

    /**
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
    */
    function SignUp(
        address _referrer
        ) public {
        UserDatabase storage USER = USERDATABASE[msg.sender];
        UserDatabase storage REFER = USERDATABASE[_referrer];

        //checker to confirm user has approved this fee before signup
        uint allowance = USDT.allowance(msg.sender, address(this));

        require (_referrer != Dead,
                "You cannot send to the dead address");
        require (USER.signedUp == false, 
                "This user is already signed up for this service");
        require (REFER.signedUp != false || _referrer == Admin, 
                "The referrer is not yet signed up to this service");
        require (_referrer != msg.sender, 
                "You cannot refer yourself");
        require (allowance >= SignUpFee, 
        "You have not allowed this contract to collect the Sign up fee");
        /*
        * A conditional is used to check the address of the referrer
        * If conditional fails:
        *   A dead address is assigned to referrer 1
        */
        if (_referrer != Admin) {
            USER.DirectUpline = _referrer;
            REFER.downlineAdresses.push(msg.sender);
        }else{
            USER.DirectUpline = Admin;
        }

        //if all conditional and checks pass, 
        //transfer Fee from user address to contract
        USDT.transferFrom(msg.sender, address(this), SignUpFee);

        //set refferer as Direct upline
        USER.DirectUpline = _referrer;

        //if all checks pass update admin database
        ADMINDATA.totalUsers += 1;
        ADMINDATA.totalAdminBonus += SignUpFee;

        //confirm user has signed up for this service
        USER.signedUp = true;
        emit NewUserAdded(msg.sender, _referrer);
        console.log("A new User with address (%o), Signed up to use this service with referrer (%o) at block timestamp of (%o)", msg.sender, _referrer, block.timestamp);

    }


    /**
    * @dev internal function to control and effect savings
    * @notice for security the _save function is private and holds the save effects
    * Params:
    *       @param _amount Admin address for owner contract 
    * REQUIREMENTS: 
    *   The user / msg.sender must have signed up to use this service
    */
    function _save(uint _amount) internal {

        //Check that user has signed up for this service
        require(USERDATABASE[msg.sender].signedUp, "YOU HAVE NOT SIGNED UP FOR THIS SERVICE");
        
        UserFinance storage USERBAL = USERFINANCE[msg.sender];
        UserDatabase storage USERDAT = USERDATABASE[msg.sender];

        //uint to calculate 90% of deposit
        uint NinetyPercent = _amount.sub(_amount.div(100).mul(10));
        //uint to calculate 10% of deposit
        uint TenPercent = _amount.sub(NinetyPercent);
        //uint to calculate 2% of deposit
        uint TwoPercent = TenPercent.div(5);
        //uint to calculate 4% of deposit
        uint FourPercent = TwoPercent.add(TwoPercent);
        //uint to calculate 8% of deposit
        uint EightPercent = FourPercent.add(FourPercent);

        //add deposit to user total savings
        USERBAL.totalSavings += _amount;
        //add 90% to users actual savings 
        USERBAL.Savings += NinetyPercent;
        //updat main database with new deposit
        ADMINDATA.totalUSDTSaved += (_amount);

        /*
        * A conditional to confirm and distribute percentage earnings upwards
        * Direct Upline cannot be Dead address
        */
        if (USERDAT.DirectUpline != Admin && USERDAT.DirectUpline != Dead) {
            USERFINANCE[USERDAT.DirectUpline].totalReferralEarned += TwoPercent; 
            address referrer2 = USERDATABASE[USERDAT.DirectUpline].DirectUpline;
            if (referrer2 != Admin) {
              USERFINANCE[referrer2].totalReferralEarned += TwoPercent;
              address referrer3 = USERDATABASE[referrer2].DirectUpline;
              if (referrer3 != Admin) {
                  USERFINANCE[referrer3].totalReferralEarned += TwoPercent;
                  ADMINDATA.totalAdminBonus += FourPercent;
              }
            }else{
              ADMINDATA.totalAdminBonus += EightPercent;
            }
        }else{
          ADMINDATA.totalAdminBonus += TenPercent;
        }
        //if all checks pass move USDT from user wallet to contact
        USDT.transferFrom(msg.sender,address(this), _amount.mul(Decimal));

        // Emit event to show successful deposit
        emit DepositSuccessful(msg.sender, _amount, NinetyPercent);
        console.log("User address (%o), made a Deposit of (%o) at block timestamp of (%o)", msg.sender, _amount, block.timestamp);

    }

    /**
    * @dev external function to Save with reentrancy guard to control _save function
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is the total amount of usdt in the transaction]
    *
    * REQUIREMENTS: 
    *   The user / msg.sender must hold the equivalent usdt sent to contract
    *   The user / msg.sender must have signed up to use this service
    * @return true if transaction is successfull
    */
    function Save(uint amount) external nonReentrant returns (bool){
      require (USDT.balanceOf(msg.sender) >= amount**Decimal, 
              "YOU DO NOT HAVE ENOUGH USDT TO COMPLETE THIS TANSACTION");
      _save(amount);    
      return(true);
    }

    /**
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    * 
    *REQUIREMENTS: 
        The user / msg.sender must have signed up to use this service
    *   The user / msg.sender must have collateral equal or more than the amout wanted
    *   The user cannot be the Dead address
    * @return true if transaction is successfull
    */
    function LendWithReferrals(uint amount, uint _collateral) external nonReentrant returns (bool){
        
        UserFinance storage USERBAL = USERFINANCE[msg.sender];

        //Check that user has signed up for this service
        require(USERDATABASE[msg.sender].signedUp, "YOU HAVE NOT SIGNED UP FOR THIS SERVICE");

        //check that message sender is not the dead address
        require (msg.sender != Dead, "The Dead address is not allowed to lend or Burrow");

        //check that the amount burrowed is not less than users withdrawal amount
        require (_collateral >= amount, "Your Collateral is lesser then the amount you want to burrow");

        // if all checks pass, transfer the amount of USDT to user wallet
        USDT.transfer(msg.sender, amount.mul(Decimal));

        //if all checks pass, add burrowed USDT amount to user finance
        USERBAL.totalUSDTBorrowed += amount;
        USERBAL.totalUSDTOwed += amount;

        //if all checks pass, update admin database
        ADMINDATA.totalUSDTLended += amount;

        // Emit event to show successful deposit
        emit BorrowingSuccessful(msg.sender, amount);
        console.log("User address (%o), made Burrowed (%o) at block timestamp of (%o)", msg.sender, amount, block.timestamp);


        return(true);
    }

    /**
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must have signed up to use this service
    *   The user / msg.sender must have collateral equal or more than the amout wanted
    *   The user cannot be the Dead address
    * @return true if transaction is successfull
    */
    function LendWithGuarrantors(uint amount, address [] memory guarantors, uint deadline) external nonReentrant returns(bool){
        //Check that user has signed up for this service
        require(USERDATABASE[msg.sender].signedUp, "YOU HAVE NOT SIGNED UP FOR THIS SERVICE");

        UserFinance storage USERBAL = USERFINANCE[msg.sender];

        GuarantorChecker storage GUARANTOR = GUARANTORCHECKER[msg.sender];
        // amount of Burrowed money each guarantor owed individually
        uint eachOwed = amount/guarantors.length;

        //intantiate value for remainders
        uint remainder = amount%guarantors.length;

        //loop through list of guarantors one by one 
        for (uint i; i < guarantors.length; i++) {
            // Confirm that no guarantor is a Dead address
            require (guarantors[i] != Dead, "One of your guarantors is the DEaD address");

            //Instantiate each guarantor
            guarantor_details storage GUARANTORDETAILS = GUARANTOR.GuarantorDetails[msg.sender][guarantors[i]];

            //pass the amount of money owed by each guarantor into the inferface
            GUARANTORDETAILS.amountGuaranteed = eachOwed;
            GUARANTORDETAILS.paymentDeadLine = deadline;
        }

        /*
        * Conditional to give any remainders to firse guarantor
        */
        if  (remainder != 0) {
            guarantor_details storage GUARANTORDETAILS = GUARANTOR.GuarantorDetails[msg.sender][guarantors[1]];
            GUARANTORDETAILS.amountGuaranteed += remainder;
        }

        //if all checks are passed and all guarantors are utilized 
        //  transfer the amount of USDT to user wallet
        USDT.transfer(msg.sender, amount.mul(Decimal));

        //if all checks pass, add burrowed USDT amount to user finance
        USERBAL.totalUSDTBorrowed += amount;
        USERBAL.totalUSDTOwed += amount;

        //if all checks pass, update admin database
        ADMINDATA.totalUSDTLended += amount;

        // Emit event to show successful deposit
        emit BorrowingSuccessful(msg.sender, amount);
        console.log("User address (%o), made Burrowed (%o) at block timestamp of (%o)", msg.sender, amount, block.timestamp);


        return(true);
    }

    /**
    * @dev internal function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    * *REQUIREMENTS: 
    *   The user / msg.sender must have signed up to use this service
    */
    function _userWithdraw(uint amount) internal {
        //Check that user has signed up for this service
        require(USERDATABASE[msg.sender].signedUp, "YOU HAVE NOT SIGNED UP FOR THIS SERVICE");

        //If all checks pass update user finance
        UserFinance storage USERBAL = USERFINANCE[msg.sender];
        USERBAL.totalSavings -= amount;
        USERBAL.Savings -= amount;

        //if all checks pass update admin data
        ADMINDATA.totalUSDTWithdrawn += amount;

        //if all checks pass, transfer USDT to user
        USDT.transfer(address(this), amount.mul(Decimal));
    }
    /**
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must own the amount about to be collected
    *   The user cannot be the Dead address
    */
    function UserWithdraw(uint amount) external nonReentrant {
        //Check that user address is not the dead address
        require(msg.sender != Dead);

        //Instantiate User Finance
        UserFinance storage USERBAL = USERFINANCE[msg.sender];

        //Check that user has enough balance to complete withdrawal
        require(USERBAL.Savings >= amount, "Insufficient Saving block funds");
        
        //if all checks pass, then send amount to internal function to complete tansaction
        _userWithdraw(amount);

        // Emit event to show transaction was completed
        emit UserWithdrawCompleted(msg.sender, amount);
        console.log("User address (%o), made withdrawal of (%o) at block timestamp of (%o)", msg.sender, amount, block.timestamp);

    }


    /**
    * @dev external function to Withdraw admin USDT
    * @param amount[_amount which is amount of usdt the user wants to withdraw from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must be an accepted admin address
    *   The user cannot be the Dead address
    * @return true if transaction is successfull
    */
    function AdminWithdraw(uint amount) external nonReentrant returns(bool){
        // Check that message sender is admin and grant access to function
        require(msg.sender == Admin, "Only the admin can use this function");

        //check that message sender is not he dead address
        require(msg.sender != Dead, "The dead address cannot call this function");

        //if all checks pass, update admin database
        ADMINDATA.totalAdminBonus -= amount;

        //if all checks pass, transfer USDT to admin address
        USDT.transfer(msg.sender, amount);
        
        //Emit event to show successful withdrawal by admin
        emit AdminWithdrawCompleted(msg.sender, amount);
        console.log("Admin address (%o), made withdrawal of (%o) at block timestamp of (%o)", msg.sender, amount, block.timestamp);
        return true;
    }
    /**
     * Update Function before Deployment 
    function EmgentWithd(uint amount) external nonReentrant returns(bool) {
    }
    */
}
