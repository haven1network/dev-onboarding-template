/**
 * @file This script handles deploying all the contracts for this project to
 * the local node.
 *
 * # Deployer Address
 * It assumes that the 0th indexed address in the `accounts` array is the
 * private key of the account that will be used to deploy the contracts.
 *
 * # Order of Deployments
 * 1.   Mock Account Manager
 *
 * 2.   Mock Permissions Interface
 *
 * 3.   Proof of Identity
 *
 * 4.   Fix Fee Oracle
 *
 * 5.   Fee Contract
 *
 * 6.   Simple Storage
 *
 * 7.   MocK NFT - To be used as the prize in the NFT Auction
 *
 * 8.   NFT Auction
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

import {
    ProofOfIdentityArgs,
    deployProofOfIdentity,
} from "@utils/deploy/proof-of-identity";

import { FeeInitalizerArgs, deployFeeContract } from "@utils/deploy/fee";

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

/* SCRIPT
================================================== */
async function main() {
    /* Setup
    ======================================== */
    const [assoc, operator, dev] = await ethers.getSigners();

    const assocAddr = await assoc.getAddress();
    const operatorAddr = await operator.getAddress();
    const devAddr = await dev.getAddress();

    /* Mock Account Manager
    ======================================== */
    const accManager = await d("Account Manager", async function () {
        const f = await ethers.getContractFactory("MockAccountManager", assoc);
        const c = await f.deploy();
        return await c.waitForDeployment();
    });

    /* Mock Permissions Interface
    ======================================== */
    const permInterface = await d("Permissions Interface", async function () {
        const f = await ethers.getContractFactory(
            "MockPermissionsInterface",
            assoc
        );

        const c = await f.deploy(accManager.address);
        return await c.waitForDeployment();
    });

    /* Proof of Identity
    ======================================== */
    const poi = await d("Proof of Identity", async function () {
        const args: ProofOfIdentityArgs = {
            associationAddress: assocAddr,
            networkOperatorAddress: operatorAddr,
            deployerAddress: assocAddr,
            permissionsInterfaceAddress: permInterface.address,
            accountManagerAddress: accManager.address,
        };

        return await deployProofOfIdentity(args, assoc);
    });

    /* Fixed Fee Oracle
    ======================================== */
    const oracle = await d("Fixed Fee Oracle", async function () {
        const startingVal = parseH1("1.2");

        const f = await ethers.getContractFactory("FixedFeeOracle", assoc);
        const c = await f.deploy(assoc, operator, startingVal);
        return await c.waitForDeployment();
    });

    /* Fee Contract
    ======================================== */
    const fee = await d("Fee Contract", async function () {
        const args: FeeInitalizerArgs = {
            oracleAddress: oracle.address,
            channels: [],
            weights: [],
            haven1Association: assocAddr,
            networkOperator: operatorAddr,
            deployer: assocAddr,
            minDevFee: parseH1("1"),
            maxDevFee: parseH1("3"),
            asscShare: parseH1("0.2"),
            gracePeriod: 600,
        };

        return await deployFeeContract(args, assoc);
    });

    /* Simple Storage
    ======================================== */
    const simpleStorage = await d("Simple Storage", async function () {
        const fnSigs = ["incrementCount()", "decrementCount()"];
        const fnFees = [parseH1("2"), parseH1("3")];

        const args: SimpleStorageInitalizerArgs = {
            feeContract: fee.address,
            association: assocAddr,
            developer: devAddr,
            feeCollector: devAddr,
            fnSigs,
            fnFees,
        };

        return await deploySimpleStorage(args, assoc);
    });

    /* Mock NFT
    ======================================== */
    const mockNFT = await d("Mock NFT", async function () {
        const f = await ethers.getContractFactory("MockNFT", assoc);
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
            beneficiary: devAddr,
        };

        const args: NFTAuctionInitalizerArgs = {
            feeContract: fee.address,
            proofOfIdentity: poi.address,
            association: assocAddr,
            developer: devAddr,
            feeCollector: devAddr,
            fnSigs,
            fnFees,
            auctionConfig,
        };

        return await deployNFTAuction(args, assoc);
    });

    /* Output
    ======================================== */
    const data = {
        accountManager: accManager.address,
        permissionsInterface: permInterface.address,
        proofOfIdentity: poi.address,
        oracle: oracle.address,
        feeContract: fee.address,
        simpleStorage: simpleStorage.address,
        mockNFT: mockNFT.address,
        auction: auction.address,
    } as const satisfies Record<string, unknown>;

    const path = "../deployment_data/local/deployments.json";
    const success = writeJSON(path, data);

    if (!success) {
        console.error("Write to JSON failed");
    }
}

main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
