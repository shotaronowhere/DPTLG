import { ethers } from "hardhat";

async function main() {
  // send wxdai from Chiado to Arbitrum Goerli for usdc

  const tokenChiado = "0x18c8a7ec7897177E4529065a7E7B0878358B3BfF" // chiado wxdai
  const FBR = "0x730Ec040763bf5C4Abac1d66d7c757f6033a3A20" // FBR on chiado
  // transfer gateway on chiado
  const TransferGatewayContract = await ethers.getContractFactory("ERC20TransferGateway");
  console.log('yo')
  const tgate = await TransferGatewayContract.deploy(FBR,tokenChiado, {gasLimit: 40000000})
  console.log(`TransferGatewayContract deployed to ${tgate.address}`);


//  FBS 0xdF6D848D2A3219f4567bBd077B2F8C93563244Fc
  
  // LP Gateway on Arbitrum
  /*
    const tokenArb = "0xc944B73fBA33a773A4A07340333A3184A70aF1ae" // arbgoerli usdc
  const FBS = "0x6b575B3af80aDca9E5ABE1764Ae9dE439e85DEb7" // FBS on arbitrumgoerli
  const LPGateway = await ethers.getContractFactory("ERC20LPGateway");
  const lpgate = await LPGateway.deploy(FBS, tokenArb,tgate.address);

  await lpgate.deployed();

  console.log(`LP Gateway deployed to ${lpgate.address}`);
  */
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
