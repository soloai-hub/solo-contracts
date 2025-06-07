// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Script, console } from "forge-std/Script.sol";
import { NFTFactory_Derivative } from "../contracts/NFTFactory_Derivative.sol";

contract DeployNFTFactory_Derivative is Script {
    // --- Configuration ---

    // These are EXAMPLE values. Replace them with your actual deployment parameters.
    // You can also make these configurable via command-line arguments or environment variables.

    // Parent IP Information (MUST be provided)
    address parentIpId = 0x5E2A3D7FD22055d60D865591E469b3e744d55BfE;
    uint256 parentLicenseTermsId = 21528;

    string derivativeCollectionName = "SONA Derivative Collection";
    string derivativeCollectionSymbol = "SONA_DERIVATIVE";




    function run() external returns (NFTFactory_Derivative deployedFactory) {
        require(parentIpId != address(0), "DeployNFTFactory_Derivative: PARENT_IP_ID must be set in .env or provided.");
        require(parentLicenseTermsId != 0, "DeployNFTFactory_Derivative: PARENT_LICENSE_TERMS_ID must be set in .env or provided and non-zero.");
        bytes memory nameBytes = bytes(derivativeCollectionName);
        require(nameBytes.length > 0, "DeployNFTFactory_Derivative: DERIVATIVE_COLLECTION_NAME must be set in .env or provided.");


        console.log("Deploying NFTFactory_Derivative with parameters:");
        console.log("  Parent IP ID:                     ", parentIpId);
        console.log("  Parent License Terms ID:          ", parentLicenseTermsId);
        console.log("  Derivative Collection Name:       ", derivativeCollectionName);
        console.log("  Derivative Collection Symbol:     ", derivativeCollectionSymbol);

        vm.startBroadcast();
        deployedFactory = new NFTFactory_Derivative(
            parentIpId,
            parentLicenseTermsId,
            derivativeCollectionName,
            derivativeCollectionSymbol
        );
        vm.stopBroadcast();

        console.log("NFTFactory_Derivative deployed at: ", address(deployedFactory));
        return deployedFactory;
    }
} 