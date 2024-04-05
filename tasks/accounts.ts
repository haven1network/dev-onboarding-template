import { task } from "hardhat/config";

// This is a sample Hardhat task. To learn how to create your own go to:
// https://hardhat.org/guides/create-task.html
task("accounts", "prints all signer accounts").setAction(async function (
    _,
    { ethers }
) {
    const accounts = await ethers.getSigners();
    for (let i = 0; i < accounts.length; ++i) {
        let out = `Account #${i}:\n${accounts[i].address}\n`;
        console.log(out);
    }
});
