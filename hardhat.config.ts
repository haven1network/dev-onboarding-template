import "hardhat/types/config";
import { type HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-solhint";
import "hardhat-contract-sizer";
import "@openzeppelin/hardhat-upgrades";
import "solidity-docgen";

import "tsconfig-paths/register";

import * as dotenv from "dotenv";

import "./tasks";

dotenv.config();

// See, in general, https://hardhat.org/hardhat-runner/docs/config#configuration
const config: HardhatUserConfig = {
    networks: {
        hardhat: {
            mining: {
                auto: true,
                interval: 5000,
            },
        },
        remoteHardhat: {
            url: "http://hardhat:8545",
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.19",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                        details: { yul: true },
                    },
                },
            },
        ],
    },
    gasReporter: {
        enabled: true,
        outputFile: "gas-report.txt",
        noColors: true,
    },
    mocha: {
        timeout: 40_000,
    },
    contractSizer: {
        // see: https://github.com/ItsNickBarry/hardhat-contract-sizer
        alphaSort: false,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: true,
    },
    docgen: {
        // see: https://github.com/OpenZeppelin/solidity-docgen#readme
        outputDir: "./vendor-docs",
        pages: "files",
        exclude: ["examples"],
    },
};

export default config;
