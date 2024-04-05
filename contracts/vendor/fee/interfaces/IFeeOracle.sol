// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IFeeOracle
/// @dev The interface for the FeeOracle contract
interface IFeeOracle {
    /// @notice Returns the value of H1 denominated in USD.
    /// @return Value of H1, denominated in USD.
    function consult() external view returns (uint256);

    /// @notice Refreshes the oracle
    /// @return Whether the refresh was successful
    function refreshOracle() external returns (bool);
}
