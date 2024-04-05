/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { BigNumberish } from "ethers";
import type { FeeContract } from "@typechain";

/* TYPES
================================================== */
export type FeeInitalizerArgs = {
    readonly oracleAddress: string;
    readonly channels: string[];
    readonly weights: BigNumberish[];
    readonly haven1Association: string;
    readonly networkOperator: string;
    readonly deployer: string;
    readonly minDevFee: BigNumberish;
    readonly maxDevFee: BigNumberish;
    readonly asscShare: BigNumberish;
    readonly gracePeriod: BigNumberish;
};

/* DEPLOY
================================================== */
/**
 * Deploys the `FeeContract`.
 *
 * # Error
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @function    deployFeeContract
 * @param       {FeeInitalizerArgs}     args
 * @param       {HardhatEthersSigner}   signer
 * @param       {number}                [confs = 2] - Number of confirmations
 * @returns     {Promise<FeeContract>}  Promise that resolves to the Fee Contract
 * @throws
 */
export async function deployFeeContract(
    args: FeeInitalizerArgs,
    signer: HardhatEthersSigner,
    confs: number = 2
): Promise<FeeContract> {
    const f = await ethers.getContractFactory("FeeContract", signer);

    const c = await upgrades.deployProxy(
        f,
        [
            args.oracleAddress,
            args.channels,
            args.weights,
            args.haven1Association,
            args.networkOperator,
            args.deployer,
            args.minDevFee,
            args.maxDevFee,
            args.asscShare,
            args.gracePeriod,
        ],
        { kind: "uups", initializer: "initialize" }
    );

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    return c as unknown as FeeContract;
}
