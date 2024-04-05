/* IMPORT NODE MODULES
================================================== */
import type { BaseContract } from "ethers";

/* TYPES
================================================== */
export type DeploymentData = {
    readonly contractName: string;
    readonly address: string;
    readonly hash: string;
    readonly nonce: number;
};

type Fn<T> = () => Promise<T>;

/* WRAPPER
================================================== */
/**
 *  Function that is a wrapper around any function that returns a type that
 *  extends `BaseContract`.
 *  Useful for logging the results of a deployment to the console.
 *  Returns a selection of data about the deployment.
 *
 *  @function   d
 *  @param      {string}    contractName
 *  @param      {Fn}        f
 *  @returns    {DeploymentData}
 */
export async function d<T extends BaseContract>(
    contractName: string,
    f: Fn<T>
): Promise<DeploymentData> {
    console.log(`Deploying: ${contractName}\n`);

    const c = await f();

    const address = await c.getAddress();
    let hash = "";
    let nonce = 0;

    const t = c.deploymentTransaction();
    if (t) {
        hash = t.hash;
        nonce = t.nonce;
    }

    console.table([
        { attr: "Hash", val: hash },
        { attr: "Address", val: address },
        { attr: "Nonce", val: nonce },
    ]);

    console.log("\nDeployment Completed\n");
    console.log("========================================\n");

    return { contractName, address, hash, nonce };
}
