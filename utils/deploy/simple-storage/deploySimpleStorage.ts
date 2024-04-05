/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { BigNumberish } from "ethers";
import type { SimpleStorage } from "@typechain";

/* TYPES
================================================== */
export type SimpleStorageInitalizerArgs = {
    readonly feeContract: string;
    readonly association: string;
    readonly developer: string;
    readonly feeCollector: string;
    readonly fnSigs: string[];
    readonly fnFees: BigNumberish[];
};

/* DEPLOY
================================================== */
/**
 * Deploys the `SimpleStorage` contract.
 *
 * # Error
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @function    deploySimpleStorage
 * @param       {SimpleStorageInitalizerArgs}   args
 * @param       {HardhatEthersSigner}           signer
 * @param       {number}                        [confs = 2] - Number of confirmations
 * @returns     {Promise<SimpleStorage>}        Promise that resolves to the `SimpleStorage` contract
 * @throws
 */
export async function deploySimpleStorage(
    args: SimpleStorageInitalizerArgs,
    signer: HardhatEthersSigner,
    confs: number = 2
): Promise<SimpleStorage> {
    const f = await ethers.getContractFactory("SimpleStorage", signer);

    const c = await upgrades.deployProxy(
        f,
        [
            args.feeContract,
            args.association,
            args.developer,
            args.feeCollector,
            args.fnSigs,
            args.fnFees,
        ],
        { kind: "uups", initializer: "initialize" }
    );

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    return c as unknown as SimpleStorage;
}
