import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    chiado: {
      chainId: 10200,
      url: "https://rpc.chiadochain.net",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
  }, 
  arbitrumGoerli: {
    chainId: 421613,
    url: "https://goerli-rollup.arbitrum.io/rpc",
    accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
  }
}
};

export default config;
