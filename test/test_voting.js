const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const Assert = require("assert");
const Web3 = require('web3');
const VotingContract = artifacts.require("./Voting.sol");

contract("Voting", function(accounts){
    const owner = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];
    const user3 = accounts[3];
    context("Test function registerVoter", function(){
       beforeEach(async function(){
             Voting = await VotingContract.new({from:owner});
       });
       it("Fail if Voter is already registered", async function(){
          await Voting.registerVoter(user1,{from:owner});
          await expectRevert(Voting.registerVoter(user1,{from:owner}),"The voter is already registered");
       });
       it("Fail if Owner is regitered as a voter",async function(){
          await expectRevert(Voting.registerVoter(owner,{from:owner}),"The Owner don't participate");
       });
       it("Fail if the voter is not registered correctly",async function(){
           await Voting.registerVoter(user1,{from:owner});
           await Voting.Voters.call(user1,function (error,result){
               Assert.equal(result.isRegistered,true,'Voter isRegistered should be true');
               Assert.equal(result.hasVoted,0,'Voter hasVoted should be 0');
           });
       })
        it("Fail if Event does not have the correct data", async function(){
            const newVoter = await Voting.registerVoter(user1,{from:owner});
            await Voting.Voters.call(user1,function(error,result){
                checkVoter = result;
            });
            await expectEvent(newVoter,
                'registerVote',
               {
                   _voter: [
                       checkVoter.isRegistered,
                       checkVoter.hasVoted.toNumber().toString(),
                       checkVoter.votedProposalId.toNumber().toString()]
                });
        });
    });

    context("Test function voterAddProposal", function(){
        beforeEach(async function(){
            Voting = await VotingContract.new({from:owner});
            await Voting.registerVoter(user1,{from:owner});
            await Voting.registerVoter(user2,{from:owner});
            await Voting.startProposals({from:owner});
        });
        it("Fail if description is empty",async function(){
            await expectRevert(Voting.voterAddProposal("",{from:user1}),
                "your description is empty");
        });
        it("Fail if description already exists",async function(){
            await Voting.voterAddProposal("my description",{from:user1});
            await expectRevert(Voting.voterAddProposal("my description",{from:user2}),
                "this description is already used");
        });
        it("Fail if the proposals is not registered correctly", async function(){
            await Voting.voterAddProposal("my description",{from:user1});
            await Voting.Proposals.call(0,function(error,result){
                Assert.equal(result.description,
                    "my description",
                    'Proposal description should be "my description"');
                Assert.equal(result.proposalAddress,
                    user1,
                    'Proposal proposalAddress should be address user1');
                Assert.equal(result.voteCount,
                    0,
                    'Proposal voteCount should be 0');
                Assert.equal(result.numberFinalist,
                    0,
                    'Proposa numberFinalist should be 0');
            });
        });
        it("Fail if Event registerProposal does not have the correct data",async function(){
            const newProposal = await Voting.voterAddProposal('my description',{from:user1});
            await Voting.Proposals.call(0,function(error,result){
                checkProposal = result;
            });
            await expectEvent(newProposal,
                'registerProposal',
                {
                    _proposal: [
                        checkProposal.proposalAddress,
                        checkProposal.description,
                        checkProposal.voteCount.toNumber().toString(),
                        checkProposal.numberFinalist.toNumber().toString()]
            });
        });
    });



    context("Try to run a complete vote with a tie then a 2nd round", function(){
        beforeEach(async function(){
            Voting = await VotingContract.new({from:owner});

            await Voting.registerVoter(user1,{from:owner});
            await Voting.registerVoter(user2,{from:owner});
            await Voting.registerVoter(user3,{from:owner});

            await Voting.startProposals({from:owner});

            await Voting.voterAddProposal("je suis le user1 votez pour moi !", {from:user1});
            await Voting.voterAddProposal("je suis le user2 votez pour moi !", {from:user2});

            await Voting.endProposals({from:owner});
            await Voting.startVote({from:owner});

            await Voting.vote(0,{from:user1});
            await Voting.vote(1,{from:user2});

            await Voting.endVote({from:owner});
            await Voting.countVote({from:owner});

            await Voting.vote(1,{from:user1});
            await Voting.endVote({from:owner});
            await Voting.countVote({from:owner});
        });
        it("Fail if finalist is not find",async function(){
            await Voting.Winner.call({from:owner},function (error,result){
                descriptionWinner = result.description;
            });
            await Voting.finalist.call(0,{from:owner},function(error,result){
                descriptionFinalist = result.description;
            });
            Assert.equal(descriptionWinner, descriptionFinalist,
                'The winner could not be found');
        });
    });

    context("Test the workflow", function() {
        beforeEach(async function(){
            Voting = await VotingContract.new({from:owner});
            await Voting.registerVoter(user1,{from:owner});
        });
        it('Fail if function registerVoter call after startProposals', async function(){
            await Voting.startProposals({from:owner});

            await expectRevert(Voting.registerVoter(user1,{from:owner}),'cannot add new voters');
        });
        it('Fail if function voterAddProposal call after endProposals',async function(){
            await Voting.startProposals({from:owner});
            await Voting.endProposals({from:owner});

            await expectRevert(Voting.registerVoter(user1,{from:owner}),'cannot add new voters');
            await expectRevert(Voting.startProposals({from:owner}),'cannot start session proposals');
            await expectRevert(Voting.voterAddProposal("test description",{from:user1}),'cannot add proposal');
        });
        it('Fail if function endProposals call after startVote',async function(){
            await Voting.startProposals({from:owner});
            await Voting.endProposals({from:owner});
            await Voting.startVote({from:owner});

            await expectRevert(Voting.registerVoter(user1,{from:owner}),'cannot add new voters');
            await expectRevert(Voting.startProposals({from:owner}),'cannot start session proposals');
            await expectRevert(Voting.voterAddProposal("test description",{from:user1}),'cannot add proposal');
            await expectRevert(Voting.endProposals({from:owner}),'cannot end session proposals');
        });
        it('Fail if function vote call after endVote',async function(){
            await Voting.startProposals({from:owner});
            await Voting.endProposals({from:owner});
            await Voting.startVote({from:owner});
            await Voting.endVote({from:owner});

            await expectRevert(Voting.registerVoter(user1,{from:owner}),'cannot add new voters');
            await expectRevert(Voting.startProposals({from:owner}),'cannot start session proposals');
            await expectRevert(Voting.voterAddProposal("test description",{from:user1}),'cannot add proposal');
            await expectRevert(Voting.endProposals({from:owner}),'cannot end session proposals');
            await expectRevert(Voting.startVote({from:owner}),'cannot start session vote');
            await expectRevert(Voting.vote(0,{from:user1}),'cannot vote');
        });
        it('failed if a workflow function can be called after the votes have been counted',async function(){
            await Voting.startProposals({from:owner});
            await Voting.voterAddProposal('test description',{from:user1});
            await Voting.endProposals({from:owner});
            await Voting.startVote({from:owner});
            await Voting.vote(0,{from:user1});
            await Voting.endVote({from:owner});
            await Voting.countVote({from:owner});

            await expectRevert(Voting.registerVoter(user1,{from:owner}),'cannot add new voters');
            await expectRevert(Voting.startProposals({from:owner}),'cannot start session proposals');
            await expectRevert(Voting.voterAddProposal("test description",{from:user1}),'cannot add proposal');
            await expectRevert(Voting.endProposals({from:owner}),'cannot end session proposals');
            await expectRevert(Voting.startVote({from:owner}),'cannot start session vote');
            await expectRevert(Voting.vote(0,{from:user1}),'cannot vote');
            await expectRevert(Voting.endVote({from:owner}),'cannot stop vote session');
            await expectRevert(Voting.countVote({from:owner}),'cannot count vote');
        });
    });
});