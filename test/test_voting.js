const { expectRevert } = require('@openzeppelin/test-helpers');
const Assert = require("assert");
const Web3 = require('web3');
const VotingContract = artifacts.require("./Voting.sol");

contract("Voting", function(accounts){
    const owner = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];
    const user3 = accounts[3];
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
        it("test",async function(){
            console.log(await Voting.Winner.call());
        });
    });
});