/* CONSTANTS
================================================== */
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

/* UTILS
================================================== */
/**
 * Generates a dummy address, padded with zeros until the suffix.
 *
 * @function    generateDummyAddress
 * @param       {string}   suffix
 * @returns     {string}
 */
export function generateDummyAddress(suffix: string): string {
    return ZERO_ADDRESS.slice(0, -suffix.length) + suffix;
}

/**
 * Generates an array of dummy address.
 *
 * @function    generateDummyAddresses
 * @param       {number}    n
 * @returns     {string[]}
 */
export function generateDummyAddresses(n: number): string[] {
    const out: string[] = [];

    for (let i = 0; i < n; ++i) {
        out.push(generateDummyAddress(`${i + 1}`));
    }

    return out;
}
