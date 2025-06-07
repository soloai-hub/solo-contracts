// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../contracts/PaymentContract.sol";

contract DeployIPPayment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        PaymentContract.Product[] memory products = new PaymentContract.Product[](5);
        products[0] = PaymentContract.Product({
            id: 1,
            name: "300 Credits",
            price: 1.2 ether,
            active: true,
            token: address(0)
        });
        products[1] = PaymentContract.Product({
            id: 2,
            name: "600 Credits",
            price: 2.5 ether,
            active: true,
            token: address(0)
        });
        products[2] = PaymentContract.Product({
            id: 3,
            name: "1200 Credits",
            price: 5 ether,
            active: true,
            token: address(0)
        });
        products[3] = PaymentContract.Product({
            id: 4,
            name: "2400 Credits",
            price: 10 ether,
            active: true,
            token: address(0)
        });
        products[4] = PaymentContract.Product({
            id: 5,
            name: "Starter Pack",
            price: 0.25 ether,
            active: true,
            token: address(0)
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