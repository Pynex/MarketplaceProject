import { task } from 'hardhat/config';

//npx hardhat balance --account "print address"
// l22
task("balance","Displays balance")
    .addParam('account','Account Address')
    .setAction(async (taskArgs, {ethers}) => {
        const account = taskArgs.account;
        const balance = await ethers.provider.getBalance(account);
         
        console.log(balance.toString());
    });