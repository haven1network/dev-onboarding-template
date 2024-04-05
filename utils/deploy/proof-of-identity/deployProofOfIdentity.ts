/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { ProofOfIdentity } from "@typechain";

/* TYPES
================================================== */
/**
 * The args required to initialise the Proof of Identity contract.
 */
export type ProofOfIdentityArgs = {
    readonly associationAddress: string;
    readonly networkOperatorAddress: string;
    readonly deployerAddress: string;
    readonly permissionsInterfaceAddress: string;
    readonly accountManagerAddress: string;
};

/**
 * The string representation of the supported attribute types.
 */
type AttributeTypeStr = "bool" | "string" | "uint256" | "bytes";

/**
 * The supported attribute type's id (matches the `SupportedAttributeType`)
 * enum from `AttributeUtils.sol` and its string representation.
 */
type SupportedAttributeType = {
    id: number;
    str: AttributeTypeStr;
};

type Attribute = {
    readonly id: number;
    readonly name: string;
    readonly attrType: SupportedAttributeType;
};

type AttributeMapping = { [key: string]: Attribute };

/* CONSTANTS
================================================== */
/**
 * Mapping of supported attribute types to the enum value
 */
export const SUPPORTED_ID_ATTRIBUTE_TYPES = {
    STRING: {
        id: 0,
        str: "string",
    },
    BOOL: {
        id: 1,
        str: "bool",
    },
    U256: {
        id: 2,
        str: "uint256",
    },
    BYTES: {
        id: 3,
        str: "bytes",
    },
} as const satisfies Record<string, SupportedAttributeType>;

/**
 *  Mapping of attributes to their ID and names.
 *
 *  # Important:
 *
 *  Update this mapping as more attributes are released so that the deployment
 *  scripts stay up to date
 */
export const PROOF_OF_ID_ATTRIBUTES = {
    PRIMARY_ID: {
        id: 0,
        name: "primaryID",
        attrType: SUPPORTED_ID_ATTRIBUTE_TYPES.BOOL,
    },
    COUNTRY_CODE: {
        id: 1,
        name: "countryCode",
        attrType: SUPPORTED_ID_ATTRIBUTE_TYPES.STRING,
    },
    PROOF_OF_LIVELINESS: {
        id: 2,
        name: "proofOfLiveliness",
        attrType: SUPPORTED_ID_ATTRIBUTE_TYPES.BOOL,
    },
    USER_TYPE: {
        id: 3,
        name: "userType",
        attrType: SUPPORTED_ID_ATTRIBUTE_TYPES.U256,
    },
    COMPETENCY_RATING: {
        id: 4,
        name: "competencyRating",
        attrType: SUPPORTED_ID_ATTRIBUTE_TYPES.U256,
    },
} as const satisfies AttributeMapping;

/* DEPLOY
================================================== */
/**
 * Deploys the `Proof of Identity contract`.
 *
 * # Error
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @function    deployProofOfIdentity
 * @param       {ProofOfIdentityArgs}       args
 * @param       {HardhatEthersSigner}       signer
 * @param       {number}                    [confs = 2] - Number of confirmations
 * @returns     {Promise<ProofOfIdentity>}  Promise that resolves to the `ProofOfIdentity` contract.
 * @throws
 */
export async function deployProofOfIdentity(
    args: ProofOfIdentityArgs,
    signer: HardhatEthersSigner,
    confs: number = 2
): Promise<ProofOfIdentity> {
    // deploy
    const f = await ethers.getContractFactory("ProofOfIdentity", signer);

    const c = (await upgrades.deployProxy(
        f,
        [
            args.associationAddress,
            args.networkOperatorAddress,
            args.deployerAddress,
            args.permissionsInterfaceAddress,
            args.accountManagerAddress,
        ],
        { kind: "uups", initializer: "initialize" }
    )) as unknown as ProofOfIdentity;

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    // set all attribute names and types
    for (const { id, name, attrType } of Object.values(
        PROOF_OF_ID_ATTRIBUTES
    )) {
        let txRes = await c.setAttributeName(id, name);
        await txRes.wait();

        txRes = await c.setAttributeType(id, attrType.id);
        await txRes.wait();
    }

    return c;
}
