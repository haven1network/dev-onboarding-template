/* TYPES
================================================== */
type TimeFrame = "years" | "months" | "days" | "hours" | "minutes" | "seconds";
type Output = "ms" | "sec";

/* FUNCTIONS
================================================== */
/**
 * Takes in a timestamp in ms and adds an amount of time to it. Returns a new
 * timestamp in ms by default, however can also return seconds.
 *
 * # Errors
 * Will throw an error `Invalid time frame` if an invalid time frame is provided.
 *
 * @function    addTime
 *
 * @param       {number}    ts          The starting timestamp in ms
 * @param       {number}    amount      The amount of time to add
 * @param       {TimeFrame} timeFrame   The time frame of the amount to add.
 * @param       {Output}    [output]    The output type: ms or sec. Defaults ms.
 * @returns     {number}    The new timestamp.
 *
 * @example
 *      const newTime = addTime(Date.now(), 1, "years")
 *      const newTime = addTime(Date.now(), 1, "years", "ms")
 *      const newTime = addTime(Date.now(), 1, "years", "sec")
 */
export function addTime(
    ts: number,
    amount: number,
    timeFrame: TimeFrame,
    output: Output = "ms"
): number {
    const date = new Date(ts);

    switch (timeFrame) {
        case "years":
            date.setFullYear(date.getFullYear() + amount);
            break;
        case "months":
            date.setMonth(date.getMonth() + amount);
            break;
        case "days":
            date.setDate(date.getDate() + amount);
            break;
        case "hours":
            date.setHours(date.getHours() + amount);
            break;
        case "minutes":
            date.setMinutes(date.getMinutes() + amount);
            break;
        case "seconds":
            date.setSeconds(date.getSeconds() + amount);
            break;
        default:
            throw new Error("Invalid time frame");
    }

    if (output === "sec") return msToSec(date.getTime());
    return date.getTime();
}

/**
 * Takes in a ms timestamp and converts it to seconds. If the conversion results
 * in a fractional number, the time will be __rounded up__ to the nearest second.
 *
 * @function    msToSec
 *
 * @param       {number}    ts  The ms timestamp to convert
 * @returns     {number}    The timestamp, rounded up to the nearest second.
 */
export function msToSec(ts: number): number {
    // convert to seconds, remove decimals and add one second to round up
    return Number((ts / 1000).toString().split(".")[0]) + 1;
}

/**
 * Takes in a timestamp in seconds and returns the start of the next day in UTC.
 *
 * @function    getStartOfNextDayUTC
 *
 * @param       {number}    ts  The timestamp in seconds
 * @returns     {number}    The start of the next day in seconds
 */
export function getStartOfNextDayUTC(ts: number): number {
    // Create a Date object from the timestamp (assumed to be in seconds)
    const date = new Date(ts * 1000);

    // Convert to UTC and set to start of the current day
    date.setUTCHours(0, 0, 0, 0);

    // Add one day to get the start of the next day
    date.setUTCDate(date.getUTCDate() + 1);

    // Convert back to a timestamp in seconds and return
    return Math.floor(date.getTime() / 1000);
}
