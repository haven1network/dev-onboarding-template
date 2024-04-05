# Solidity API

## H1DevelopedApplication

`H1DevelopedApplication` serves as the entry point into the Haven1
ecosystem for developers looking to deploy smart contract applications on
Haven1.

`H1DevelopedApplication` standardizes the following:

-   Establishing privileges;
-   Pausing and unpausing the contract;
-   Upgrading the contract;
-   Assigning fees to functions; and
-   Handling the payment of those fees.

`H1DevelopedApplication` exposes a modifier (`developerFee`) that is to be
attached to any function that has a fee associated with it. This modifier
will handle the fee logic.

IMPORTANT: Contracts that store H1 should **never** elect to refund the
remaining balance when using the `developerFee` modifier as it will send the
contract's balance to the user.

The `H1DevelopedApplication` does not implement `ReentrancyGuardUpgradeable`.
The inheriting contracts must implement this feature where needed.

### FeePaid

```solidity
event FeePaid(string fnSig, uint256 feeContract, uint256 developer)
```

Emits the fee sent to the Fee Contract and to the developer.

#### Parameters

| Name        | Type    | Description                                               |
| ----------- | ------- | --------------------------------------------------------- |
| fnSig       | string  | The function signature against which the fee was applied. |
| feeContract | uint256 | The fee sent to the Fee Contract.                         |
| developer   | uint256 | The fee sent to the developer.                            |

### FeeProposed

```solidity
event FeeProposed(string fnSig, uint256 fee)
```

Emits the function signature of for which the fee is proposed
and the associated fee.

#### Parameters

| Name  | Type    | Description                                           |
| ----- | ------- | ----------------------------------------------------- |
| fnSig | string  | The function signature for which the fee is proposed. |
| fee   | uint256 | The proposed fee.                                     |

### FeeSet

```solidity
event FeeSet(string fnSig, uint256 fee)
```

Emits the function signature of for which the fee is set and the
associated fee.

#### Parameters

| Name  | Type    | Description                                      |
| ----- | ------- | ------------------------------------------------ |
| fnSig | string  | The function signature for which the fee is set. |
| fee   | uint256 | The set fee.                                     |

### FeeRejected

```solidity
event FeeRejected(string fnSig, uint256 fee)
```

Emits the function signature of for which the fee is rejected and
the associated fee.

#### Parameters

| Name  | Type    | Description                                           |
| ----- | ------- | ----------------------------------------------------- |
| fnSig | string  | The function signature for which the fee is rejected. |
| fee   | uint256 | The rejected fee.                                     |

### AdminRemovedFee

```solidity
event AdminRemovedFee(bytes4 fnSelector, uint256 fee)
```

Emits the function selector for which the admin removed a fee.

#### Parameters

| Name       | Type    | Description                                          |
| ---------- | ------- | ---------------------------------------------------- |
| fnSelector | bytes4  | The function selector for which the fee was removed. |
| fee        | uint256 | The fee that was removed.                            |

### FeeContractAddressUpdated

```solidity
event FeeContractAddressUpdated(address feeContract)
```

Emits the address of the new FeeContract.

#### Parameters

| Name        | Type    | Description                         |
| ----------- | ------- | ----------------------------------- |
| feeContract | address | The address of the new FeeContract. |

### AssociationAddressUpdated

```solidity
event AssociationAddressUpdated(address association)
```

Emits the address of the new Association.

#### Parameters

| Name        | Type    | Description                         |
| ----------- | ------- | ----------------------------------- |
| association | address | The address of the new Association. |

### DeveloperAddressUpdated

```solidity
event DeveloperAddressUpdated(address developer)
```

Emits the address of the new developer.

#### Parameters

| Name      | Type    | Description                       |
| --------- | ------- | --------------------------------- |
| developer | address | The address of the new developer. |

### DevFeeCollectorUpdated

```solidity
event DevFeeCollectorUpdated(address devFeeCollector)
```

Emits the address of the new dev fee collector.

#### Parameters

| Name            | Type    | Description                               |
| --------------- | ------- | ----------------------------------------- |
| devFeeCollector | address | The address of the new dev fee collector. |

### DevFeeCollectorUpdatedAdmin

