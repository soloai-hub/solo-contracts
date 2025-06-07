// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentContract {
    address public owner;
    address public recipient;
    
    struct Product {
        uint256 id;
        string name;
        uint256 price;
        bool active;
        address token;
    }
    
    mapping(uint256 => Product) public products;
    
    event ProductPurchased(
        address indexed buyer,
        uint256 indexed productId,
        string indexed productName,
        uint256 price,
        address token,
        uint256 timestamp
    );
    
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(address _recipient, Product[] memory _products) {
        owner = msg.sender;
        recipient = _recipient;

        for (uint256 i = 0; i < _products.length; i++) {
            products[_products[i].id] = _products[i];
        }
    }
    
    function purchase(uint256 _productId) external payable {
        Product memory product = products[_productId];
        require(product.active, "Product not active");

        if (product.token == address(0)) {
            require(msg.value >= product.price, "Insufficient token sent");
            payable(recipient).transfer(msg.value);
        } else {
            require(IERC20(product.token).transferFrom(msg.sender, recipient, product.price), "Transfer failed");
        }

        emit ProductPurchased(
            msg.sender,
            _productId,
            product.name,
            product.price,
            product.token,
            block.timestamp
        );
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }
    
    function getProduct(uint256 _productId) external view returns (Product memory) {
        return products[_productId];
    }

    function setProducts(Product[] memory _products) external onlyOwner {
        for (uint256 i = 0; i < _products.length; i++) {
            products[_products[i].id] = _products[i];
        }
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }
    
    receive() external payable {}
}


