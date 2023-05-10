// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ProjectRegistry {
struct Project {
string name;
string description;
address owner;
uint256 targetAmount;
uint256 deadline;
uint256 actualAmount;
address[] backers;
uint[] backersValues;
uint256 id;
bool checked;
bool moneyTaken;
uint256 startTime;
}

function getMyMoney (uint256 id) public
{
  require(msg.sender != address(0), "Invalid address.");
  uint idx=0;
   for (uint i = 0; i < projects.length; i++) {
        if(projects[i].id==id)
        {
            idx=i;
            break;
        }
   }
  require(msg.sender == projects[idx].owner, "The owner cannot call this function.");
  require(projects[idx].deadline > 0 && projects[idx].deadline <= block.timestamp, "The deadline hasn't expired yet.");
  require(projects[idx].moneyTaken==false);
  require(projects[idx].checked==false);
  if (projects[idx].actualAmount >= projects[idx].targetAmount && !projects[idx].checked) {
    // Send the funds to the owner.
    address payable owner = payable(projects[idx].owner);
    owner.transfer(projects[idx].actualAmount);
    projects[idx].checked = true;
    projects[idx].moneyTaken =true;
}
}
Project[] public projects;

function getProjectCount() public view returns (uint256) {
    return projects.length;
}

function createProject(string memory name, string memory description, uint256 targetAmount, uint256 deadline,uint256 start) public {
    Project memory newProject = Project(name, description, msg.sender, targetAmount, deadline, 0, new address[](0),new uint[](0),projects.length,false,false,start);
    projects.push(newProject);
    if (hasAnyProjectExpired()) {
        uint256[] memory ids = getExpiredProjectsIds();
        returnBackersValues(ids);
    }

}

function getProject(uint256 index) public view returns (string memory, string memory, address, uint256, uint256, uint256, address[] memory,uint256,bool,uint256) {
    require(index < projects.length, "Invalid project index");
    Project memory project = projects[index];
    return (project.name, project.description, project.owner, project.targetAmount, project.deadline, project.actualAmount, project.backers,project.id,project.moneyTaken,project.startTime);
}

function invest(uint256 index) public payable {
    require(index < projects.length, "Invalid project idx");
    Project storage project = projects[index];
    require(!hasProjectExpired(project), "Project deadline pass");
    project.actualAmount += msg.value;
    project.backers.push(msg.sender);
    project.backersValues.push(msg.value);
    if (hasAnyProjectExpired()) {
        uint256[] memory ids = getExpiredProjectsIds();
        returnBackersValues(ids);
    }
}


function hasProjectExpired(Project memory project) internal view returns (bool) {
    return block.timestamp >= project.deadline;
}

function hasAnyProjectExpired() public view returns (bool) {
    for (uint i = 0; i < projects.length; i++) {
        if (hasProjectExpired(projects[i])&& !projects[i].checked) {

            return true;
        }
    }
    return false;
}
function getExpiredProjectsIds() public view returns (uint256[] memory) {
    uint256[] memory expiredProjects = new uint256[](projects.length);
    uint256 expiredCount = 0;
    for (uint256 i = 0; i < projects.length; i++) {
        if (hasProjectExpired(projects[i])) {

            expiredProjects[expiredCount] = projects[i].id;
            expiredCount++;
        }
    }
    uint256[] memory result = new uint256[](expiredCount);
    for (uint256 i = 0; i < expiredCount; i++) {
        result[i] = expiredProjects[i];
    }
    
    return result;
}
function returnBackersValues(uint256[] memory projectIds) public {
    for (uint256 i = 0; i < projectIds.length; i++) {
        Project storage project = projects[projectIds[i]];
        if (project.actualAmount < project.targetAmount) {
            for (uint256 j = 0; j < project.backers.length; j++) {
                payable(project.backers[j]).transfer(project.backersValues[j] );
                projects[projectIds[i]].checked=true;
            }
        }
    }
}




}