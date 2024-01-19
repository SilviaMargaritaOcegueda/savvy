require("@nomicfoundation/hardhat-toolbox");

/** @type import('
 * hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    tenderly: {
      chainId: 1,
      url: "https://rpc.tenderly.co/fork/1579f50a-8d52-40e1-8969-680aeb507dac",
    },
  },
};
