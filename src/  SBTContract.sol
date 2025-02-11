// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
 
/**
 * @title SBTContract
 * @dev Implementation of a Soulbound Token (SBT) for Fadhili Chain donors
 * Non-transferable NFT that represents donor achievements and reputation
 */
contract SBTContract is ERC721, Ownable {
    
    using Strings for uint256;
 
    uint256 public _tokenId;
 
    // Custom errors
    error TokenAlreadyMinted();
    error TokenNotTransferable();
    error InvalidMetadata();
 
    // Structs
    struct DonorMetadata {
        uint256 totalDonations;
        uint256 donationCount;
        string donorLevel;
        uint256 lastDonationTimestamp;
        string ipfsHash;
    }
 
    // State variables
    mapping(address => bool) public hasSBT;
    mapping(uint256 => DonorMetadata) public donorMetadata;
    mapping(address => uint256) public donorTokenIds;
 
    // Events
    event SBTMinted(address indexed donor, uint256 indexed tokenId, string donorLevel);
    event MetadataUpdated(uint256 indexed tokenId, uint256 totalDonations, uint256 donationCount);
 
    constructor() ERC721("Fadhili Donor SBT", "FDSBT") Ownable(msg.sender) {}
 
    // Modifiers
    modifier onlyTokenHolder(address donor) {
        require(hasSBT[donor], "Not a token holder");
        _;
    }
 
    /**
     * @dev Mint a new Soulbound Token for a donor
     * @param to Address of the donor
     * @param ipfsHash IPFS hash containing additional donor metadata
     */
    function mintSBT(address to, string memory ipfsHash) external onlyOwner {
        if (hasSBT[to]) revert TokenAlreadyMinted();
        if (bytes(ipfsHash).length == 0) revert InvalidMetadata();
 
        uint256 tokenId =_tokenId;
        _tokenId++;
       
        _safeMint(to, tokenId);
       
        donorMetadata[tokenId] = DonorMetadata({
            totalDonations: 0,
            donationCount: 0,
            donorLevel: "Bronze",
            lastDonationTimestamp: block.timestamp,
            ipfsHash: ipfsHash
        });
 
        hasSBT[to] = true;
        donorTokenIds[to] = tokenId;
 
        emit SBTMinted(to, tokenId, "Bronze");
    }
 
    /**
     * @dev Update donor metadata after a donation
     * @param donor Address of the donor
     * @param donationAmount Amount donated
     */
    function updateDonorMetadata(address donor, uint256 donationAmount)
        external
        onlyOwner
        onlyTokenHolder(donor)
    {
        uint256 tokenId = donorTokenIds[donor];
        DonorMetadata storage metadata = donorMetadata[tokenId];
       
        metadata.totalDonations += donationAmount;
        metadata.donationCount += 1;
        metadata.lastDonationTimestamp = block.timestamp;
       
        // Update donor level based on total donations
        metadata.donorLevel = _calculateDonorLevel(metadata.totalDonations);
 
        emit MetadataUpdated(tokenId, metadata.totalDonations, metadata.donationCount);
    }
 
    /**
     * @dev Get donor level based on total donations
     * @param totalDonations Total amount donated
     */
    function _calculateDonorLevel(uint256 totalDonations) internal pure returns (string memory) {
        if (totalDonations >= 10000 ether) return "Diamond";
        if (totalDonations >= 5000 ether) return "Platinum";
        if (totalDonations >= 1000 ether) return "Gold";
        if (totalDonations >= 500 ether) return "Silver";
        return "Bronze";
    }
 
    /**
     * @dev Generate token URI with on-chain metadata
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        DonorMetadata memory metadata = donorMetadata[tokenId];
 
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "Fadhili Donor #',
                    tokenId.toString(),
                    '", "description": "Fadhili Chain Donor Achievement Token", ',
                    '"attributes": [{"trait_type": "Donor Level", "value": "',
                    metadata.donorLevel,
                    '"}, {"trait_type": "Total Donations", "value": "',
                    metadata.totalDonations.toString(),
                    '"}, {"trait_type": "Donation Count", "value": "',
                    metadata.donationCount.toString(),
                    '"}], "image": "ipfs://',
                    metadata.ipfsHash,
                    '"}'
                )
            ))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
 

 
    /**
     * @dev Override transfer functions to make tokens soulbound
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal  {
        //super._beforeTokenTransfer(from, to, tokenId);
       
        // Allow minting but prevent transfers
        if (from != address(0) && to != address(0)) {
            revert TokenNotTransferable();
        }
    }
 
    /**
     * @dev Returns the donor's token ID
     * @param donor Address of the donor
     */
    function getDonorTokenId(address donor) external view returns (uint256) {
        require(hasSBT[donor], "Donor has no SBT");
        return donorTokenIds[donor];
    }
 
    /**
     * @dev Returns donor's metadata
     * @param donor Address of the donor
     */
    function getDonorMetadata(address donor) external view returns (DonorMetadata memory) {
        require(hasSBT[donor], "Donor has no SBT");
        return donorMetadata[donorTokenIds[donor]];
    }
    /**
 * @dev Returns the donor's Soulbound Token ID, or 0 if they have none
 * @param donor Address of the donor
 */
function getDonorSBT(address donor) external view returns (uint256) {
    if (!hasSBT[donor]) {
        return 0;
    }
    return donorTokenIds[donor];
}
function updateSBT(uint256 tokenId, uint256 donationAmount) external onlyOwner {
    DonorMetadata storage metadata = donorMetadata[tokenId];

    metadata.totalDonations += donationAmount;
    metadata.donationCount += 1;
    metadata.lastDonationTimestamp = block.timestamp;

    // Update donor level based on total donations
    metadata.donorLevel = _calculateDonorLevel(metadata.totalDonations);

    emit MetadataUpdated(tokenId, metadata.totalDonations, metadata.donationCount);
}
}