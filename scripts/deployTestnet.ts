/**
 * @file This script handles deploying all the contracts in this project to the
 * Haven1 Testnet.
 *
 * # Deployer Address
 * It assumes that the 0th indexed address in the `accounts` array is the
 * private key of the account that will be used to deploy the contracts.
 * E.g.
 *
 * ```typescript
 * const config: HardhatUserConfig = {
 *     networks: {
 *         haven_testnet: {
 *             url: HAVEN_TESTNET_RPC,
 *             accounts: [TESTNET_DEPLOYER], // this account will deploy
 *         },
 *     },
 * }
 * ```
 *
 * # Order of Deployments
 * 1.   Simple Storage
 *
 * 2.   MocK NFT - To be used as the prize in the NFT Auction
 *
 * 3.   NFT Auction
 */

/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";

/* IMPORT CONSTANTS UTILS, AND TYPES
================================================== */
import { d } from "@utils/deploy/deployWrapper";
import { parseH1 } from "@utils/token";
import { WEEK_SEC } from "../test/constants";
import { writeJSON } from "@utils/json";
import { checkENV } from "@utils/checkENV";

import {
    SimpleStorageInitalizerArgs,
    deploySimpleStorage,
} from "@utils/deploy/simple-storage";
import {
    AuctionConfig,
    NFTAuctionInitalizerArgs,
    deployNFTAuction,
    getAuctionKind,
} from "@utils/deploy/nft-auction";

/* CONSTANTS, UITLS, AND TYPES
================================================== */
const REQUIRED_VARS = [
    "TESTNET_CHAIN_ID",
    "HAVEN_TESTNET_RPC",
    "TESTNET_DEPLOYER",
    "TESTNET_ASSOCIATION_ADDRESS",
    "TESTNET_DEV_ADDRESS",
    "TESTNET_FEE_CONTRACT",
    "TESTNET_POI_CONTRACT",
];

/* SCRIPT
================================================== */
async function main() {
    // check to make sure that all required env vars are present
    // if this test passes, any env vars defined above can now safely be cast
    // as string.
    const missingVars = checkENV(REQUIRED_VARS);
    if (missingVars.length > 0) {
        throw new Error(`ErrMissingVars: ${missingVars.join("\n")}`);
    }

    /* Setup
    ======================================== */
    const [deployer] = await ethers.getSigners();

    const association = process.env.TESTNET_ASSOCIATION_ADDRESS as string;
    const developer = process.env.TESTNET_DEV_ADDRESS as string;
    const feeContract = process.env.TESTNET_FEE_CONTRACT as string;
    const poiContract = process.env.TESTNET_POI_CONTRACT as string;

    /* Simple Storage
    ======================================== */
    const simpleStorage = await d("Simple Storage", async function () {
        const fnSigs = ["incrementCount()", "decrementCount()"];
        const fnFees = [parseH1("2"), parseH1("3")];

        const args: SimpleStorageInitalizerArgs = {
            feeContract,
            association,
            developer,
            feeCollector: developer,
            fnSigs,
            fnFees,
        };

        return await deploySimpleStorage(args, deployer);
    });

    /* Mock NFT
    ======================================== */
    const mockNFT = await d("Mock NFT", async function () {
        const f = await ethers.getContractFactory("MockNFT", deployer);
        const c = await f.deploy(10_000);
        return await c.waitForDeployment();
    });

    /* NFT AUCTION
    ======================================== */
    const auction = await d("NFT Auction", async function () {
        const nftID = 1n;
        const fnSigs = ["bid()"];
        const fnFees = [parseH1("1")];

        const auctionConfig: AuctionConfig = {
            kind: getAuctionKind("ALL"),
            length: BigInt(WEEK_SEC),
            startingBid: parseH1("10"),
            nft: mockNFT.address,
            nftID,
            beneficiary: developer,
        };

        const args: NFTAuctionInitalizerArgs = {
            feeContract: feeContract,
            proofOfIdentity: poiContract,
            association: association,
            developer,
            feeCollector: developer,
            fnSigs,
            fnFees,
            auctionConfig,
        };

        return await deployNFTAuction(args, deployer);
    });

    /* Output
    ======================================== */
    const data = {
        simpleStorage: simpleStorage.address,
        mockNFT: mockNFT.address,
        auction: auction.address,
    } as const satisfies Record<string, unknown>;

    const path = "../deployment_data/testnet/deployments.json";
    const success = writeJSON(path, data);

    if (!success) {
        console.error("Write to JSON failed");
    }
}

main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
