## `Voting`

1. L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.

2. L'administrateur du vote commence la session d'enregistrement de la proposition.
3. Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.

4.L'administrateur de vote met fin à la session d'enregistrement des propositions.

5.L'administrateur du vote commence la session de vote.


6.Les électeurs inscrits votent pour leurs propositions préférées.

7.L'administrateur du vote met fin à la session de vote.

8.L'administrateur du vote comptabilise les votes.

Tout le monde peut vérifier les derniers détails de la proposition gagnante.



### `onlyVoter()`






### `getAllProposals() → struct Voting.Proposal[]` (external)





### `registerVoter(address _voter)` (external)





### `startProposals()` (external)





### `voterAddProposal(string _description)` (external)





### `endProposals()` (external)





### `startVote()` (external)





### `vote(uint256 _proposalId)` (external)





### `endVote()` (external)





### `countVote() → struct Voting.Proposal[]` (external)






### `registerVote(struct Voting.Voter _voter)`





### `changeWorkflowStatus(enum Voting.WorkflowStatus _oldWorkFlow, enum Voting.WorkflowStatus _newWorkFlow)`





### `registerProposal(struct Voting.Proposal _proposal)`





### `setVote(struct Voting.Voter _voter, struct Voting.Proposal _proposal)`





### `eventCountVote(bool _secondTurn)`






### `Voter`


bool isRegistered


uint256 hasVoted


uint256 votedProposalId


### `Proposal`


address proposalAddress


string description


uint256 voteCount


uint256 numberFinalist



### `WorkflowStatus`




















