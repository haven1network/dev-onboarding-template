import {
    ContractTransactionResponse,
    type ContractTransactionReceipt,
} from "ethers";

/**
 * Return the total gas cost of a transaction. Will return zero if the `txRec`
 * is null.
 *
 * @funtion     totalGas
 * @param       {ContractTransactionReceipt | null}   txRec
 * @returns     {bigint}
 */
export function totalGas(txRec: ContractTransactionReceipt | null): bigint {
    return (txRec?.gasUsed ?? 0n) * (txRec?.gasPrice ?? 0n);
}

/**
 * Get the timestamp of a transaction. Will return 0 if the timestamp was not
 * found.
 *
 * @async
 * @function    tsFromTxRec
 * @param       {ContractTransactionReceipt | null}   txRec
 * @returns     {Promise<number>}
 */
export async function tsFromTxRec(
    txRec: ContractTransactionReceipt | null
): Promise<number> {
    return (await txRec?.getBlock())?.timestamp ?? 0;
}

/**
 * Get the timestamp of a transaction. Will return 0 if the timestamp was not
 * found.
 *
 * @async
 * @function    tsFromTxRes
 * @param       {ContractTransactionResponse | null}   txRes
 * @returns     {Promise<number>}
 */
export async function tsFromTxRes(
    txRes: ContractTransactionResponse | null
): Promise<number> {
    return (await txRes?.getBlock())?.timestamp ?? 0;
}
