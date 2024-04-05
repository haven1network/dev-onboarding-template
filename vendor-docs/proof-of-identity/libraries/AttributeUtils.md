# Solidity API

## Attribute

```solidity
struct Attribute {
    uint256 expiry;
    uint256 updatedAt;
    bytes data;
}
```

## SupportedAttributeType

```solidity
enum SupportedAttributeType {
    STRING,
    BOOL,
    U256,
    BYTES
}
```

## AttributeUtils

_Library that contains the `Attribute` struct and associated methods._

### setAttribute

```solidity
function setAttribute(struct Attribute attr, uint256 expiry, uint256 updatedAt, bytes data) internal
```

Sets an attribute for the first time.

#### Parameters

| Name      | Type             | Description                                               |
| --------- | ---------------- | --------------------------------------------------------- |
| attr      | struct Attribute | The attribute to set.                                     |
| expiry    | uint256          | The timestamp of expiry of the attribute.                 |
| updatedAt | uint256          | The timestamp of the last time the attribute was updated. |
| data      | bytes            | The attribute data to set in bytes.                       |

### toString

```solidity
function toString(enum SupportedAttributeType attrType) internal pure returns (string)
```

Returns the string name of the `SupportedAttributeType`.

#### Parameters

| Name     | Type                        | Description                            |
| -------- | --------------------------- | -------------------------------------- |
| attrType | enum SupportedAttributeType | The supported attribute type to check. |

#### Return Values

| Name | Type   | Description                                      |
| ---- | ------ | ------------------------------------------------ |
| [0]  | string | The string name of the requested attribute type. |
