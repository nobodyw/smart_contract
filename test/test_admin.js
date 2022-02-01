const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const Assert = require("assert");
const Web3 = require('web3');
const AdminContract = artifacts.require("./Admin.sol");

contract("Admin",function(accounts){
    const owner = accounts[0];
    const user = accounts[1];
    const user2 = accounts[2];

    context("add User to WhiteList", function (){
        beforeEach(async function(){
            // add user to whiteList

            adminInstance = await AdminContract.new({from:owner});
            userAddedWhiteList = await adminInstance.addToWhiteList(user,{from:owner});
        });

        it("Fail if user in whiteList is not equal true",async function (){
            Assert.equal(await adminInstance.isWhitelisted(user,{from:owner}),
                true, "User in whiteList is not equal true");
        });
        it("Fail if event Whitelisted don't return adress User and true",async function(){
            await expectEvent(userAddedWhiteList,'Whitelisted',
                { userWhiteList: user, isWhiteList: true});
        });
        it("Fail if user in BlackListedd added to WhiteList not return true",async function(){
            await expectRevert(adminInstance.addToWhiteList(user,{from:owner}),
                "The account is already WhiteListed");
        });
        it("Fail if user add to BlackList not return false",async function(){
            await adminInstance.addToBlackList(user2,{from:owner});
            Assert.equal(await adminInstance.isWhitelisted(user2,{from:owner}),
                false, 'is WhiteListed must be false');
            Assert.equal(await adminInstance.isBlacklisted(user2,{from:owner}),
                true, 'is BlackListed must be true');
        });
        it("Check if remove return false",async function(){
            await adminInstance.removeList(user,{from:owner});
            Assert.equal(await adminInstance.isWhitelisted(user,{from:owner}),
                false,'must be return false');
            Assert.equal(await adminInstance.isBlacklisted(user,{from:owner}),
                false,'must be return false');
        });
    });
});