```solidity
event DevFeeCollectorUpdatedAdmin(address devFeeCollector)
```

Emits the address of the new dev fee collector.

#### Parameters

| Name            | Type    | Description                           |
| --------------- | ------- | ------------------------------------- |
| devFeeCollector | address | The address of the new fee collector. |

### developerFee

```solidity
modifier developerFee(bool payableFunction, bool refundRemainingBalance)
```

This modifier handles the payment of the developer fee.
It should be used in functions that need to pay the fee.

_Checks if fee is not only sent via msg.value, but also available as
balance in the contract to correctly return underfunded multicalls via
delegatecall._

-   May revert with `H1Developed__InsufficientFunds`.
-   May emit a `FeePaid` event.

#### Parameters

| Name                   | Type | Description                                                                                                   |
| ---------------------- | ---- | ------------------------------------------------------------------------------------------------------------- |
| payableFunction        | bool | If true, the function using this modifier is by default payable and `msg.value` should be reduced by the fee. |
| refundRemainingBalance | bool | Whether the remaining balance after the function execution should be refunded to the sender.                  |

### \_\_H1DevelopedApplication_init

```solidity
function __H1DevelopedApplication_init(address feeContract_, address association_, address developer_, address devFeeCollector_, string[] fnSigs_, uint256[] fnFees_) internal
```

Initializes the `H1DevelopedApplication` contract.

_If the length of the `fnSignatures` and `fnFees` do not match, the
deployment will fail. They can be of length zero (0) if you do not wish
to immediately set any specific fees._

-   May revert with `H1Developed__InvalidAddress`.
-   May revert with `H1Developed__ArrayLengthMismatch`.

#### Parameters

| Name              | Type      | Description                                                            |
| ----------------- | --------- | ---------------------------------------------------------------------- |
| feeContract\_     | address   | The address of the `FeeContract`.                                      |
| association\_     | address   | The address of the Haven1 Association.                                 |
| developer\_       | address   | The address of the contract's developer.                               |
| devFeeCollector\_ | address   | The address of the fee collector.                                      |
| fnSigs\_          | string[]  | An array of function signatures for which specific fees will be set.   |
| fnFees\_          | uint256[] | An array of fees that will be set for their `fnSelector` counterparts. |

### \_\_H1DevelopedApplication_init_unchained

```solidity
function __H1DevelopedApplication_init_unchained(address feeContract_, address association_, address developer_, address devFeeCollector_, string[] fnSigs_, uint256[] fnFees_) internal
```

_see {H1DevelopedApplication-\_\_H1DevelopedApplication_init}_

### getFnFeeAdj

```solidity
function getFnFeeAdj(bytes4 fnSelector) public view returns (uint256)
```

Returns the adjusted fee in H1 tokens, if any, associated with
the given function selector.
If the fee is less than the minimum possible fee, the minimum fee will be
returned.
If the fee is greater than the maximum possible fee, the maximum fee will
be returned.

_Example usage: `getFnFee("0xa9059cbb")`._

#### Parameters

| Name       | Type   | Description                                                  |
| ---------- | ------ | ------------------------------------------------------------ |
| fnSelector | bytes4 | The function selector for which the fee should be retrieved. |

#### Return Values

| Name | Type    | Description                                                   |
| ---- | ------- | ------------------------------------------------------------- |
| [0]  | uint256 | The fee, if any, associated with the given function selector. |

### getFnSelector

```solidity
function getFnSelector(string fnSignature) public pure returns (bytes4)
```

Returns the function selector for a given function signature.

_Example usage: `transfer(address,uint256)`_

#### Parameters

| Name        | Type   | Description                    |
| ----------- | ------ | ------------------------------ |
| fnSignature | string | The signature of the function. |

#### Return Values

| Name | Type   | Description                                             |
| ---- | ------ | ------------------------------------------------------- |
| [0]  | bytes4 | The function selector for the given function signature. |

### proposeFee

```solidity
function proposeFee(string fnSig, uint256 fee) external
```

Proposes a new fee for a given function. To propose multiple fees
at once, see {H1DevelopedApplication-proposeFees}.

