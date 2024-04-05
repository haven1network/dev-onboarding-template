// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {H1Developed__InvalidFeeAmount, H1Developed__InvalidAddress} from "./Errors.sol";

struct FeeProposal {
    /**
     * @dev The fee, in USD, to 18 decimals of precision.
     */
    uint256 fee;
    /**
     * @dev The signature of the function for which the fee should be set.
     * E.g., `abi.encode("transfer(address,uint256)");``
     */
    bytes fnSig;
}

struct FeeProposalFormatted {
    /**
     * @dev The fee, in USD, to 18 decimals of precision.
     */
    uint256 fee;
    /**
     * @dev The signature of the function for which the fee should be set.
     * E.g., `transfer(address,uint256)`.
     */
    string fnSig;
}

/**
 * @title Validate
 * @author Haven1 Development Team
 * @dev Library that consists of validation functions. Functions suffixed
 * with `exn` with throw expections if the given condition(s) are not met.
 */
library Validate {
    /**
     * @notice Helper function to test the validity of a given fee against a
     * given min and max constraint.
     *
     * @param fee The fee to validate.
     * @param min The minimum fee.
     * @param max The maximum fee.
     *
     * @dev Will revert with `H1Developed__InvalidFeeAmount` if the fee is
     * less than the min or greater than the max.
     */
    function feeExn(uint256 fee, uint256 min, uint256 max) internal pure {
        if ((fee > 0 && fee < min) || fee > max) {
            revert H1Developed__InvalidFeeAmount(fee);
        }
    }

    /**
     * @notice Helper function to test the validity of a given address.
     *
     * @param addr The address to check
     * @param source The source of the address check.
     *
     * @dev Will revert with `H1Developed__InvalidAddress` if the address is
     * invalid.
     */
    function addrExn(address addr, string memory source) internal pure {
        if (addr == address(0)) {
            revert H1Developed__InvalidAddress(addr, source);
        }
    }
}

/**
 * @title FnSig
 * @author Haven1 Development Team
 * @dev Library that provides helpers for function signatures stored as bytes.
 */
library FnSig {
    /**
     * @notice Decodes a given byte array `b` to a string. If the byte array
     * has no length, an empty string `""` is returned.
     * @param b The byte array to decode.
     */
    function toString(bytes memory b) internal pure returns (string memory) {
        if (b.length == 0) return "";
        return string(b);
    }

    /**
     * @notice Converts a given byte array to a function signature.
     * If the byte array has no length, an empty bytes4 array is returned.
     * @param b The byte array to decode.
     * @dev The provided byte array is expected to be a function signature.
     * E.g., `abi.encode("transfer(address,uint256)");``
     */
    function toFnSelector(bytes memory b) internal pure returns (bytes4) {
        if (b.length == 0) return bytes4("");
        return bytes4(keccak256(b));
    }
}
