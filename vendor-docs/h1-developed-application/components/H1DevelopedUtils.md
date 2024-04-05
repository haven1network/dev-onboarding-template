# Solidity API

## FeeProposal

```solidity
struct FeeProposal {
    uint256 fee;
    bytes fnSig;
}
```

## FeeProposalFormatted

```solidity
struct FeeProposalFormatted {
    uint256 fee;
    string fnSig;
}
```

## Validate

_Library that consists of validation functions. Functions suffixed
with `exn` with throw expections if the given condition(s) are not met._

### feeExn

```solidity
function feeExn(uint256 fee, uint256 min, uint256 max) internal pure
```

Helper function to test the validity of a given fee against a
given min and max constraint.

_Will revert with `H1Developed__InvalidFeeAmount` if the fee is
less than the min or greater than the max._

#### Parameters

| Name | Type    | Description          |
| ---- | ------- | -------------------- |
| fee  | uint256 | The fee to validate. |
| min  | uint256 | The minimum fee.     |
| max  | uint256 | The maximum fee.     |

### addrExn

```solidity
function addrExn(address addr, string source) internal pure
```

Helper function to test the validity of a given address.

_Will revert with `H1Developed__InvalidAddress` if the address is
invalid._

#### Parameters

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| addr   | address | The address to check             |
| source | string  | The source of the address check. |

## FnSig

_Library that provides helpers for function signatures stored as bytes._

### toString

```solidity
function toString(bytes b) internal pure returns (string)
```

Decodes a given byte array `b` to a string. If the byte array
has no length, an empty string `""` is returned.

#### Parameters

| Name | Type  | Description               |
| ---- | ----- | ------------------------- |
| b    | bytes | The byte array to decode. |

### toFnSelector

```solidity
function toFnSelector(bytes b) internal pure returns (bytes4)
```

Converts a given byte array to a function signature.
If the byte array has no length, an empty bytes4 array is returned.

_The provided byte array is expected to be a function signature.
E.g., `abi.encode("transfer(address,uint256)");``_

#### Parameters

| Name | Type  | Description               |
| ---- | ----- | ------------------------- |
| b    | bytes | The byte array to decode. |
