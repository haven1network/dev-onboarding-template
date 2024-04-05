/**
 * Generates a random number starting at `from` until, but __not including__
 * `to`.
 *
 * # Error
 * Will throw an error if `to` is less than or equal to `from`.
 *
 * @function    randomNumber
 * @param       {number}    from
 * @param       {number}    to
 * @returns     {number}
 * @throws
 */
export function randomNumber(from: number, to: number): number {
    if (to <= from) {
        throw new Error(
            `Invalid arguments. Expected "to" to be greater than "from", got from = ${from}. to = ${to}.`
        );
    }
    const randomNumber = Math.random() * (to - from) + from;
    return Math.floor(randomNumber);
}
