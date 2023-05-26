import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";


dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  solidity: {
    compilers: [
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
        },
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
        },
      },
      {
        version: "0.4.25",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
        },
      },
    ]
  },
  networks: {
    pulsechain: {
      url: 'https://rpc.pulsechain.com',
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      chainId: 369,
    },
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    coinmarketcap: process.env.CMC_API,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API,
  },
};

export default config;
