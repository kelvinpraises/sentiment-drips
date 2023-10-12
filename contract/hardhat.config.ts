import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-toolbox";
import "hardhat-ethernal";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

dotenv.config();

let deployPrivateKey = process.env.DEPLOYER_PRIVATE_KEY as string;
if (!deployPrivateKey) {
  // default first account deterministically created by local nodes like `npx hardhat node` or `anvil`
  throw "No deployer private key set in .env";
}

const infuraIdKey = process.env.INFURA_RPC_ID as string;

const chainIds = {
  // Local Network
  localhost: 31337,

  // Testnet Networks
  polygon: 0,
  fvm: 0,
  scroll: 0,
};

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 400,
      },
    },
  },

  networks: {
    // Local Networks
    localhost: createTestnetConfig("localhost", "http://localhost:8545"),
    hardhat: {
      mining: {
        auto: false,
        interval: 5000,
      },
    },

    // Test Networks
    polygon: createTestnetConfig("polygon"),
    fvm: createTestnetConfig("fvm"),
    scroll: createTestnetConfig("scroll"),
  },

  paths: {
    sources: "./src",
    cache: "./cache_hardhat",
  },

  ethernal: {
    email: process.env.ETHERNAL_EMAIL,
    password: process.env.ETHERNAL_PASSWORD,

    disableSync: false, // If set to true, plugin will not sync blocks & txs
    disableTrace: false, // If set to true, plugin won't trace transaction
    workspace: undefined, // Set the workspace to use, will default to the default workspace (latest one used in the dashboard). It is also possible to set it through the ETHERNAL_WORKSPACE env variable
    uploadAst: true, // If set to true, plugin will upload AST, and you'll be able to use the storage feature (longer sync time though)
    disabled: false, // If set to true, the plugin will be disabled, nothing will be synced, ethernal.push won't do anything either
    resetOnStart: undefined, // Pass a workspace name to reset it automatically when restarting the node, note that if the workspace doesn't exist it won't error
    serverSync: false, // Only available on public explorer plans - If set to true, blocks & txs will be synced by the server. For this to work, your chain needs to be accessible from the internet. Also, trace won't be synced for now when this is enabled.
    skipFirstBlock: false, // If set to true, the first block will be skipped. This is mostly useful to avoid having the first block synced with its tx when starting a mainnet fork
    verbose: true, // If set to true, will display this config object on start and the full error object
  },
};

/**
 * Generates hardhat network configuration the test networks.
 * @param network
 * @param url (optional)
 * @returns {NetworkUserConfig}
 */
function createTestnetConfig(
  network: keyof typeof chainIds,
  url?: string
): NetworkUserConfig {
  if (!url) {
    url = `https://${network}.infura.io/v3/${infuraIdKey}`;
  }
  return {
    accounts: [deployPrivateKey],
    chainId: chainIds[network],
    allowUnlimitedContractSize: true,
    url,
    gasPrice: 20000000000,
  };
}

export default config;
