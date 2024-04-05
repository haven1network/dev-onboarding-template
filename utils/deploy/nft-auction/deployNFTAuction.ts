// @TODO UPDATE THIS WHEN CONTRACT IS DONE
/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { BigNumberish } from "ethers";
import type { NFTAuction } from "@typechain";

/* TYPES
================================================== */
type AuctionKindKey = keyof typeof AUCTION_KIND;
type AuctionKindVal = (typeof AUCTION_KIND)[keyof typeof AUCTION_KIND];

export type AuctionConfig = {
    readonly kind: AuctionKindVal;
    readonly length: bigint;
    readonly startingBid: bigint;
    readonly nft: string;
    readonly nftID: bigint;
    readonly beneficiary: string;
};

export type NFTAuctionInitalizerArgs = {
    readonly feeContract: string;
    readonly proofOfIdentity: string;
    readonly association: string;
    readonly developer: string;
    readonly feeCollector: string;
    readonly fnSigs: string[];
    readonly fnFees: BigNumberish[];
    readonly auctionConfig: AuctionConfig;
};

/* CONSTANTS AND UTILS
================================================== */
export const AUCTION_KIND = {
    RETAIL: 1,
    INSTITUTION: 2,
    ALL: 3,
} as const;

/**
 * Returns the numeric value associated with an auction kind.
 *
 * @function    getAuctionKind
 * @param       {AuctionKindKey}    auction
 * @returns     {AuctionKindVal}
 */
export function getAuctionKind(auction: AuctionKindKey): AuctionKindVal {
    return AUCTION_KIND[auction];
}

/* DEPLOY
================================================== */
/**
 * Deploys the `NFTAuction` contract.
 *
 * # Error
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @function    deployNFTAuction
 * @param       {NFTAuctionInitalizerArgs}  args
 * @param       {HardhatEthersSigner}       signer
 * @param       {number}                    [confs = 2] - Number of confirmations
 * @returns     {Promise<NFTAuction>}       Promise that resolves to the `NFTAuction` contract
 * @throws
 */
export async function deployNFTAuction(
    args: NFTAuctionInitalizerArgs,
    signer: HardhatEthersSigner,
    confs: number = 2
): Promise<NFTAuction> {
    const f = await ethers.getContractFactory("NFTAuction", signer);

    const c = await upgrades.deployProxy(
        f,
        [
            args.feeContract,
            args.proofOfIdentity,
            args.association,
            args.developer,
            args.feeCollector,
            args.fnSigs,
            args.fnFees,
            args.auctionConfig,
        ],
        { kind: "uups", initializer: "initialize" }
    );

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    return c as unknown as NFTAuction;
}
