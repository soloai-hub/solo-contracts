// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IIPAssetRegistry } from "@storyprotocol/core/interfaces/registries/IIPAssetRegistry.sol";
import { ISPGNFT } from "@storyprotocol/periphery/interfaces/ISPGNFT.sol";
import { IRegistrationWorkflows } from "@storyprotocol/periphery/interfaces/workflows/IRegistrationWorkflows.sol";
import { WorkflowStructs } from "@storyprotocol/periphery/lib/WorkflowStructs.sol";

import { ILicenseRegistry } from "@storyprotocol/core/interfaces/registries/ILicenseRegistry.sol";
import { IPILicenseTemplate } from "@storyprotocol/core/interfaces/modules/licensing/IPILicenseTemplate.sol";
import { ILicensingModule } from "@storyprotocol/core/interfaces/modules/licensing/ILicensingModule.sol";
import { PILFlavors } from "@storyprotocol/core/lib/PILFlavors.sol";
// import { PILTerms } from "@storyprotocol/core/interfaces/modules/licensing/IPILicenseTemplate.sol"; // PILTerms might not be directly used if using PILFlavors

import { ILicenseToken } from "@storyprotocol/core/interfaces/ILicenseToken.sol";
// import { RoyaltyPolicyLAP } from "@storyprotocol/core/modules/royalty/policies/LAP/RoyaltyPolicyLAP.sol"; // Included via PILFlavors if needed

import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NFTFactory_Derivative is ERC721Holder {

    IIPAssetRegistry public constant IP_ASSET_REGISTRY = IIPAssetRegistry(0x77319B4031e6eF1250907aa00018B8B1c67a244b);
    IRegistrationWorkflows public constant REGISTRATION_WORKFLOWS = IRegistrationWorkflows(0xbe39E1C756e921BD25DF86e7AAa31106d1eb0424);
    ILicensingModule internal constant LICENSING_MODULE = ILicensingModule(0x04fbd8a2e56dd85CFD5500A4A4DfA955B9f1dE6f);
    IPILicenseTemplate internal constant PIL_TEMPLATE = IPILicenseTemplate(0x2E896b0b2Fdb7457499B56AAaA4AE55BCB4Cd316);
    address internal constant ROYALTY_POLICY_LAP = 0xBe54FB168b3c982b7AaE60dB6CF75Bd8447b390E;
    address public immutable WIP = 0x1514000000000000000000000000000000000000;


    address public immutable parentIpIdToDeriveFrom;
    uint256 public immutable parentLicenseTermsId; 
    address public immutable currencyTokenForDerivativeFees; 

    ISPGNFT public derivativeSpgNft;

    event DerivativeIpAssetMinted(
        address indexed recipient,
        address indexed derivativeIpId,
        uint256 indexed tokenId,
        address parentIpId
    );
    event LicenseTermsAttachedToDerivative(
        address indexed derivativeIpId,
        address indexed licenseTemplate,
        uint256 licenseTermsId
    );
     event ParentLicenseTokenMintedForDerivative(
        address indexed minter, 
        address indexed parentIpId,
        uint256 parentLicenseTokenId,
        address derivativeIpId
    );
    event DerivativeLicenseTokenMinted(
        address indexed recipient,
        address indexed derivativeIpId,
        uint256 indexed derivativeLicenseTokenId
    );


    constructor(
        address _parentIpId,
        uint256 _parentLicenseTermsId,
        string memory _derivativeCollectionName,
        string memory _derivativeCollectionSymbol
    ) {
        require(_parentIpId != address(0), "Parent IP ID cannot be zero address");
        require(_parentLicenseTermsId != 0, "Parent license terms ID cannot be zero");

        parentIpIdToDeriveFrom = _parentIpId;
        parentLicenseTermsId = _parentLicenseTermsId;

        derivativeSpgNft = ISPGNFT(
            REGISTRATION_WORKFLOWS.createCollection(
                ISPGNFT.InitParams({
                    name: _derivativeCollectionName,
                    symbol: _derivativeCollectionSymbol,
                    baseURI: "", // Consider making configurable or non-empty
                    contractURI: "", // Consider making configurable or non-empty
                    maxSupply: 10000, // Or make configurable
                    mintFee: 0, // Or make configurable
                    mintFeeToken: WIP, 
                    mintFeeRecipient: address(this),
                    owner: address(this), 
                    mintOpen: true,
                    isPublicMinting: false
                })
            )
        );
    }

    function mintDerivativeAndRegisterIp(
        address _recipient,
        WorkflowStructs.IPMetadata calldata _ipMetadata
    ) external returns (address derivativeIpId, uint256 derivativeTokenId) {
        require(_recipient != address(0), "Recipient cannot be zero address");

        // 1. Mint the new derivative IP Asset (NFT minted to this contract first)
        uint256 expectedTokenId = derivativeSpgNft.totalSupply() + 1;
        derivativeIpId = IP_ASSET_REGISTRY.ipId(block.chainid, address(derivativeSpgNft), expectedTokenId);

        (address returnedIpId, uint256 returnedTokenId) = REGISTRATION_WORKFLOWS.mintAndRegisterIp(
            address(derivativeSpgNft), 
            address(this),            
            _ipMetadata,
            true                       
        );

        require(returnedIpId == derivativeIpId, "Derivative IP ID mismatch");
        require(returnedTokenId == expectedTokenId, "Derivative Token ID mismatch");
        derivativeTokenId = returnedTokenId;

        // 2. Mint a license token from the parent IP.
        // This contract (receiver) will hold the license token to authorize derivatization.
        uint256 parentLicenseTokenId = LICENSING_MODULE.mintLicenseTokens(
            parentIpIdToDeriveFrom,
            address(PIL_TEMPLATE),    // Assuming parent's license terms are registered with this template
            parentLicenseTermsId,
            1,                        // Amount of license tokens
            address(this),            // Receiver is this contract
            "",                       // royaltyContext (empty for PIL)
            0,                        // maxMintingFee 
            0                         // maxRevenueShare
        );
        emit ParentLicenseTokenMintedForDerivative(address(this), parentIpIdToDeriveFrom, parentLicenseTokenId, derivativeIpId);

        // 3. Register the newly minted IP as a derivative of the parent, using the license token.
        uint256[] memory licenseTokenIds = new uint256[](1);
        licenseTokenIds[0] = parentLicenseTokenId;

        LICENSING_MODULE.registerDerivativeWithLicenseTokens(
            derivativeIpId,       // childIpId
            licenseTokenIds,      // licenseTokenIds from parent
            "",                   // royaltyContext (empty for PIL)
            0                     // maxRts (Refer to Story Docs for appropriate value, 0 for no limit/default)
        );
        uint256 derivativeLicenseTokenId = LICENSING_MODULE.mintLicenseTokens(
            derivativeIpId,
            address(PIL_TEMPLATE),
            parentLicenseTermsId,
            1,
            _recipient,
            "",
            0,
            0
        );
        emit DerivativeLicenseTokenMinted(_recipient, derivativeIpId, derivativeLicenseTokenId);
        derivativeSpgNft.transferFrom(address(this), _recipient, derivativeTokenId);
        require(derivativeSpgNft.ownerOf(derivativeTokenId) == _recipient, "Recipient is not the derivative NFT owner");

        emit DerivativeIpAssetMinted(_recipient, derivativeIpId, derivativeTokenId, parentIpIdToDeriveFrom);

        return (derivativeIpId, derivativeTokenId);
    }
} 