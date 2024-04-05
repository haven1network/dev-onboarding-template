# Solidity API

## H1Developed\_\_FeeTransferFailed

```solidity
error H1Developed__FeeTransferFailed(address to, uint256 amount)
```

This error is thrown when a fee transfer failed.

### Parameters

| Name   | Type    | Description                    |
| ------ | ------- | ------------------------------ |
| to     | address | The recipient address.         |
| amount | uint256 | The amount of the transaction. |

## H1Developed\_\_InvalidAddress

```solidity
error H1Developed__InvalidAddress(address provided, string source)
```

This error is thrown when an address validation has failed.

### Parameters

| Name     | Type    | Description                   |
| -------- | ------- | ----------------------------- |
| provided | address | The address provided.         |
| source   | string  | The origination of the error. |

## H1Developed\_\_InsufficientFunds

```solidity
error H1Developed__InsufficientFunds(uint256 fundsInContract, uint256 currentFee)
```

This error is thrown when there are insufficient funds send to
pay the fee.

### Parameters

| Name            | Type    | Description                         |
| --------------- | ------- | ----------------------------------- |
| fundsInContract | uint256 | The current balance of the contract |
| currentFee      | uint256 | The current fee amount              |

## H1Developed\_\_ArrayLengthMismatch

```solidity
error H1Developed__ArrayLengthMismatch(uint256 a, uint256 b)
```

_Error to throw when the length of n arrays are required to be equal
and are not._

### Parameters

| Name | Type    | Description                     |
| ---- | ------- | ------------------------------- |
| a    | uint256 | The length of the first array.  |
| b    | uint256 | The length of the second array. |

## H1Developed\_\_ArrayLengthZero

```solidity
error H1Developed__ArrayLengthZero()
```

_Error to throw when the length of an array must be greater than zero
and it is not._

## H1Developed\_\_IndexOutOfBounds

```solidity
error H1Developed__IndexOutOfBounds(uint256 idx, uint256 maxIdx)
```

_Error to throw when a user tries to access an invalid index of an array.
param idx The index that was accessed.
param maxIdx The maximum index that can be accessed on the array._

## H1Developed\_\_InvalidFnSignature

```solidity
error H1Developed__InvalidFnSignature(string sig)
```

_Error to throw when an invalid function signature has been provided._

### Parameters

| Name | Type   | Description             |
| ---- | ------ | ----------------------- |
| sig  | string | The provided signature. |

## H1Developed\_\_InvalidFeeAmount

```solidity
error H1Developed__InvalidFeeAmount(uint256 fee)
```

_Error to throw when an attempt add a fee is made and it falls
outside the constraints set by the `FeeContract`._

### Parameters

| Name | Type    | Description             |
| ---- | ------- | ----------------------- |
| fee  | uint256 | The invalid fee amount. |
