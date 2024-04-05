/** One day in seconds. */
export const DAY_SEC = 86_400;

/** One week in seconds. */
export const WEEK_SEC = DAY_SEC * 7;

/** One year in seconds. */
export const YEAR_SEC = DAY_SEC * 365;

/** The zero, or null, address. */
export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

/** Null address used to represent native H1 */
export const H1_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

/** The interface ID for ERC721. */
export const ERC_721_INTERFACE_ID = "0x80ac58cd";

/** The interface ID for ERC1155. */
export const ERC_1155_INTERFACE_ID = "0xd9b67a26";

/** Collection of Access Control revert messages. */
const ACCESS_CONTROL_REVERSIONS = {
    MISSING_ROLE:
        /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/,
} as const satisfies Record<string, RegExp>;

type AccessControlKey = keyof typeof ACCESS_CONTROL_REVERSIONS;

/**
 * Function to return the regex for an OZ `AccessControl` reversion message.
 *
 * @function accessControlErr
 * @param   {AccessControlKey} err
 * @returns {RegExp}
 */
export function accessControlErr(err: AccessControlKey): RegExp {
    return ACCESS_CONTROL_REVERSIONS[err];
}

/** Collection of Pausable revert messages. */
const PAUSABLE_ERRORS = {
    WHEN_NOT_PAUSED: "Pausable: paused",
    WHEN_PAUSED: "Pausable: not paused",
} as const satisfies Record<string, string>;

type PausableErrorsKey = keyof typeof PAUSABLE_ERRORS;

/**
 * Function to return an error message associated with an OZ `Pausable` contract
 * error.
 *
 * @function pausableErr
 * @param   {PausableErrorsKey} err
 * @returns {string}
 */
export function pausableErr(err: PausableErrorsKey): string {
    return PAUSABLE_ERRORS[err];
}

/** Collection of Safe ERC20 revert messages. */
const SAFE_ERC20_ERRORS = {
    LOW_LEVEL_CALL: "SafeERC20: low-level call failed",
    ERC20_OP: "SafeERC20: ERC20 operation did not succeed",
} as const satisfies Record<string, string>;

type SafeERC20Error = keyof typeof SAFE_ERC20_ERRORS;

/**
 * Function to return an error message associated with an OZ `SafeERC20` lib.
 *
 * @function safeERC20Err
 * @param   {SafeERC20Error} err
 * @returns {string}
 */
export function safeERC20Err(err: SafeERC20Error): string {
    return SAFE_ERC20_ERRORS[err];
}

/** Collection of ERC20 revert messages. */
const ERC20_ERRORS = {
    BURN_FROM_ZERO_ADDRESS: "ERC20: burn from the zero address",
    BURN_EXCEEDS_BALANCE: "ERC20: burn amount exceeds balance",
    MINT_TO_ZERO_ADDRESS: "ERC20: mint to the zero address",
    APPROVE_FROM_ZERO_ADDRESS: "ERC20: approve from the zero address",
    APPROVE_TO_ZERO_ADDRESS: "ERC20: approve to the zero address",
    INSUFFICIENT_ALLOWANCE: "ERC20: insufficient allowance",
    DECREASE_ALLOWANCE: "ERC20: decreased allowance below zero",
    TRANSFER_FROM_ZERO_ADDRESS: "ERC20: transfer from the zero address",
    TRANSFER_TO_ZERO_ADDRESS: "ERC20: transfer to the zero address",
    TRANSFER_EXCEEDS_BALANCE: "ERC20: transfer amount exceeds balance",
} as const satisfies Record<string, string>;

type ERC20Error = keyof typeof ERC20_ERRORS;

/**
 * Function to return an error message associated with an OZ `ERC20` contract.
 *
 * @function erc20Err
 * @param   {ERC20Error} err
 * @returns {string}
 */
export function erc20Err(err: ERC20Error): string {
    return ERC20_ERRORS[err];
}

/** Collection of Initializable revert messages. */
const INITIALIZBLE_ERRORS = {
    ALREADY_INITIALIZED: "Initializable: contract is already initialized",
    IS_INITIALIZING: "Initializable: contract is initializing",
    NOT_INITIALIZING: "Initializable: contract is not initializing",
} as const satisfies Record<string, string>;

type InitializableError = keyof typeof INITIALIZBLE_ERRORS;

/**
 * Function to return an error message associated with the OZ `Initializalbe`
 * contract.
 *
 * @function initialiazbleErr
 * @param   {InitializableError} err
 * @returns {string}
 */
export function initialiazbleErr(err: InitializableError): string {
    return INITIALIZBLE_ERRORS[err];
}

type H1DevelopedErrorKey = keyof typeof H1_DEVELOPED_ERRORS;

/** Collection of H1 Developed revert messages. */
const H1_DEVELOPED_ERRORS = {
    TRANSFER_FAILED: "H1Developed__FeeTransferFailed",
    INVALID_ADDRESS: "H1Developed__InvalidAddress",
    INSUFFICIENT_FUNDS: "H1Developed__InsufficientFunds",
    ARRAY_LENGTH_MISMATCH: "H1Developed__ArrayLengthMismatch",
    ARRAY_LENGTH_ZERO: "H1Developed__ArrayLengthZero",
    OUT_OF_BOUNDS: "H1Developed__IndexOutOfBounds",
    INVALID_FN_SIG: "H1Developed__InvalidFnSignature",
    INVALID_FEE_AMT: "H1Developed__InvalidFeeAmount",
} as const satisfies Record<string, string>;

/**
 * Function to return an error message from the `H1DevelopedApplication`
 * contract.
 *
 * @function h1DevelopedErr
 * @param   {H1DevelopedErrorKey} err
 * @returns {string}
 */
export function h1DevelopedErr(err: H1DevelopedErrorKey): string {
    return H1_DEVELOPED_ERRORS[err];
}
