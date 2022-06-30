require('dotenv-flow').config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  compilers: {
    solc: {
      version: '0.5.16',    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
        // evmVersion: "istanbul"
      }
    },
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  networks: {
    boba_mainnet: {
      provider: () => new HDWalletProvider(process.env.DEPLOYER_PRIVATE_KEY, `https://mainnet.boba.network`),
      network_id: 288,
      timeoutBlocks: 200
      // gasPrice: 10000000000
    },
    boba_rinkeby: {
      provider: () => new HDWalletProvider(process.env.DEPLOYER_PRIVATE_KEY, `wss://wss.rinkeby.boba.network/`),
      network_id: 28,
      timeoutBlocks: 20
      // gas: 11000000
    }
  },
};
