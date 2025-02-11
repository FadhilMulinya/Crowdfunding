// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
import "./  SBTContract.sol";
 
/**
 * @title DonationContract
 * @dev A secure donation platform for charitable giving on Celo
 * @custom:security-contact security@fadhilichain.com
 */
contract DonationContract is  ReentrancyGuard , SBTContract{
    using SafeERC20 for IERC20;

//    bytes32 public constant DEFAULT_ADMIN_ROLE = abi.encode
    
 
    // Custom errors for gas optimization
    error InvalidAmount();
    error CharityNotRegistered();
    error CharityNotVerified();
    error CharityAlreadyRegistered();
    error TokenNotSupported();
    error TransferFailed();
    error InvalidAddress();
 
    // State variables
    SBTContract public immutable sbtContract;
    uint256 private _donationIdCounter;
 
    // Supported stablecoins
    IERC20 public immutable cUSD;
    IERC20 public immutable cKES;
    IERC20 public immutable USDC;
 
    // Structs
    struct Charity {
        address payable walletAddress;
        string name;
        string description;
        string ipfsHash;
        bool isVerified;
        uint256 totalDonations;
        uint256 donorCount;
        mapping(address => uint256) donorContributions;
        uint256 createdAt;
        uint256 lastUpdated;
    }
 
    struct DonationInfo {
        uint256 donationId;
        address donor;
        address charity;
        uint256 amount;
        address tokenAddress;
        string message;
        uint256 timestamp;
    }
 
    // Mappings
    mapping(address => Charity) private charities;
    mapping(uint256 => DonationInfo) private donations;
    mapping(address => bool) private supportedTokens;
    mapping(address => uint256[]) private charityDonations;
    mapping(address => uint256[]) private donorHistory;
 
    // Events
    event CharityRegistered(
        address indexed charityAddress,
        string name,
        string ipfsHash,
        uint256 timestamp
    );
    event DonationMade(
        uint256 indexed donationId,
        address indexed donor,
        address indexed charity,
        uint256 amount,
        address tokenAddress,
        uint256 timestamp
    );
    event CharityVerified(address indexed charity, uint256 timestamp);
    event CharityUpdated(address indexed charity, string newIpfsHash, uint256 timestamp);
    event TokenStatusUpdated(address indexed token, bool supported);
    event EmergencyWithdraw(address indexed token, address indexed to, uint256 amount);
 
    /**
     * @dev Contract constructor
     * @param _sbtContract Address of the SBT contract
     * @param _cUSD Address of cUSD token
     * @param _cKES Address of cKES token
     * @param _USDC Address of USDC token
     */
    constructor(
        address _sbtContract,
        address _cUSD,
        address _cKES,
        address _USDC
    ) {
        if (_sbtContract == address(0) || _cUSD == address(0) ||
            _cKES == address(0) || _USDC == address(0)) revert InvalidAddress();
 
        sbtContract = SBTContract(_sbtContract);
        cUSD = IERC20(_cUSD);
        cKES = IERC20(_cKES);
        USDC = IERC20(_USDC);
 
        supportedTokens[_cUSD] = true;
        supportedTokens[_cKES] = true;
        supportedTokens[_USDC] = true;
 
        // Set initial permissions
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
 
    /**
     * @dev Register a new charity
     * @param name Charity name
     * @param description Charity description
     * @param ipfsHash IPFS hash of charity metadata
     */
    function registerCharity(
        string calldata name,
        string calldata description,
        string calldata ipfsHash
    ) external  {
        if (charities[msg.sender].walletAddress != address(0))
            revert CharityAlreadyRegistered();
        if (bytes(name).length == 0 || bytes(ipfsHash).length == 0)
            revert InvalidAddress();
 
        Charity storage charity = charities[msg.sender];
        charity.walletAddress = payable(msg.sender);
        charity.name = name;
        charity.description = description;
        charity.ipfsHash = ipfsHash;
        charity.createdAt = block.timestamp;
        charity.lastUpdated = block.timestamp;
 
        emit CharityRegistered(msg.sender, name, ipfsHash, block.timestamp);
    }
 
    /**
     * @dev Make a donation using supported stablecoins
     * @param charity Address of the charity
     * @param tokenAddress Address of the token being donated
     * @param amount Amount to donate
     * @param message Donation message
     */
    function makeTokenDonation(
        address payable charity,
        address tokenAddress,
        uint256 amount,
        string calldata message
    ) external nonReentrant  {
        if (!supportedTokens[tokenAddress]) revert TokenNotSupported();
        if (amount == 0) revert InvalidAmount();
        if (!_isValidCharity(charity)) revert CharityNotRegistered();
        if (!charities[charity].isVerified) revert CharityNotVerified();
 
        IERC20 token = IERC20(tokenAddress);
       
        // Transfer tokens using SafeERC20
        token.safeTransferFrom(msg.sender, charity, amount);
 
        // Update donation records
        _processDonation(charity, msg.sender, amount, tokenAddress, message);
    }
 
    /**
     * @dev Process donation records and update stats
     */
    function _processDonation(
        address charity,
        address donor,
        uint256 amount,
        address tokenAddress,
        string calldata message
    ) private {
        uint256 donationId = _donationIdCounter;
        _donationIdCounter++;
 
        DonationInfo storage donation = donations[donationId];
        donation.donationId = donationId;
        donation.donor = donor;
        donation.charity = charity;
        donation.amount = amount;
        donation.tokenAddress = tokenAddress;
        donation.message = message;
        donation.timestamp = block.timestamp;
 
        charityDonations[charity].push(donationId);
        donorHistory[donor].push(donationId);
 
        Charity storage charityData = charities[charity];
        charityData.totalDonations += amount;
        if (charityData.donorContributions[donor] == 0) {
            charityData.donorCount++;
        }
        charityData.donorContributions[donor] += amount;
        charityData.lastUpdated = block.timestamp;
 
        // Update or mint SBT
        uint256 tokenId = sbtContract.getDonorSBT(donor);
        if (tokenId == 0) {
            sbtContract.mintSBT(donor, "");
        } else {
            sbtContract.updateSBT(tokenId, amount);
        }
 
        emit DonationMade(
            donationId,
            donor,
            charity,
            amount,
            tokenAddress,
            block.timestamp
        );
    }
 
    // Admin functions
    /**
     * @dev Verify a charity
     * @param charityAddress Address of the charity to verify
     */
    function verifyCharity(address charityAddress)
        external{
        if (!_isValidCharity(charityAddress)) revert CharityNotRegistered();
        if (charities[charityAddress].isVerified) revert("Already verified");
 
        charities[charityAddress].isVerified = true;
        charities[charityAddress].lastUpdated = block.timestamp;
 
        emit CharityVerified(charityAddress, block.timestamp);
    }
 
    /**
     * @dev Update supported token status
     * @param tokenAddress Token address
     * @param isSupported Support status
     */
    function updateSupportedToken(address tokenAddress, bool isSupported)
        external
    {
        if (tokenAddress == address(0)) revert InvalidAddress();
        supportedTokens[tokenAddress] = isSupported;
        emit TokenStatusUpdated(tokenAddress, isSupported);
    }
 
    // View functions
    function getCharityDetails(address charityAddress)
        external
        view
        returns (
            string memory name,
            string memory description,
            string memory ipfsHash,
            bool isVerified,
            uint256 totalDonations,
            uint256 donorCount,
            uint256 createdAt,
            uint256 lastUpdated
        )
    {
        Charity storage charity = charities[charityAddress];
        return (
            charity.name,
            charity.description,
            charity.ipfsHash,
            charity.isVerified,
            charity.totalDonations,
            charity.donorCount,
            charity.createdAt,
            charity.lastUpdated
        );
    }
 
    function getDonationInfo(uint256 donationId)
        external
        view
        returns (DonationInfo memory)
    {
        return donations[donationId];
    }
 
    function getCharityDonations(address charity)
        external
        view
        returns (uint256[] memory)
    {
        return charityDonations[charity];
    }
 
    function getDonorHistory(address donor)
        external
        view
        returns (uint256[] memory)
    {
        return donorHistory[donor];
    }
 
    function isTokenSupported(address token)
        external
        view
        returns (bool)
    {
        return supportedTokens[token];
    }
 
    // Internal helper functions
    function _isValidCharity(address charity)
        internal
        view
        returns (bool)
    {
        return charities[charity].walletAddress != address(0);
    }
 
 
    /**
     * @dev Emergency withdraw function
     * @param token Token address to withdraw
     * @param to Address to send tokens to
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
 
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
 
        emit EmergencyWithdraw(token, to, amount);
    }
 

}