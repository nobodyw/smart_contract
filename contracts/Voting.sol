// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable{

    mapping(address => Voter) private Voters;
    Proposal[] public Proposals;
    Proposal[] public finalist;
    Proposal public Winner;

    struct Voter {
        bool isRegistered;
        uint hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        address proposalAddress;
        string description;
        uint voteCount;
        uint numberFinalist;
    }

    WorkflowStatus public workflowStatus;
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event registerVote(Voter voter);
    event changeWorkflowStatus(WorkflowStatus oldWorkFlow, WorkflowStatus newWorkFlow);
    event registerProposal(Proposal proposal);
    event setVote(Voter voter, Proposal proposal);

    modifier onlyVoter(){
        require(Voters[msg.sender].isRegistered,"You are not voter");
        _;
    }

    function registerVoter(address _voter) external onlyOwner{
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'cannot add new voters');
        require(!Voters[_voter].isRegistered, "The voter is already registered");
        require(_voter != owner(),"The Owner don't participate");

        Voters[_voter].isRegistered = true;
        Voters[_voter].hasVoted = 0;
        emit registerVote(Voters[_voter]);
    }

    function startProposals() external onlyOwner{
        require(workflowStatus == WorkflowStatus.RegisteringVoters,'cannot start session proposals');

        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit changeWorkflowStatus(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function voterAddProposal(string memory _description) external onlyVoter{
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,'cannot add proposal');
        require(keccak256(abi.encode(_description)) != keccak256(abi.encode("")), 'your description is empty');

        for (uint i = 0; i < Proposals.length; i++) {
            require(keccak256(abi.encode(Proposals[i].description)) != keccak256(abi.encode(_description)), "this description is already used");
            require(Proposals[i].proposalAddress != msg.sender, "You are already register like proposal");
        }
        Proposals.push(Proposal(msg.sender,_description,0,0));
        emit registerProposal(Proposal(msg.sender,_description,0,0));
    }

    function endProposals() external onlyOwner{
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,'cannot end session proposals');

        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVote() external onlyOwner{
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,'cannot start session vote');

        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function vote(uint _proposalId) external onlyVoter{
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'cannot vote');

        require(Voters[msg.sender].hasVoted == Proposals[_proposalId].numberFinalist,'You have already voted');
        require(_proposalId <= Proposals.length ,'this proposal does not exist');

        Voters[msg.sender].hasVoted++;
        Voters[msg.sender].votedProposalId = _proposalId;

        Proposals[_proposalId].voteCount++;
        emit setVote(Voters[msg.sender], Proposals[_proposalId]);
    }

    function endVote() external onlyOwner{
        require(workflowStatus == WorkflowStatus.VotingSessionStarted,'cannot stop vote session');

        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function countVote() external onlyOwner returns(Proposal[] memory) {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, 'cannot count vote');

        uint indexWinner = 0;

        for(uint i = 0; i < Proposals.length; i++){
            if(Proposals[i].voteCount > indexWinner){
                indexWinner = Proposals[i].voteCount;
            }
        }
        for(uint i = 0; i < Proposals.length; i++){
            if(Proposals[i].voteCount == indexWinner){
                Proposals[i].numberFinalist++;
                finalist.push(Proposals[i]);
            }
        }
        if(finalist.length > 1){
            workflowStatus = WorkflowStatus.VotingSessionStarted;
            Proposals = finalist;
            emit changeWorkflowStatus(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotingSessionStarted);
            return Proposals;
        }
        workflowStatus = WorkflowStatus.VotesTallied;
        Winner = Proposals[0];
        emit changeWorkflowStatus(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotesTallied);
        return Proposals;
    }
}