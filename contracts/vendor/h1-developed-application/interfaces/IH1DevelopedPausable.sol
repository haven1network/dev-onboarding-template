// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IH1DevelopedPausable
 * @dev The interface for the H1DevelopedPausable
 */
interface IH1DevelopedPausable {
    /**
     * @notice Pauses the contract.
     */
    function pause() external;

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external;
}
