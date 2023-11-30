// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

// 0x812C23640dC89FF6Cb8B5AF44a3094a94b26b93A IPoolAddressesProvider sepolia eth

contract Flashloan is FlashLoanSimpleReceiverBase {

    address payable owner;

    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
    owner = payable (msg.sender);

    }


    modifier onlyOwner() {
        require(msg.sender==owner, "You are not the owner");
        _;
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
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;

  }

  function requestFlashLoan(address _token, uint _amount) public {
    address receiverAddress = address(this);
    address asset = _token;
    uint amount = _amount;
    bytes memory params;
    uint16 referralCode;

    POOL.flashLoanSimple(
        receiverAddress,
        asset,
        amount,
        params,
        referralCode);
    
  }

  function getBalance(address _tokenAddress) external view returns (uint) {
    return IERC20(_tokenAddress).balanceOf(address(this));
  }

  function withdraw(address _tokenAddress ) onlyOwner external {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));

  }

  receive() external payable { }

    
}