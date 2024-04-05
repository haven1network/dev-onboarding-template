/* IMPORT NODE MODULES
================================================== */
import {
    type BigNumberish,
    type AddressLike,
    type TransactionReceipt,
} from "ethers";
import { ethers } from "hardhat";
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

/* UTILS
================================================== */
/**
 * Wrapper around `ethers.formatUnits` that converts a value into decimal
 * string, with the correct H1 decimal places.
 *
 * @function    formatH1
 * @param       {BigNumberish}   amount
 * @returns     {string}
 */
export function formatH1(amount: BigNumberish): string {
    return ethers.formatUnits(amount, 18);
}

/**
 * Wrapper around `ethers.parseUnits` that converts a decimal string to a
 * `bigint`, parsed to 18 decimals.
 *
 * @function    parseH1
 * @param       {string}   amount
 * @returns     {bigint}
 */
export function parseH1(amount: string): bigint {
    return ethers.parseUnits(amount, 18);
}

/**
 * Sends H1 from the `from` signer to the `to` address.
 * The `amount` should be a plain dec string, e.g., "100".
 *
 * # Errors
 * This function may error. It is up to the calling code to handle as desired.
 *
 * @async
 * @function    sendH1
 * @param       {HardhatEthersSigner}   from
 * @param       {AddressLike}           to
 * @param       {string}                amount
 * @param       {string}                [unencodedData]
 * @returns     {Promise<TransactionReceipt | null>}
 * @throws
 */
export async function sendH1(
    from: HardhatEthersSigner,
    to: AddressLike,
    amount: string,
    unencodedData?: string
): Promise<TransactionReceipt | null> {
    const value = parseH1(amount);

    const data = unencodedData && ethers.encodeBytes32String(unencodedData);

    const tx = await from.sendTransaction({ to, value, data });
    return await tx.wait();
}

/**
 * Sends H1 from the `from` signer to the `to` address.
 * The `amount` should be a bigint, pre-parsed.
 *
 * # Errors
 * This function may error. It is up to the calling code to handle as desired.
 *
 * @async
 * @function    sendH1Bigint
 * @param       {HardhatEthersSigner}   from
 * @param       {AddressLike}           to
 * @param       {bigint}                amount
 * @param       {string}                [unencodedData]
 * @returns     {Promise<TransactionReceipt | null>}
 * @throws
 */
export async function sendH1Bigint(
    from: HardhatEthersSigner,
    to: AddressLike,
    amount: bigint,
    unencodedData?: string
): Promise<TransactionReceipt | null> {
    const data = unencodedData && ethers.encodeBytes32String(unencodedData);

    const tx = await from.sendTransaction({ to, value: amount, data });
    return await tx.wait();
}

/**
 * Wrapper around `signer.provider.getBalance`.
 *
 * # Errors
 * This function may error. It is up to the calling code to handle as desired.
 *
 * @async
 * @function    getH1Balance
 * @param       {AddressLike}           address
 * @param       {HardhatEthersSigner}   signer
 * @returns     {Promise<bigint>}
 * @throws
 */
export async function getH1Balance(
    address: AddressLike,
    signer?: HardhatEthersSigner
): Promise<bigint> {
    signer ||= (await ethers.getSigners())[0];
    return await signer.provider.getBalance(address);
}
