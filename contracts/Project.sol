// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Project {
    address payable public owner;
    uint256 public goal;
    uint256 public endTime;
    mapping(address => uint256) public backers;
    address[] public backersList;

    constructor(address payable _owner, uint256 _goal, uint256 _durationInDays) {
        owner = _owner;
        goal = _goal;
        endTime = block.timestamp + (_durationInDays * 1 days);
    }


    function backProject() external payable {
    require(block.timestamp <= endTime, "The funding period has ended");
    require(msg.value > 0, "The amount sent must be greater than 0");
    require(address(this).balance + msg.value <= goal, "The funding goal has been reached");
    backers[msg.sender] += msg.value;
    if (backers[msg.sender] == msg.value) {
        backersList.push(msg.sender);
    }
    payable(address(this)).transfer(msg.value);
    }


    function withdrawFunds() external {
        require(address(this).balance >= goal, "The funding goal has not been reached");
        require(msg.sender == owner, "Only the owner can withdraw funds");
        owner.transfer(address(this).balance);
    }
}
