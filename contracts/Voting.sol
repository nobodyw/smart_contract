// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title decentralized voting system
* @author nobodyw, https://github.com/nobodyw
* @notice The contract allows you to register your proposal and vote for your favorite proposal,
    in case there are several finalists, a second round can be done.
    more details on the voting process in the contract doc ../docs/Voting.md
    .
*/
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

/*
* @dev Call after voter registration
* @param _voter is the Struct of the new voter
*/
    event registerVote(Voter _voter);
/*
* @dev Call after a change of stage in the vote
* @param _oldWorkFlow is the WorkflowStatus step that will change, _newWorkFlow is the step of the new WorkflowStatus
*/
    event changeWorkflowStatus(WorkflowStatus _oldWorkFlow, WorkflowStatus _newWorkFlow);
/*
* @dev Call after a voter registers their proposal
* @param _proposal is the struct of new Proposal
*/
    event registerProposal(Proposal _proposal);
/*
* @dev Call after a voter votes for their preferred proposal
* @param _voter is the struct of the voter, _proposal is the structure for which we just voted
*/
    event setVote(Voter _voter, Proposal _proposal);
/*
* @dev Call after the vote count to know the winner
* @param _secondTurn if true a winner has been found, if false we go back to a new voting session with the finalists
*/
    event eventCountVote(bool _secondTurn);

    modifier onlyVoter(){
        require(Voters[msg.sender].isRegistered,"You are not voter");
        _;
    }

/*
* @return Array of all Proposal
*/
    function getAllProposals() external view returns(Proposal[] memory){
        return Proposals;
    }

/*
* @notice The owner registers the voters
* @param _voter is the address of the voter
*/
    function registerVoter(address _voter) external onlyOwner{
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'cannot add new voters');
        require(!Voters[_voter].isRegistered, "The voter is already registered");
        require(_voter != owner(),"The Owner don't participate");

        Voters[_voter].isRegistered = true;
        Voters[_voter].hasVoted = 0;
        emit registerVote(Voters[_voter]);
    }

/*
 * @notice The owner starts the proposal session
 * @dev The workFlowStatus change RegisteringVoters to ProposalsRegistrationStarted
*/
    function startProposals() external onlyOwner{
        require(workflowStatus == WorkflowStatus.RegisteringVoters,'cannot start session proposals');

        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit changeWorkflowStatus(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

/*
 * @notice The voter adds himself as a proposal
 * @param _description is the description of the new proposition
*/
    function voterAddProposal(string memory _description) external onlyVoter{
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,'cannot add proposal');
        require(keccak256(abi.encode(_description)) != keccak256(abi.encode("")), 'your description is empty');

        for (uint i = 0; i < Proposals.length; i++) {
            require(keccak256(abi.encode(Proposals[i].description)) != keccak256(abi.encode(_description)),
                "this description is already used");
            require(Proposals[i].proposalAddress != msg.sender, "You are already register like proposal");
        }
        Proposals.push(Proposal(msg.sender,_description,0,0));
        emit registerProposal(Proposal(msg.sender,_description,0,0));
    }

/*
 * @notice The owner stop the proposal session
 * @dev The workFlowStatus change ProposalsRegistrationStarted to ProposalsRegistrationEnded
*/
    function endProposals() external onlyOwner{
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,'cannot end session proposals');

        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
    }

/*
 * @notice The owner start the voting session
 * @dev The workFlowStatus change ProposalsRegistrationEnded to VotingSessionStarted
*/
    function startVote() external onlyOwner{
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,'cannot start session vote');

        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

/*
 * @notice The voter votes for their preferred proposal
 * @param _proposalId is the id of the proposal for which we want to vote
*/
    function vote(uint _proposalId) external onlyVoter{
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'cannot vote');

        require(Voters[msg.sender].hasVoted == Proposals[_proposalId].numberFinalist,'You have already voted');
        require(_proposalId <= Proposals.length ,'this proposal does not exist');

        Voters[msg.sender].hasVoted++;
        Voters[msg.sender].votedProposalId = _proposalId;

        Proposals[_proposalId].voteCount++;
        emit setVote(Voters[msg.sender], Proposals[_proposalId]);
    }

/*
 * @notice The owner stop the voting session
 * @dev The workFlowStatus change ProposalsRegistrationStarted to ProposalsRegistrationEnded
*/
    function endVote() external onlyOwner{
        require(workflowStatus == WorkflowStatus.VotingSessionStarted,'cannot stop vote session');

        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }


/*
 * @dev Count the number of Proposals that have the same number of votes.
        If several finalists have been found, we return the workflow to sessionVoteStart
        If only one finalist has been found, the Winner is determined and the workflow ends with VotesTallied
 * @return array which contains the finalistS or the finalist
*/
    function countVote() external onlyOwner returns(Proposal[] memory) {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, 'cannot count vote');
        require(Proposals.length >= 1,'there are no finalists');
        uint indexWinner = 0;
        delete finalist;

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
            delete Proposals;
            for(uint i = 0; i < finalist.length; i++){
                Proposals.push(finalist[i]);
            }
            emit changeWorkflowStatus(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotingSessionStarted);
            emit eventCountVote(true);
            return Proposals;
        }

        workflowStatus = WorkflowStatus.VotesTallied;

        Winner.description = finalist[0].description;
        Winner.numberFinalist = finalist[0].numberFinalist;
        Winner.voteCount = finalist[0].voteCount;
        Winner.proposalAddress = finalist[0].proposalAddress;

        emit changeWorkflowStatus(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotesTallied);
        emit eventCountVote(false);
        return Proposals;
    }
}