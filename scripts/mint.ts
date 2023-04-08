// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
// import { chainIds, proxyGatewayAddr } from "./config/testnet/sepolia"; // NOTE: update the config before deployment

async function main() {
    const tokenAddr = "0x1C68BCD6E18E3b047EfDF1C6Cc35AB4b21B1A636";

    const Token = await ethers.getContractFactory("Token").attach("0x1C68BCD6E18E3b047EfDF1C6Cc35AB4b21B1A636");

    await Token.mint("0x453AA106A34e8F72fAA687326071bAC1E5D34af5", 1)
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
