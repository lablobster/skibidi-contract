import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";

require("dotenv").config();
const {
  PRIVATE_KEY,
} = process.env;


const config: HardhatUserConfig = {
  solidity: "0.7.6",

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: "https://rpc.rollux.com/",
      },
    },
    rollux: {
      url: "https://rpc.rollux.com/",
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: "abc",
    customChains: [
      {
        network: "rollux",
        chainId: 570,
        urls: {
          apiURL: "https://explorer.rollux.com/api",
          browserURL: "https://explorer.rollux.com"
        }
      }
    ]
  }

};

export default config;