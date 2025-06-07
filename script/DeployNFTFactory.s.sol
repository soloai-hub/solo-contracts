// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import { NFTFactory_License } from "../contracts/NFTFactory_License.sol";

contract DeployNFTFactory is Script {
    function run() external {
        vm.startBroadcast();
        new NFTFactory_License();
        vm.stopBroadcast();
    }
}