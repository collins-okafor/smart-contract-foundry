// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PadiRegistry.sol";

contract PadiRegistryTest is Test {
    PadiRegistry padiRegistry;
    address user;
    address verifier;
    address padi;

    function setUp() public {
        // Deploy PadiRegistry contract
        padiRegistry = new PadiRegistry(address(this), address(this));

        // Set up user, verifier, and padi addresses
        user = address(0x1);
        verifier = address(0x2);
        padi = address(0x3);

        // Add user, verifier, and padi
        padiRegistry.addVerifier(verifier);
        padiRegistry.addVerifier(padi);
    }

    function test_UserCanGenerateHexID() public {
        padiRegistry.generateUniqueHexID("123456789");
        bytes32 hexId = padiRegistry.userHexIDs(user);
        assertNotEqual(hexId, bytes32(0), "Hex ID should be generated for the user");
    }

    function test_VerifierCanVerifyHexID() public {
        padiRegistry.generateUniqueHexID("987654321");
        bytes32 hexId = padiRegistry.userHexIDs(user);

        string memory passportNumber = padiRegistry.verifyUniqueHexID(hexId);
        assertEq(passportNumber, "987654321", "Passport number should match the generated hex ID");
    }

    function test_PadiCanViewAllAddresses() public {
        (address[] memory verifierAddresses, address[] memory userAddresses) = padiRegistry.viewAllAddresses();
        assertEq(verifierAddresses.length, 2, "There should be two verifiers");
        assertEq(userAddresses.length, 1, "There should be one user");
    }

    function test_Fail_VerifierCannotGenerateHexID() public {
        // This test should fail because only users can generate hex IDs
        padiRegistry.generateUniqueHexID("111111111");
    }
}
