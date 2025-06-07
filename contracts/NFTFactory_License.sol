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
import { PILTerms } from "@storyprotocol/core/interfaces/modules/licensing/IPILicenseTemplate.sol";

import { ILicenseToken } from "@storyprotocol/core/interfaces/ILicenseToken.sol";
import { RoyaltyPolicyLAP } from "@storyprotocol/core/modules/royalty/policies/LAP/RoyaltyPolicyLAP.sol";

import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";



contract NFTFactory_License is ERC721Holder {

    IIPAssetRegistry public constant IP_ASSET_REGISTRY = IIPAssetRegistry(0x77319B4031e6eF1250907aa00018B8B1c67a244b);
    IRegistrationWorkflows public constant REGISTRATION_WORKFLOWS = IRegistrationWorkflows(0xbe39E1C756e921BD25DF86e7AAa31106d1eb0424);
    ISPGNFT public spgNft;

    ILicenseRegistry internal constant LICENSE_REGISTRY = ILicenseRegistry(0x529a750E02d8E2f15649c13D69a465286a780e24);
    ILicensingModule internal constant LICENSING_MODULE = ILicensingModule(0x04fbd8a2e56dd85CFD5500A4A4DfA955B9f1dE6f);
    IPILicenseTemplate internal constant PIL_TEMPLATE = IPILicenseTemplate(0x2E896b0b2Fdb7457499B56AAaA4AE55BCB4Cd316);
    address public immutable WIP = 0x1514000000000000000000000000000000000000;

    address internal constant ROYALTY_POLICY_LAP = 0xBe54FB168b3c982b7AaE60dB6CF75Bd8447b390E;

    ILicenseToken internal LICENSE_TOKEN = ILicenseToken(0xFe3838BFb30B34170F00030B52eA4893d8aAC6bC);

    event IpAssetMinted(address indexed recipient, address indexed ipId, uint256 indexed tokenId);

    event LicenseTermsAttached(address indexed ipId, address indexed licenseTemplate, uint256 licenseTermsId);

    event LicenseTokenMinted(address indexed to, address ipId, uint256 startTokenId, uint256 amount);

    constructor() {
        spgNft = ISPGNFT(
            REGISTRATION_WORKFLOWS.createCollection(
                ISPGNFT.InitParams({
                    name: "SOLO AVATAR Collection",
                    symbol: "SOLO_AVATAR",
                    baseURI: "",
                    contractURI: "",
                    maxSupply: 10000,
                    mintFee: 0,
                    mintFeeToken: WIP,
                    mintFeeRecipient: address(this),
                    owner: address(this),
                    mintOpen: true,
                    isPublicMinting: false
                })
            )
        );
    }

    function mintAndRegisterFor(address recipient) external returns (address ipId, uint256 tokenId) {
        uint256 expectedTokenId = spgNft.totalSupply() + 1;

        ipId = IP_ASSET_REGISTRY.ipId(block.chainid, address(spgNft), expectedTokenId);

        (address returnedIpId, uint256 returnedTokenId) = REGISTRATION_WORKFLOWS.mintAndRegisterIp(
            address(spgNft),
            address(this),
            WorkflowStructs.IPMetadata({
                ipMetadataURI: "https://ipfs.io/ipfs/QmZHfQdFA2cb3ASdmeGS5K6rZjz65osUddYMURDx21bT73",
                ipMetadataHash: keccak256(
                    abi.encodePacked(
                        "{'title':'SONA','description':'SONA','createdAt':'','creators':[]}"
                    )
                ),
                nftMetadataURI: "https://ipfs.io/ipfs/QmRL5PcK66J1mbtTZSw1nwVqrGxt98onStx6LgeHTDbEey",
                nftMetadataHash: keccak256(
                    abi.encodePacked(
                        "{'name':'SONA','description':'SONA','image':'https://picsum.photos/200'}"
                    )
                )
            }),
            true
        );

        uint256 licenseTermsId = PIL_TEMPLATE.registerLicenseTerms(
            PILFlavors.commercialRemix({
                mintingFee: 0,
                commercialRevShare: 20 * 10 ** 6,
                royaltyPolicy: ROYALTY_POLICY_LAP,
                currencyToken: WIP
            })
        );

        LICENSING_MODULE.attachLicenseTerms(ipId, address(PIL_TEMPLATE), licenseTermsId);
        emit LicenseTermsAttached(ipId, address(PIL_TEMPLATE), licenseTermsId);

        require(returnedIpId == ipId, "IP ID mismatch");
        require(returnedTokenId == expectedTokenId, "Token ID mismatch");
        tokenId = returnedTokenId;

        spgNft.transferFrom(address(this), recipient, tokenId);
        require(spgNft.ownerOf(returnedTokenId) == recipient, "Recipient is not the NFT owner");
        emit IpAssetMinted(recipient, ipId, tokenId);
    }

    function attachLicenseTerms(address ipId) external {

        // Create License Terms
        // uint256 licenseTermsId = PIL_TEMPLATE.registerLicenseTerms(
        //     PILFlavors.nonCommercialSocialRemixing()
        // );
        
        // nonCommercialSocialRemixing() has been registered, licenseTermsId = 1
        // https://docs.story.foundation/concepts/programmable-ip-license/pil-flavors#pil-flavors-examples

        // Attech License Terms to IP
        uint256 licenseTermsId = 1;
        LICENSING_MODULE.attachLicenseTerms(ipId, address(PIL_TEMPLATE), licenseTermsId);

        emit LicenseTermsAttached(ipId, address(PIL_TEMPLATE), licenseTermsId);
        
    }

    /// Mint license tokens for an IP Asset.
    /// Anyone can mint a license token.
    function mintLicenseToken(address ipId, uint256 licenseTermsId, uint256 amount) external returns (uint256 startTokenId) {
        require(amount > 0, "Amount must be > 0");

        startTokenId = LICENSING_MODULE.mintLicenseTokens({
            licensorIpId: ipId,
            licenseTemplate: address(PIL_TEMPLATE),
            licenseTermsId: licenseTermsId,
            amount: amount,
            receiver: msg.sender,
            royaltyContext: "", // for PIL, royaltyContext is empty
            maxMintingFee: 0,
            maxRevenueShare: 0
        });

        emit LicenseTokenMinted(msg.sender, ipId, startTokenId, amount);
    }
}