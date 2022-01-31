const { expectRevert } = require('@openzeppelin/test-helpers');
const Assert = require("assert");
const Web3 = require('web3');
const BankContract = artifacts.require("./Bank.sol");

contract("Bank", function(accounts){
    const owner = accounts[0];
    const userBank = accounts[1];

    context("must add funds in the bank and withdraw them", function(){
        beforeEach(async function (){
            Bank = await BankContract.new({from: owner});
            await Bank.deposit(Web3.utils.toBN(10 * (10 **18)),{from:owner});
            await Bank.deposit(Web3.utils.toBN(5 * (10 **18)),{from:userBank});
        });

        it("Owner and userBank should deposit 10p18 and 5p18 in his bank account",async() =>{
            await expectRevert(Bank.deposit(0, {from:owner}),'amount is to low');
            Assert.equal(await Bank.balanceOf(owner,{from:owner}),
                10*(10**18),'error in deposit Owner');
            Assert.equal(await Bank.balanceOf(userBank,{from:userBank}),
                5*(10**18),'error in deposit userBank');
        });

        it("Owner should transfer 1p18 to userBank", async() => {
            await expectRevert(Bank.transfer(userBank,0,{from:owner}),
                'amount is to low');
            await expectRevert(Bank.transfer(owner,100,{from:owner}),
                'transfer only works with an account other');
            await Bank.transfer(userBank,Web3.utils.toBN(1 * (10 ** 18)),{from:owner});

            Assert.equal(await Bank.balanceOf(owner,{from:owner}),
                9 *(10**18),'error in transfer Owner');
            Assert.equal(await Bank.balanceOf(userBank,{from:userBank}),
                6*(10**18),'error in transfer Owner');
        });
    });
});