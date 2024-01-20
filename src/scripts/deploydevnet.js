const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  // Prepare the deployer wallet - this will be based on the private key we set up in config
  const [deployer] = await ethers.getSigners();
  console.log(
    "Process env",
    ethers.providers.JsonRpcProvider(process.env.TENDERLY_URL)
  );
  // Prepare the provider - this will give us access to the blockchain via Tenderly DevNet
  provider = new ethers.providers.JsonRpcProvider(process.env.TENDERLY_URL);

  // GhoINteraction will be an ethers internal representation of the compiled contract
  const GhoInteraction = await ethers.getContractFactory(
    "GhoInteraction",
    deployer
  );
  console.log("Deploying GhoInteraction...");

  // GhoInteraction will be the instance of our contract that we are about to deploy
  const ghoInteraction = await GhoInteraction.deploy("Hello from Tenderly!");

  // We wait for the deployment to be completed and confirmed
  await ghoInteraction.deployed();
  await ghoInteraction.ghoInteraction(1);

  // This will tell us the address at which the contract was deployed
  console.log("GhoInteraction deployed to:", ghoInteraction.address);
}

// Do the thing!
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
