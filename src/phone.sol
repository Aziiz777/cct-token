// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IBurnMintERC20} from "./interface/IBurnMintERC20.sol";

contract phoneToken is ERC20, ERC20Burnable, AccessControl, IBurnMintERC20 {
    address private immutable i_CCIPAdmin;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant FEE_BASIS_POINTS = 100; // 1% = 100 basis points
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;
    address public feeRecipient;

    // Max supply: 420,069,000,000 tokens with 18 decimals
    uint256 public constant MAX_SUPPLY = 420_069_000_000 * 10**18;
    uint256 public constant INITIAL_MINT = MAX_SUPPLY * 14 / 100; // 14% of max supply
    uint256 public constant MONTHLY_MINT_LIMIT = MAX_SUPPLY / 100; // 1% of max supply
    
    // Minting restriction variables
    uint256 public lastMintTimestamp;
    uint256 public monthlyMintedAmount;
    uint256 public constant MONTH_DURATION = 30 days;

    // Whitelist mapping
    mapping(address => bool) public isWhitelisted;

    constructor(address admin) ERC20("phone", "ph") {
        i_CCIPAdmin = msg.sender; // CCIP admin is the deployer
        feeRecipient = admin;

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);

        // Whitelist the admin
        isWhitelisted[admin] = true;

        // Initial mint of 15% to admin
        _mint(admin, INITIAL_MINT);
        lastMintTimestamp = block.timestamp;
    }

    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }
    // Whitelist management functions
    function addToWhitelist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Cannot whitelist zero address");
        isWhitelisted[account] = true;
    }

    function removeFromWhitelist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isWhitelisted[account] = false;
    }

    // Mint function with monthly limit
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint would exceed max supply");
        
        // Check if a new month has started
        if (block.timestamp >= lastMintTimestamp + MONTH_DURATION) {
            monthlyMintedAmount = 0;
            lastMintTimestamp = block.timestamp - (block.timestamp % MONTH_DURATION); // Reset to start of month
        }
        
        // Check monthly mint limit
        require(monthlyMintedAmount + amount <= MONTHLY_MINT_LIMIT, "Exceeds monthly mint limit");
        
        _mint(account, amount);
        monthlyMintedAmount += amount;
    }

    // Burn functions
    function burn(uint256 amount) public override(IBurnMintERC20, ERC20Burnable) onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override(IBurnMintERC20, ERC20Burnable) onlyRole(BURNER_ROLE) {
        super.burnFrom(account, amount);
    }

    function burn(address account, uint256 amount) public override {
        burnFrom(account, amount);
    }

    // Getter for CCIP admin
    function getCCIPAdmin() public view returns (address) {
        return i_CCIPAdmin;
    }

    // Set fee recipient
    function setFeeRecipient(address _feeRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    // Custom transfer function with fee and whitelist check
    function transferWithFee(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (isWhitelisted[msg.sender] || isWhitelisted[recipient]) {
            _transfer(msg.sender, recipient, amount);
        } else {
            uint256 feeAmount = (amount * FEE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;
            uint256 transferAmount = amount - feeAmount;

            _transfer(msg.sender, feeRecipient, feeAmount);
            _transfer(msg.sender, recipient, transferAmount);
        }

        return true;
    }

    // Override transfer
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        return transferWithFee(recipient, amount);
    }

    // Override transferFrom
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        if (isWhitelisted[sender] || isWhitelisted[recipient]) {
            _transfer(sender, recipient, amount);
            _approve(sender, msg.sender, currentAllowance - amount);
        } else {
            uint256 feeAmount = (amount * FEE_BASIS_POINTS) / BASIS_POINTS_DENOMINATOR;
            uint256 transferAmount = amount - feeAmount;

            _transfer(sender, feeRecipient, feeAmount);
            _transfer(sender, recipient, transferAmount);
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    // Function to check remaining monthly mint allowance
    function getRemainingMonthlyMint() public view returns (uint256) {
        if (block.timestamp >= lastMintTimestamp + MONTH_DURATION) {
            return MONTHLY_MINT_LIMIT;
        }
        return MONTHLY_MINT_LIMIT - monthlyMintedAmount;
    }
}