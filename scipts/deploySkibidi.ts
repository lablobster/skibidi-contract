import { ethers, run } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Get the contract factory
    const Skibidi = await ethers.getContractFactory("Skibidi");

    // Deploy the contract
    const skibidi = await Skibidi.deploy();
    await skibidi.waitForDeployment();
    const skibidiAddress = await skibidi.getAddress();
    console.log("Skibidi deployed to:", skibidiAddress);

    // Verify the contract
    await run("verify:verify", {
        address: skibidiAddress,
        constructorArguments: [],
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