_Note that a function's signature is different from its selector.
Function Signature Example: `transfer(address,uint256)`._

_Only callable by an account with the role: `DEV_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `H1Developed__InvalidFeeAmount`.
-   May emit a `FeeProposed` event.

#### Parameters

| Name  | Type    | Description                                                |
| ----- | ------- | ---------------------------------------------------------- |
| fnSig | string  | The signature of the function for which a fee is proposed. |
| fee   | uint256 | The proposed fee.                                          |

### proposeFees

```solidity
function proposeFees(string[] fnSigs, uint256[] fnFees) external
```

Proposes fees for a list of functions.

_Note that a function's signature is different from its selector.
Function Signature Example: `transfer(address,uint256)`_

_Only callable by an account with the role: `DEV_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `H1Developed__InvalidFeeAmount`.
-   May revert with `H1Developed__ArrayLengthMismatch`.
-   May revert with `H1Developed__ArrayLengthZero`.
-   May emit multiple `FeeProposed` events.

#### Parameters

| Name   | Type      | Description                                                  |
| ------ | --------- | ------------------------------------------------------------ |
| fnSigs | string[]  | The list of function signatures for which fees are proposed. |
| fnFees | uint256[] | The list of proposed fees.                                   |

### approveFee

```solidity
function approveFee(uint256 index) external
```

Approves the proposed fee at the given index.

_Removes the approved fee out of the `_feeProposals` list._

_Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `H1Developed__ArrayLengthMismatch`.
-   May revert with `H1Developed__IndexOutOfBounds`.
-   May emit a `FeeSet` event.

#### Parameters

| Name  | Type    | Description                                                    |
| ----- | ------- | -------------------------------------------------------------- |
| index | uint256 | The index of the fee to approve from the `_feeProposals` list. |

### approveAllFees

```solidity
function approveAllFees() external
```

Approves all currently proposed fees.

_Resets the `_feeProposals` list._

_Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `H1Developed__ArrayLengthZero`.
-   May emit multiple `FeeSet` events.

### rejectFee

```solidity
function rejectFee(uint256 index) external
```

Rejects the proposed fee at the given index.

_Removes the rejected fee out of the `_feeProposals` list._

_Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with: `H1Developed__ArrayLengthZero`.
-   May revert with: `H1Developed__IndexOutOfBounds`.
-   May emit a `FeeRejected` event.

#### Parameters

| Name  | Type    | Description                                                   |
| ----- | ------- | ------------------------------------------------------------- |
| index | uint256 | The index of the fee to reject from the `_feeProposals` list. |

### rejectAllFees

```solidity
function rejectAllFees() external
```

Rejects all currently proposed fees.

_Resets the `_feeProposals` list._

_Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit multiple `FeeRejected` events.

### reviewFees

```solidity
function reviewFees(bool[] approvals) external
```

Allows for the approval / rejection of fees in the
`_feeProposals` list.

_Resets the `_feeProposals` list._

_Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with: `H1Developed__ArrayLengthZero`.
-   May revert with: `H1Developed__ArrayLengthMismatch`.
-   May emit multiple `FeeSet` events.
-   May emit multiple `FeeRejected` events.

#### Parameters

| Name      | Type   | Description                                                                                                                     |
| --------- | ------ | ------------------------------------------------------------------------------------------------------------------------------- |
| approvals | bool[] | A list of booleans that indicate whether a given fee at the corresponding index in the `_feeProposals` list should be approved. |

### removeFeeAdmin

```solidity
function removeFeeAdmin(bytes4 fnSelector) external
```

Allows the admin account to remove a fee.

_Only callable by an account with the role `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
-   May emit an `AdminRemovedFee` event.

#### Parameters

| Name       | Type   | Description                                         |
| ---------- | ------ | --------------------------------------------------- |
| fnSelector | bytes4 | The function selector for which the fee is removed. |

### setFeeContract

```solidity
function setFeeContract(address feeContract_) external
```

Updates the `_feeContract` address.

_Only callable by an account with the role `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
-   May emit a `Association` event.

#### Parameters

| Name          | Type    | Description                  |
| ------------- | ------- | ---------------------------- |
| feeContract\_ | address | The new FeeContract address. |

### setAssociation

