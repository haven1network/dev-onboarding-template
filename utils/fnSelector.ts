import { ethers } from "ethers";

/**
 * Returns the function selector for a given function signature.
 *
 * @function    fnSelector
 * @param       {string}    sig
 * @returns     {string}    The function selector
 *
 */
export function fnSelector(sig: string): string {
    // Function selector is the first four (4) bytes the keccak256 hash of the
    // bytes representation of the function signature.
    // E.g., bytes4(keccak256(bytes("transfer(address,uint256)")))
    //
    // Each hex digit is four bits. So 0x + first four bytes is the first ten
    // chars. 0x|d0|9d|e0|8a
    return ethers.id(sig).substring(0, 10);
}
