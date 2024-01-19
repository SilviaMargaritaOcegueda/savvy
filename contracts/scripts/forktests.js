const { ethers } = require("ethers");
// const { ethers } = require("hardhat");
// for string converting to use as byte32
//const utils = ethers.utils;
const { utils } = ethers;

const hre = require("hardhat");

async function main() {
  const WALLETS = [
    "0xD49450E0110b8EB31a2FE02F82DAeeB5b4c9Dc7C",
    "0x63F4c7728521F14f76D55Bc65e0B44913D8d441c",
  ];
  console.log("this is the string: ", ethers.utils.parseUnits("10", "ether"));
  const result = await hre.network.provider.send("tenderly_setBalance", [
    WALLETS,
    //amount in wei will be set for all wallets
    ethers.utils.hexValue(ethers.utils.parseUnits("10", "ether").toHexString()),
    //ethers.utils..hexlify(ethers.parseUnits("10", "ether").toHexString()),
  ]);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
