// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract VestingContract {
    address public owner;
    uint256 public totalVestingAmount;
    uint256 public vestingPeriod;
    uint256 public cliffPeriod;
    uint256 public startTime;
    mapping(address => uint256) public vestingBalances;

    constructor(uint256 _totalVestingAmount, uint256 _vestingPeriod, uint256 _cliffPeriod) public {
        owner = msg.sender;
        totalVestingAmount = _totalVestingAmount;
        vestingPeriod = _vestingPeriod;
        cliffPeriod = _cliffPeriod;
        startTime = now;
        vestingBalances[owner] = totalVestingAmount;
    }

    function releaseVestedAmount(address _beneficiary) public {
        require(_beneficiary != address(0), "Beneficiary address cannot be 0x0");
        require(_beneficiary != owner, "Owner cannot release vesting balance");

        uint256 vestedAmount = calculateVestedAmount(_beneficiary);
        require(vestingBalances[_beneficiary] >= vestedAmount, "Vesting balance is less than the vested amount");

        vestingBalances[_beneficiary] -= vestedAmount;
        _beneficiary.transfer(vestedAmount);
    }

    function calculateVestedAmount(address _beneficiary) private view returns (uint256) {
        uint256 elapsedTime = now - startTime;
        if (elapsedTime < cliffPeriod) {
            return 0;
        }
        uint256 vestedAmount = (elapsedTime - cliffPeriod) * totalVestingAmount / vestingPeriod;
        return vestedAmount;
    }
}
