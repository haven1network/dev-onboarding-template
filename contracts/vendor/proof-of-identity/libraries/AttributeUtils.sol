// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Represents one attribute.
 * All attributes are stored as bytes via `abi.encode` in order to allow
 * for heterogeneous storage.
 */
struct Attribute {
    uint256 expiry;
    uint256 updatedAt;
    bytes data;
}

/**
 * @dev Represents the supported types of an attribute.
 */
enum SupportedAttributeType {
    STRING,
    BOOL,
    U256,
    BYTES
}

/**
 * @title AttributeUtils
 * @author Haven1 Dev Team
 * @dev Library that contains the `Attribute` struct and associated methods.
 */
library AttributeUtils {
    /**
     * @notice Sets an attribute for the first time.
     * @param attr The attribute to set.
     * @param expiry The timestamp of expiry of the attribute.
     * @param updatedAt The timestamp of the last time the attribute was updated.
     * @param data The attribute data to set in bytes.
     */
    function setAttribute(
        Attribute storage attr,
        uint256 expiry,
        uint256 updatedAt,
        bytes memory data
    ) internal {
        attr.expiry = expiry;
        attr.updatedAt = updatedAt;
        attr.data = data;
    }

    /**
     * @notice Returns the string name of the `SupportedAttributeType`.
     * @param attrType The supported attribute type to check.
     * @return The string name of the requested attribute type.
     */
    function toString(
        SupportedAttributeType attrType
    ) internal pure returns (string memory) {
        if (attrType == SupportedAttributeType.STRING) return "string";
        if (attrType == SupportedAttributeType.BOOL) return "bool";
        if (attrType == SupportedAttributeType.U256) return "uint256";
        return "bytes";
    }
}
