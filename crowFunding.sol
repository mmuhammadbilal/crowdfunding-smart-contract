// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors;
    address public manager;

    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        uint target;
        uint deadline;
        uint minContribution;
        uint raisedAmount;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;

   constructor(){
        manager=msg.sender;
    }
    
    function sendEth(uint i) public payable{
        require(block.timestamp < requests[i].deadline,"Deadline has passed");
        require(msg.value >=requests[i].minContribution,"Minimum Contribution is not met");
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        requests[i].raisedAmount+=msg.value;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function refund(uint i) public{
        require(block.timestamp>requests[i].deadline && requests[i].raisedAmount<requests[i].target,"You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
        
    }
    modifier onlyManger(){
        require(msg.sender==manager,"Only manager can calll this function");
        _;
    }
    function createRequests(string memory _description,address payable _recipient,uint _value,uint _target,uint _deadline,uint _minimumContribution) public onlyManger{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.target=_target;
        newRequest.deadline=block.timestamp+_deadline;
        newRequest.minContribution=_minimumContribution;
        newRequest.noOfVoters=0;
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"YOu must be contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyManger{
        require(requests[ _requestNo].raisedAmount>=requests[_requestNo].target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}
