// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";


// 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A IPoolAddressesProvider sepolia eth

// 

contract Flashloan is FlashLoanSimpleReceiverBase {
      
    address payable owner;

    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) payable
    {
    owner = payable (msg.sender);

    }

    function requestFlashLoan(address _token, uint _amount, bytes calldata params) public {
    address receiverAddress = address(this);
    address asset = _token;
    uint amount = _amount;
    uint16 referralCode;

    POOL.flashLoanSimple(
        receiverAddress,
        asset,
        amount,
        params,
        referralCode);
    
  }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
  ) external override returns (bool) {
        // we have the borrowed funds
        // custom logic

        (address[] memory routers, bytes[] memory trades, address[] memory tokens, bytes[] memory approves) = abi.decode(params, (address[], bytes[], address[], bytes[]));
        // router adresses length must be eaqual to trades data length
        require(routers.length > 0 && routers.length == trades.length, "Invalid input");
        
        for(uint256 i; i < routers.length; i++) {

            // Approve each token 
            //(bool successApprove,bytes memory returnData ) = tokens[i].call{value: address(this).balance, gas: gasleft()}(approves[i]);
            bool successApprove = IERC20(tokens[i]).approve(address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45), type(uint256).max);
            require(successApprove, "Can not approve");
            //Send trade data to contract adresses
            (bool success, bytes memory returndata) = routers[i].call{value: address(this).balance, gas: gasleft()}(trades[i]);
            require(success, "Can not trade(");
        }

        // Approve borrowed amount + premium for AAVE pool contract
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);
        return true;

  }

  function gas_left() public view returns (uint) {
      return gasleft();
  }

  function viewParams(bytes calldata params) public view returns(address[] memory, bytes[] memory) {
      (address[] memory routers, bytes[] memory data)= abi.decode(params, (address[], bytes[]));
      return (routers, data);
  }

  function getBalance(address _tokenAddress) external view returns (uint) {
    return IERC20(_tokenAddress).balanceOf(address(this));
  }

  modifier onlyOwner() {
        require(msg.sender==owner, "You are not the owner");
        _;
    }

  function withdraw(address _tokenAddress ) onlyOwner external {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));

  }

  receive() external payable { }

    
}