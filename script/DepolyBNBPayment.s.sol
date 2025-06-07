// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../contracts/PaymentContract.sol";

contract DeployIPPayment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        PaymentContract.Product[] memory products = new PaymentContract.Product[](10);
        products[0] = PaymentContract.Product({
            id: 1,
            name: "300 Credits",
            price: 0.0075 ether,
            active: true,
            token: address(0)
        });
        products[1] = PaymentContract.Product({
            id: 2,
            name: "600 Credits",
            price: 0.015 ether,
            active: true,
            token: address(0)
        });
        products[2] = PaymentContract.Product({
            id: 3,
            name: "1200 Credits",
            price: 0.03 ether,
            active: true,
            token: address(0)
        });
        products[3] = PaymentContract.Product({
            id: 4,
            name: "2400 Credits",
            price: 0.06 ether,
            active: true,
            token: address(0)
        });
        products[4] = PaymentContract.Product({
            id: 5,
            name: "Starter Pack",
            price: 0.0015 ether,
            active: true,
            token: address(0)
        });
        products[5] = PaymentContract.Product({
            id: 6,
            name: "300 Credits",
            price: 4.9 ether,
            active: true,
            token: address(0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d)
        });
        products[6] = PaymentContract.Product({
            id: 7,
            name: "600 Credits",
            price: 9.9 ether,
            active: true,
            token: address(0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d)
        });
        products[7] = PaymentContract.Product({
            id: 8,
            name: "1200 Credits",
            price: 19.9 ether,
            active: true,
            token: address(0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d)
        });
        products[8] = PaymentContract.Product({
            id: 9,
            name: "2400 Credits",
            price: 39.9 ether,
            active: true,
            token: address(0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d)
        });
        products[9] = PaymentContract.Product({
            id: 10,
            name: "Starter Pack",
            price: 0.99 ether,
            active: true,
            token: address(0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d)
        });
        
        PaymentContract paymentContract = new PaymentContract(
            address(this),
            products
        );
        
        console.log("PaymentContract deployed at:", address(paymentContract));
        console.log("Owner:", paymentContract.owner());
        
        vm.stopBroadcast();
    }
} 