// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

// interface IPFS {
//     function upload(string memory _data) external returns (bytes32);
// }

contract PadiRegistry is Ownable {
    using ECDSA for bytes32;

    // Enum to represent user tags
    enum UserTag { USER, PADI, VERIFIER }

    // Structure to represent user data
    struct UserData {
        string passportNumber;
        address userAddress;
        bool hasHexID;
    }


    // Mapping from unique ID to user data
    mapping(bytes32 => UserData) public userData;

    // Mapping from user address to verifier addresses
    mapping(address => address[]) public verifiers;

    // Mapping from verifier address to charges
    mapping(address => uint256) public verificationCharges;

    // Mapping from address to tag (USER for user, PADI for padi, VERIFIER for verifier)
    mapping(address => UserTag) public addressTags;

    // Mapping from user address to hexIDs
    mapping(address => bytes32) public userHexIDs;


    // IPFS contract address
    address public ipfsContractAddress;
    address public padiAddress;


    // Event emitted when a user adds a verifier
    event VerifierAdded(address indexed user, address indexed verifier);

    // Event emitted when a verifier charges are updated
    event VerificationChargesUpdated(address indexed verifier, uint256 charges);


    // Modifier to check if the sender has the verifier tag
    modifier onlyVerifier() {
        require(addressTags[msg.sender] == UserTag.VERIFIER, "Sender is not a verifier");
        _;
    }

    // Modifier to check if the sender has the padi tag
    modifier onlyPadi() {
        require(addressTags[msg.sender] == UserTag.PADI, "Sender is not a padi");
        _;
    }

    // Modifier to check if the sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner(), "Only the owner can call this function");
        _;
    }

    // Constructor to set the IPFS contract address and padi address
    // constructor(address _ipfsContractAddress, address _padiAddress) {
    //     ipfsContractAddress = _ipfsContractAddress;
    //     padiAddress = _padiAddress;
    // }
    constructor(address _padiAddress) {
        // ipfsContractAddress = _ipfsContractAddress;
        padiAddress = _padiAddress;
    }


    // Function to add a verifier
    function addVerifier(address _verifier) external {
        require(addressTags[msg.sender] == UserTag.USER, "Only users can add verifiers");
        verifiers[msg.sender].push(_verifier);
        addressTags[_verifier] = UserTag.VERIFIER; // Set verifier tag
        emit VerifierAdded(msg.sender, _verifier);
    }

    // Function to update verification charges
    function updateVerificationCharges(uint256 _charges) external onlyOwner {
        verificationCharges[msg.sender] = _charges;
        emit VerificationChargesUpdated(msg.sender, _charges);
    }

    // Function for a user to generate a unique ID using passport number and address
    function generateUniqueHexID(string memory _passportNumber) external {
        require(addressTags[msg.sender] == UserTag.USER, "Only users can generate hex IDs");

        // Check if the hex ID already exists
        require(!userData[msg.sender].hasHexID, "User already has a hex ID");

        // Generate unique ID using keccak256
        bytes32 uniqueId = keccak256(abi.encodePacked(msg.sender, _passportNumber));
        
        // Upload data to IPFS and get the hash
        // IPFS ipfsContract = IPFS(ipfsContractAddress);
        // bytes32 ipfsHash = ipfsContract.upload(_passportNumber);

        // Store user data
        userData[uniqueId] = UserData({
            passportNumber: _passportNumber,
            userAddress: msg.sender,
            hasHexID: true
        });

        // Store the hex ID
        userHexIDs[msg.sender] = uniqueId;
    }

    // Function for a verifier to verify a user's passport data
    function verifyUniqueHexID(bytes32 _uniqueId) external onlyVerifier payable returns (string memory) {

        require(isVerifierApproved(msg.sender), "Verifier is not approved by the user");

        // Retrieve the user's hex ID
        bytes32 storedUniqueId = userHexIDs[msg.sender];
        require(storedUniqueId != bytes32(0), "User does not have a hex ID");

        // Verify that the provided hex ID matches the stored hex ID
        require(_uniqueId == storedUniqueId, "Incorrect hex ID");

        // Collect charges from the verifier
        require(msg.value >= verificationCharges[msg.sender], "Insufficient verification fee");
        
        // Transfer verification charges to Padi address
        payable(padiAddress).transfer(msg.value);

        // Return the user's passport number
        return userData[msg.sender].passportNumber;
    }

    // Function for a padi to view all user and verifier addresses
    function viewAllAddresses() external view onlyPadi returns (address[] memory, address[] memory) {
        return (verifiers[msg.sender], getAllUserAddresses());
    }

    // Function to get all user addresses
    function getAllUserAddresses() public view returns (address[] memory) {
        address[] memory userAddresses;
        for (uint256 i = 0; i < verifiers[msg.sender].length; i++) {
            userAddresses[i] = userData[keccak256(abi.encodePacked(verifiers[msg.sender][i], ""))].userAddress;
        }
        return userAddresses;
    }

    function isVerifierApproved(address _verifier) internal view returns (bool) {
        address[] memory userVerifiers = verifiers[msg.sender];
        for (uint256 i = 0; i < userVerifiers.length; i++) {
            if (userVerifiers[i] == _verifier) {
                return true;
            }
        }
        return false;
    }

}