// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

interface IPFS {
    function upload(string memory _data) external returns (bytes32);
}

contract PassportRegistry is Ownable {
    using ECDSA for bytes32;

    // Enum to represent user tags
    enum UserTag { USER, PADI, VERIFIER }

    // Structure to represent user data
    struct UserData {
        string passportNumber;
        address userAddress;
    }


    // Mapping from unique ID to user data
    mapping(bytes32 => UserData) public userData;

    // Mapping from user address to verifier addresses
    mapping(address => address[]) public verifiers;

    // Mapping from verifier address to charges
    mapping(address => uint256) public verificationCharges;

    // Mapping from address to tag (0 for user, 1 for padi, 2 for verifier)
    mapping(address => UserTag) public addressTags;


    // IPFS contract address
    address public ipfsContractAddress;
    

    // Event emitted when a user adds a verifier
    event VerifierAdded(address indexed user, address indexed verifier);

    // Event emitted when a verifier charges are updated
    event VerificationChargesUpdated(address indexed verifier, uint256 charges);
}