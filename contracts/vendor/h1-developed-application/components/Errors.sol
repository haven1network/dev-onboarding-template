// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice This error is thrown when a fee transfer failed.
 * @param to The recipient address.
 * @param amount The amount of the transaction.
 */
error H1Developed__FeeTransferFailed(address to, uint256 amount);

/**
 * @notice This error is thrown when an address validation has failed.
 * @param provided The address provided.
 * @param source The origination of the error.
 */
error H1Developed__InvalidAddress(address provided, string source);

/**
 * @notice This error is thrown when there are insufficient funds send to
 * pay the fee.
 *
 * @param fundsInContract The current balance of the contract
 * @param currentFee The current fee amount
 */
error H1Developed__InsufficientFunds(
    uint256 fundsInContract,
    uint256 currentFee
);

/**
 * @dev Error to throw when the length of n arrays are required to be equal
 * and are not.
 * @param a The length of the first array.
 * @param b The length of the second array.
 */
error H1Developed__ArrayLengthMismatch(uint256 a, uint256 b);

/**
 * @dev Error to throw when the length of an array must be greater than zero
 * and it is not.
 */
error H1Developed__ArrayLengthZero();

/**
 * @dev Error to throw when a user tries to access an invalid index of an array.
 * param idx The index that was accessed.
 * param maxIdx The maximum index that can be accessed on the array.
 */
error H1Developed__IndexOutOfBounds(uint256 idx, uint256 maxIdx);

/**
 * @dev Error to throw when an invalid function signature has been provided.
 * @param sig The provided signature.
 */
error H1Developed__InvalidFnSignature(string sig);

/**
 * @dev Error to throw when an attempt add a fee is made and it falls
 * outside the constraints set by the `FeeContract`.
 * @param fee The invalid fee amount.
 */
error H1Developed__InvalidFeeAmount(uint256 fee);
