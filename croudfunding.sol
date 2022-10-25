//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{

    //Declaring main entities as variables

    mapping(address=>uint) public contributors; //address=>value contributed
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors; 

    
    //structure for manager's request to voters

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;  //maping multiple requests for different causes using indexes (0,1,2,...)
    uint public numRequests;

   
    //constructor for setting target and deadline
    constructor(uint _target, uint _deadline){

        target=_target;
        deadline=block.timestamp+_deadline; //deadline value in unix time system
        minimumContribution= 100 wei; 
        manager=msg.sender;

    }


    //function to send funding

    function sendEth() public payable{

        require(block.timestamp < deadline ,"Deadline has passed");
        require(msg.value >= minimumContribution, "minimum contribution is not met");

        //if block to check that the contributor is new and incrementing the no. of contributors
        //if old contributor is sending more ethers, we don't need to increment noOfContributors
        if(contributors[msg.sender]==0){
                  noOfContributors++; 
        }  

        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;

    }

    //funtion to check balance

    function getContractBalance() public view returns(uint){
        return address(this).balance; //returns balance of contract
    }

    //function for refund if target is not met before deadline

    function refund() public{

        require(block.timestamp>deadline && raisedAmount<target,"yor are not eligible for refund");
        require(contributors[msg.sender]>0);

        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;

    }


    // modifier for restricting access to manager only

    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }

    //function for creating requests for crowdfunding

    function createRequests(string memory _description, address payable _receipient ,uint _value) public onlyManager{
        Request storage newRequest=requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_receipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    // function for voting request(voting to send money to recepient (>=50%))

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"you have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    
    //function for making payment to winning request
    function makePayment(uint _requestNo) public onlyManager{

        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2,"Majority doesnot support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;

    }      

}