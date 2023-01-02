// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
        address guarantorAddress;

        ///@notice flag to check when user has guaranteed lending 
        bool guarranteed;
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
    mapping(address =>mapping (address => GuarantorChecker)) public GUARANTORCHECKER;

    ///@notice mapping to access adminData struct
    AdminData public ADMINDATA;

    ///@notice 
    event NewUserAdded(address userAccountNumber, address DirectUpline);

    ///@notice 
    event DepositSuccessful(address userAccountNumber,uint totalDeposit, uint depositAfterFee);

    ///@notice 
    event BorrowingSuccessful(address borrowerAccount, uint AmountBorrowed);

    ///@notice 
    event UserWithdrawCompleted(address withdrawAccount, uint withdrawAmount);

    ///@notice 
    event AdminWithdrawCompleted(address AdminAddress, uint Amount);


    /**
    * @dev add addmin Owner address and Usdt contract address
    * @notice for security admin address is private and not public
    * Params:
    *       @param _admin Admin address for owner contract
    *       @param _usdt usdt address of token
    *       
    */
    constructor(address _admin, IERC20 _usdt, uint _decimal, uint _signupFee){
        Admin = _admin;
        USDT = _usdt;
        Decimal = 10**_decimal;
        SignUpFee = _signupFee.mul(Decimal);
    }

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
    function SignUp(address _referrer) public {
      UserDatabase storage USER = USERDATABASE[msg.sender];
      UserDatabase storage REFER = USERDATABASE[_referrer];
      uint allowance = USDT.allowance(msg.sender, address(this));
      require (_referrer != Dead,
              "You cannot send to the dead address");
      require (USER.signedUp == false, 
              "This user is already signed up for this service");
      require (REFER.signedUp != false || _referrer == Admin, 
              "The referrer is not yet signed up to this service");
      require (_referrer != msg.sender, 
              "You cannot refer yourself");
      require (allowance >= SignUpFee, "You have not allowed this contract to collect the Sign up fee");
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
      USDT.transferFrom(msg.sender, address(this), SignUpFee);
      USER.DirectUpline = _referrer;
      ADMINDATA.totalUsers += 1;
      ADMINDATA.totalAdminBonus += SignUpFee;
      USER.signedUp = true;
      emit NewUserAdded(msg.sender, _referrer);
    }


    /**
    * @dev internal function to control and effect savings
    * @notice for security the _save function is private and holds the save effects
    * @param _amount, _referral [Admin address for owner contract , usdt address of token]
    */
    function _save(uint _amount) internal {
        UserFinance storage USERBAL = USERFINANCE[msg.sender];
        UserDatabase storage USERDAT = USERDATABASE[msg.sender];
        uint NinetyPercent = _amount.sub(_amount.div(100).mul(10));
        uint TenPercent = _amount.sub(NinetyPercent);
        uint TwoPercent = TenPercent.div(5);
        uint FourPercent = TwoPercent.add(TwoPercent);
        uint EightPercent = FourPercent.add(FourPercent);
        USERBAL.totalSavings += _amount;
        USERBAL.Savings += NinetyPercent;
        ADMINDATA.totalUSDTSaved += (_amount);
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
        emit DepositSuccessful(msg.sender, _amount, NinetyPercent);
    }

    /**
    * @dev external function to Save with reentrancy guard to control _save function
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is the total amount of usdt in the transaction]
    *
    * REQUIREMENTS: 
    *   The user / msg.sender must hold the equivalent usdt sent to contract
    */
    function Save(uint amount) external nonReentrant returns (bool){
      require (USDT.balanceOf(msg.sender) >= amount, 
              "YOU DO NOT HAVE ENOUGH USDT TO COMPLETE THIS TANSACTION");
      _save(amount);    
      return(true);
    }

    /**
    * @dev public function to calculate weather a user can burrow
    */
    function publicLendCalculator(uint amount)external view returns (bool){
      UserDatabase storage USERDAT = USERDATABASE[msg.sender];
      bool ValidLending;
      uint downLenderBalance;
      uint count = 0;
      for (uint i = 0; i < (USERDAT.allApprovedLenders).length ; i++){
        if (USERDAT.downlineAdresses[count] != Dead){
            downLenderBalance = USDT.balanceOf(USERDAT.downlineAdresses[count]);
            count++;
        }else{
          count++;
        }
        if (amount <= downLenderBalance){
            ValidLending = true;
        }else{
          ValidLending = false;
        }
      }
      return (ValidLending);
    }

    /**
    * @dev internal function to calculate the amount a user is allowed to burrow
    */
    function _lendCalculator()internal returns (uint){
      UserDatabase storage USERDAT = USERDATABASE[msg.sender];
      uint count = 0;
      for (uint i = 0; i < (USERDAT.allApprovedLenders).length ; i++){
        if (USERDAT.downlineAdresses[count] != Dead){
            uint downLenderBalance = USDT.balanceOf(USERDAT.downlineAdresses[count]);
            uint totalLenderbalance = downLenderBalance;
            USERDAT.totalLenderbalance += totalLenderbalance;
            count++;
        }else{
          count++;
        }
      }
      return (USERDAT.totalLenderbalance);
    }

    /**
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must have collateral equal or more than the amout wanted
    *   The user cannot be the Dead address
    */
    function LendWithReferrals(uint amount) external nonReentrant returns (bool){
      require (msg.sender != Dead, "The Dead address is not allowed to lend or Burrow");
      UserFinance storage USERBAL = USERFINANCE[msg.sender];
      uint Collateral = _lendCalculator();

      require (Collateral >= amount, "Your Collateral is lesser then the amount you want to burrow");
      USDT.transfer(msg.sender, amount);
      USERBAL.totalUSDTBorrowed += amount;
      USERBAL.totalUSDTOwed += amount;
      ADMINDATA.totalUSDTLended += amount;
      emit BorrowingSuccessful(msg.sender, amount);
      return(true);
    }

    /**
    * @dev external function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must have collateral equal or more than the amout wanted
    *   The user cannot be the Dead address
    */
    function LendWithGuarrantors(uint amount, address [] memory guarantors) external nonReentrant returns(bool){
      require (guarantors[Dead] == false, "One of your guarantors is the DEaD address");
      GuarantorChecker storage GUARANTOR = GUARANTORCHECKER[lender][msg.sender];
      for(uint i = 0; i < guarantors.legth ; i++) {
        require(GUARANTOR.guaranteed == true, "YOU HAVE NOT YET BEEN GRANTED A GUARANTEE FROM THIS USER");
      }

    }

    function AcceptGuarantor(address lender) public {
      GuarantorChecker storage GUARANTOR = GUARANTORCHECKER[lender][msg.sender];
      GUARANTOR.guarranteed = true;
    }

    /**
    * @dev internal function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    
    */
    function _userWithdraw(uint amount) internal {
      UserFinance storage USERBAL = USERFINANCE[msg.sender];
      USERBAL.totalSavings -= amount;
      USERBAL.Savings -= amount;
      ADMINDATA.totalUSDTWithdrawn += amount;
    }
    /**
    * @dev internal function to Lend usdt from the savings block system
    * @notice for security the Save function is nonReentrant to prevent attacks
    * @param amount[_amount which is amount of usdt the user wants to borrow from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must own the amount about to be collected
    *   The user cannot be the Dead address
    */
    function UserWithdraw(uint amount) external nonReentrant {
      require(msg.sender != Dead);
      UserFinance storage USERBAL = USERFINANCE[msg.sender];
      require(USERBAL.Savings >= amount, "Insufficient Saving block funds");
      _userWithdraw(amount);
      emit UserWithdrawCompleted(msg.sender, amount);
    }


    /**
    * @dev internal function to Withdraw admin USDT
    * @param amount[_amount which is amount of usdt the user wants to withdraw from the system]
    *REQUIREMENTS: 
    *   The user / msg.sender must be an accepted admin address
    *   The user cannot be the Dead address
    */
    function AdminWithdraw(uint amount) external nonReentrant returns(bool){
      require(msg.sender == Admin, "Only the admin can use this function");
      require(msg.sender != Dead, "The dead address cannot call this function");
      ADMINDATA.totalAdminBonus -= amount;
      USDT.transfer(msg.sender, amount);
      emit AdminWithdrawCompleted(msg.sender, amount);
      return true;
    }
}