```solidity
function setAssociation(address association_) external
```

Updates the `_association` address.

_Only callable by an account with the role `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
-   May emit a `AssociationAddressUpdated` event.

#### Parameters

| Name          | Type    | Description                  |
| ------------- | ------- | ---------------------------- |
| association\_ | address | The new Association address. |

### setDeveloper

```solidity
function setDeveloper(address developer_) external
```

Updates the `_developer` address.

_Only callable by an account with the role `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
-   May emit a `DeveloperAddressUpdated` event.

#### Parameters

| Name        | Type    | Description                |
| ----------- | ------- | -------------------------- |
| developer\_ | address | The new developer address. |

### setDevFeeCollector

```solidity
function setDevFeeCollector(address devFeeCollector_) external
```

Updates the `_devFeeCollector` address.

_Only callable by an account with the role `DEV_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$
-   May emit a `FeeCollectorUpdated` event.

#### Parameters

| Name              | Type    | Description                    |
| ----------------- | ------- | ------------------------------ |
| devFeeCollector\_ | address | The new fee collector address. |

### setDevFeeCollectorAdmin

```solidity
function setDevFeeCollectorAdmin(address devFeeCollector_) external
```

Updates the `_devFeeCollector` address.

_Only callable by an account with the role `DEFAULT_ADMIN_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
-   May emit a `FeeCollectorUpdatedAdmin` event.

#### Parameters

| Name              | Type    | Description                    |
| ----------------- | ------- | ------------------------------ |
| devFeeCollector\_ | address | The new fee collector address. |

### proposedFees

```solidity
function proposedFees() external view returns (struct FeeProposalFormatted[])
```

Returns a list of the currently proposed fees and their function
signature.

#### Return Values

| Name | Type                          | Description                                                         |
| ---- | ----------------------------- | ------------------------------------------------------------------- |
| [0]  | struct FeeProposalFormatted[] | A list of the currently proposed fees and their function signature. |

### feeContract

```solidity
function feeContract() external view returns (address)
```

Returns the address of the `FeeContract`.

#### Return Values

| Name | Type    | Description                       |
| ---- | ------- | --------------------------------- |
| [0]  | address | The address of the `FeeContract`. |

### association

```solidity
function association() external view returns (address)
```

Returns the address of the `Association`.

#### Return Values

| Name | Type    | Description                       |
| ---- | ------- | --------------------------------- |
| [0]  | address | The address of the `Association`. |

### developer

```solidity
function developer() external view returns (address)
```

Returns the address of the `developer`.

#### Return Values

| Name | Type    | Description                     |
| ---- | ------- | ------------------------------- |
| [0]  | address | The address of the `developer`. |

### devFeeCollector

```solidity
function devFeeCollector() external view returns (address)
```

Returns the address of the `_devFeeCollector`.

#### Return Values

| Name | Type    | Description                            |
| ---- | ------- | -------------------------------------- |
| [0]  | address | The address of the `_devFeeCollector`. |

### getFnFeeUSD

```solidity
function getFnFeeUSD(bytes4 fnSelector) public view returns (uint256)
```

Returns the unadjusted USD fee, if any, associated with the given
function selector.

_Example usage: `getFnFee("0xa9059cbb")`_

#### Parameters

| Name       | Type   | Description                                                  |
| ---------- | ------ | ------------------------------------------------------------ |
| fnSelector | bytes4 | The function selector for which the fee should be retrieved. |

#### Return Values

| Name | Type    | Description                                                   |
| ---- | ------- | ------------------------------------------------------------- |
| [0]  | uint256 | The fee, if any, associated with the given function selector. |

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Overrides OpenZeppelin `_authorizeUpgrade` in order to ensure only the
admin role can upgrade the contracts._

### msgValueAfterFee

```solidity
function msgValueAfterFee() internal view returns (uint256)
```

Returns the current `msg.value` after the developer fee has been
subtracted.

_To be used in place of `msg.value` in functions that take a
developer fee._

#### Return Values

| Name | Type    | Description                                                 |
| ---- | ------- | ----------------------------------------------------------- |
| [0]  | uint256 | The `msg.value` after the developer fee has been subtraced. |
