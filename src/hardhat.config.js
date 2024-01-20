require("@nomicfoundation/hardhat-toolbox");

/** @type import('
 * hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

// Initialize hardhat-tenderly plugin for automatic contract verification
var tdly = require("@tenderly/hardhat-tenderly");
tdly.setup({ automaticVerifications: true });

// Your private key and tenderly devnet URL (which contains our secret id)
// We read both from the .env file so we can push this config to git and/or share publicly
const privateKey = process.env.PRIVATE_KEY;
const tenderlyUrl = process.env.TENDERLY_URL;
module.exports = {
  solidity: "0.8.20",
  networks: {
    tenderly: {
      chainId: 1,
      url: "https://rpc.tenderly.co/fork/1579f50a-8d52-40e1-8969-680aeb507dac",
    },
    devnet: {
      url: tenderlyUrl,
      // This will allow us to use our private key for signing later
      accounts: [`0x${privateKey}`],
      // This is the mainnet chain ID
      chainId: 1,
    },
  },
  tenderly: {
    // Replace with project slug in Tenderly
    project: "My First DevNet",
    // Replace with your Tenderly username
    username: "Marybee",
    // Perform contract verification in private mode
    privateVerification: true,
  },
};
