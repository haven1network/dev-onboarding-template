// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title BytesConversion
 * @author Haven1 Dev Team
 * @dev Library to decode bytes to a given type.
 */
library BytesConversion {
    function toString(bytes memory b) internal pure returns (string memory) {
        if (b.length == 0) return "";
        return abi.decode(b, (string));
    }

    function toU256(bytes memory b) internal pure returns (uint256) {
        if (b.length == 0) return 0;
        return abi.decode(b, (uint256));
    }

    function toBool(bytes memory b) internal pure returns (bool) {
        if (b.length == 0) return false;
        return abi.decode(b, (bool));
    }

    function toBytes(bytes memory b) internal pure returns (bytes memory) {
        if (b.length == 0) return "";
        return abi.decode(b, (bytes));
    }
}
