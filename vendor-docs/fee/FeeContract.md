# Solidity API

## FeeContract

This contract collects and distributes application fees from user
application transactions.

_The primary function of this contract is to ensure
proper distribution of fees from Haven1 applications to distribution
channels._

### OPERATOR_ROLE

```solidity
bytes32 OPERATOR_ROLE
```

The role to control the contract.

### distributionEpoch

```solidity
uint256 distributionEpoch
```

Stores the time frame that must be waited before distributing
fees to channels.

### feeUpdateEpoch

```solidity
uint256 feeUpdateEpoch
```

Stores the time frame that must be waited before updating the
fees amount.

### \_channels

```solidity
address[] _channels
```

_Addresses used for fee distribution.
`_channels[i]` corresponds to `_weights[i]`._

### \_weights

```solidity
uint256[] _weights
```

_Weights for distribution amounts.
`_weights[i]` corresponds to `_channels[i]`._

### FeesReceived

```solidity
event FeesReceived(address from, address txOrigin, uint256 amount)
```

Emits the address sending the funds and amount paid.

#### Parameters

| Name     | Type    | Description                    |
| -------- | ------- | ------------------------------ |
| from     | address | The source account.            |
| txOrigin | address | The origin of the transaction. |
| amount   | uint256 | The amount of fees received.   |

### FeesDistributed

```solidity
event FeesDistributed(address to, uint256 amount)
```

Emits the address receiving the fee, and the fee amount.

#### Parameters

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| to     | address | The destination account.        |
| amount | uint256 | The amount of fees distributed. |

### FeeUpdated

```solidity
event FeeUpdated(uint256 newFee)
```

Emits the new fee amount.

#### Parameters

| Name   | Type    | Description         |
| ------ | ------- | ------------------- |
| newFee | uint256 | The new fee amount. |

### ChannelAdded

```solidity
event ChannelAdded(address newChannelAddress, uint256 channelWeight, uint256 contractShares)
```

Emits the address, shares, and total shares of the contract.

#### Parameters

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| newChannelAddress | address | The address of the new channel.   |
| channelWeight     | uint256 | The weight of the new channel.    |
| contractShares    | uint256 | The total shares of the contract. |

### ChannelAdjusted

```solidity
event ChannelAdjusted(address adjustedChannel, uint256 newChannelWeight, uint256 currentContractShares)
```

Emits address of the adjusted channel, the new channel weight and
current share amount.

#### Parameters

| Name                  | Type    | Description                          |
| --------------------- | ------- | ------------------------------------ |
| adjustedChannel       | address | The address of the adjusted channel. |
| newChannelWeight      | uint256 | The address of the adjusted channel. |
| currentContractShares | uint256 | The current contract shares.         |

### ChannelRemoved

```solidity
event ChannelRemoved(address channelRemoved, uint256 newTotalSharesAmount)
```

Emits the address that was removed and the new total shares amount.

#### Parameters

| Name                 | Type    | Description                   |
| -------------------- | ------- | ----------------------------- |
| channelRemoved       | address | The channel that was removed. |
| newTotalSharesAmount | uint256 | The channel that was removed. |

### MinFeeUpdated

```solidity
event MinFeeUpdated(uint256 newFee)
```

Emits the new minimum fee.

#### Parameters

| Name   | Type    | Description               |
| ------ | ------- | ------------------------- |
| newFee | uint256 | The new minimum multiple. |

### MaxFeeUpdated

```solidity
event MaxFeeUpdated(uint256 newFee)
```

Emits the new maximum fee.

#### Parameters

| Name   | Type    | Description               |
| ------ | ------- | ------------------------- |
| newFee | uint256 | The new maximum multiple. |

### OracleUpdated

```solidity
event OracleUpdated(address oracleAddress)
```

Emits the new oracle address.

#### Parameters

| Name          | Type    | Description             |
| ------------- | ------- | ----------------------- |
| oracleAddress | address | The new oracle address. |

### FeeEpochUpdated

```solidity
event FeeEpochUpdated(uint256 epoch)
```

Emits the new epoch length.

#### Parameters

| Name  | Type    | Description           |
| ----- | ------- | --------------------- |
| epoch | uint256 | The new epoch length. |

### DistributionEpochUpdated

```solidity
event DistributionEpochUpdated(uint256 epoch)
```

Emits the new epoch length.

#### Parameters

| Name  | Type    | Description           |
| ----- | ------- | --------------------- |
| epoch | uint256 | The new epoch length. |

### FeeContract\_\_TransferFailed

```solidity
error FeeContract__TransferFailed()
```

_Error to inform users that funds have failed to transfer._

### FeeContract\_\_EpochLengthNotYetMet

```solidity
error FeeContract__EpochLengthNotYetMet()
```

_Error to inform users that the min duration before a fee
distribution can occur has not yet been met._

### FeeContract\_\_InvalidAddress

```solidity
error FeeContract__InvalidAddress(address account)
```

_Error to inform users an invalid address has been passed to the
function._

#### Parameters

| Name    | Type    | Description                        |
| ------- | ------- | ---------------------------------- |
| account | address | The invalid address that was used. |

### FeeContract\_\_InvalidWeight

```solidity
error FeeContract__InvalidWeight(uint256 weight)
```

_Error to inform users an invalid weight has been passed to the
function._

#### Parameters

| Name   | Type    | Description         |
| ------ | ------- | ------------------- |
| weight | uint256 | The invalid weight. |

### FeeContract\_\_ChannelLimitReached

```solidity
error FeeContract__ChannelLimitReached()
```

_Error to inform users that no more addresses can be added to the
channels array._

### FeeContract\_\_ChannelWeightMisalignment

```solidity
error FeeContract__ChannelWeightMisalignment()
```

_Error to inform users an invalid address has been passed to the
function._

### FeeContract\_\_ChannelNotFound

```solidity
error FeeContract__ChannelNotFound(address channel)
```

_Error to inform users that the requested channel was not found._

#### Parameters

| Name    | Type    | Description                                                  |
| ------- | ------- | ------------------------------------------------------------ |
| channel | address | The address of the channel that was requested but not found. |

### FeeContract\_\_FeeUpdateFailed

```solidity
error FeeContract__FeeUpdateFailed()
```

_Error to inform users a request to update the fee failed._

### FeeContract\_\_InvalidFee

```solidity
error FeeContract__InvalidFee()
```

_Error to inform users that the fee is invalid._

### constructor

```solidity
constructor() public
```

### receive

```solidity
receive() external payable
```

Gives the contract the ability to receive H1 from external
addresses.

_`msg.data` must be empty.
May emit a `FeesReceived` event._

### initialize

```solidity
function initialize(address oracle, address[] channels, uint256[] weights, address haven1Association, address networkOperator, address deployer, uint256 minDevFee, uint256 maxDevFee, uint256 asscShare, uint256 gracePeriod) external
```

Initializes variables during deployment.

_There cannot be more than ten channels.
Each channel must have a matching weight explicitly supplied._

#### Parameters

| Name              | Type      | Description                                             |
| ----------------- | --------- | ------------------------------------------------------- |
| oracle            | address   | The address for the fee oracle.                         |
| channels          | address[] | The channels that receive payments.                     |
| weights           | uint256[] | The amount of shares each channel receives.             |
| haven1Association | address   | The address that can add or revoke privileges.          |
| networkOperator   | address   | The address that calls restricted functions.            |
| deployer          | address   | The address responsible for deploying the contract.     |
| minDevFee         | uint256   | The min multiple on network fee allowed for devs.       |
| maxDevFee         | uint256   | The max multiple on network fee allowed for devs.       |
| asscShare         | uint256   | The share of the dev fee the Association is to receive. |
| gracePeriod       | uint256   | The grace period, in seconds.                           |

### addChannel

```solidity
function addChannel(address _newChannelAddress, uint256 _weight) external
```

Adds a new channel with a given weight.

_We allow 10 channels to ensure distribution can be managed. This
function ensures that there are no duplicate addresses or zero addresses._

_The total weight is tracked by `CONTRACT_SHARES` which we use to divide
each address's shares by then send the correct amounts to each channel._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit a `ChannelAdded` event.

#### Parameters

| Name                | Type    | Description                     |
| ------------------- | ------- | ------------------------------- |
| \_newChannelAddress | address | The new channel to add.         |
| \_weight            | uint256 | The weight for the new channel. |

### adjustChannel

```solidity
function adjustChannel(address _oldChannelAddress, address _newChannelAddress, uint256 _newWeight) external
```

Adjusts a channel and its weight.

_The sum of all the channel's weights is tracked by `CONTRACT_SHARES`
which we adjust here by subtracting the old weight number and adding the
new one._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `FeeContract__ChannelNotFound`.
-   May emit a `ChannelAdjusted` event.

#### Parameters

| Name                | Type    | Description                                              |
| ------------------- | ------- | -------------------------------------------------------- |
| \_oldChannelAddress | address | The address of the channel to update.                    |
| \_newChannelAddress | address | The address of the channel that replaces the old one.    |
| \_newWeight         | uint256 | The amount of total shares the new address will receive. |

### removeChannel

```solidity
function removeChannel(address _channel) external
```

Removes a channel and it's weight.

_The total weight is tracked by `CONTRACT_SHARES`.
which we subtract the value from in the middle of this function._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `FeeContract__ChannelNotFound`.
-   May emit a `ChannelRemoved` event.

#### Parameters

| Name      | Type    | Description                |
| --------- | ------- | -------------------------- |
| \_channel | address | The address being removed. |

### distributeFees

```solidity
function distributeFees() external
```

Distributes fees to channels.

_This function can be called when enough time has passed since the
last distribution.
The balance of the contract is distributed to channels._

-   May revert with `FeeContract__EpochLengthNotYetMet`.
-   May emit a `FeesDistributed` event.

### forceDistributeFees

```solidity
function forceDistributeFees() external
```

Forces a fee distribution.

_Can only be called by an operator. To be used in case the funds
need to be distributed immediately._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit a `FeesDistributed` event.

### setMinFee

```solidity
function setMinFee(uint256 fee) external
```

Sets the minimum fee for developer applications. **Must** be to a precision of 18 decimals.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit a `MinFeeUpdated` event.

#### Parameters

| Name | Type    | Description                                           |
| ---- | ------- | ----------------------------------------------------- |
| fee  | uint256 | The minimum fee, in USD, that a developer may charge. |

### setMaxFee

```solidity
function setMaxFee(uint256 fee) external
```

Sets the maximum fee for developer applications. **Must** be to a
precision of 18 decimals.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit a `MaxFeeUpdated` event.

#### Parameters

| Name | Type    | Description                                           |
| ---- | ------- | ----------------------------------------------------- |
| fee  | uint256 | The highest fee, in USD, that a developer may charge. |

### setOracle

```solidity
function setOracle(address newOracle) external
```

Sets the oracle address.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `FeeContract__InvalidAddress`.
-   May emit an `OracleUpdated` event.

#### Parameters

| Name      | Type    | Description             |
| --------- | ------- | ----------------------- |
| newOracle | address | The new oracle address. |

### setGracePeriod

```solidity
function setGracePeriod(uint256 gracePeriod) external
```

Adjust the grace period as an admin.

#### Parameters

| Name        | Type    | Description           |
| ----------- | ------- | --------------------- |
| gracePeriod | uint256 | The new grace period. |

### setGraceContract

```solidity
function setGraceContract(bool enterGrace) external
```

Sets or removes the `msg.sender` as a grace contract.

#### Parameters

| Name       | Type | Description                                          |
| ---------- | ---- | ---------------------------------------------------- |
| enterGrace | bool | Whether to set the `msg.sender` as a grace contract. |

### setFeeUSD

```solidity
function setFeeUSD(uint256 feeUSD_) external
```

Updates the `_feeUSD` value.

Example:

-   1.75 USD: `1750000000000000000`
-   1.00 USD: `1000000000000000000`
-   0.50 USD: `500000000000000000`

May revert with:
/^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/\

#### Parameters

| Name     | Type    | Description                                                     |
| -------- | ------- | --------------------------------------------------------------- |
| feeUSD\_ | uint256 | The new fee, in USD. **Must** be to a precision of 18 decimals. |

### setAsscShare

```solidity
function setAsscShare(uint256 asscShare_) external
```

Updates the `_asscShare` value.

Example:

-   10%: `100000000000000000`
-   15%: `150000000000000000`

May revert with:
/^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/\

#### Parameters

| Name        | Type    | Description                                                                                                      |
| ----------- | ------- | ---------------------------------------------------------------------------------------------------------------- |
| asscShare\_ | uint256 | The new share of the developer fee that the Association will receive. **Must** be to a precision of 18 decimals. |

### getFeeUSD

```solidity
function getFeeUSD() external view returns (uint256)
```

Returns the current fee value in USD to a precision of 18
decimals.

#### Return Values

| Name | Type    | Description                                                 |
| ---- | ------- | ----------------------------------------------------------- |
| [0]  | uint256 | The current fee value in USD to a precision of 18 decimals. |

### getAsscShare

```solidity
function getAsscShare() external view returns (uint256)
```

Returns the current share the Association receives of the
developer fee to a precision of 18 decimals.

#### Return Values

| Name | Type    | Description                                                                                    |
| ---- | ------- | ---------------------------------------------------------------------------------------------- |
| [0]  | uint256 | The current share the Association receives of the developer fee to a precision of 18 decimals. |

### setFeeUpdateEpoch

```solidity
function setFeeUpdateEpoch(uint256 newEpochLength) public
```

Adjusts how often the fee value can be updated.

#### Parameters

| Name           | Type    | Description                                                                                                                                                                          |
| -------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| newEpochLength | uint256 | The length of the new time between oracle updates. May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/ May emit a `FeeEpochUpdated` event. |

### setDistributionEpoch

```solidity
function setDistributionEpoch(uint256 newEpochLength) public
```

Adjusts how frequently a fee distribution can occur.

#### Parameters

| Name           | Type    | Description                                                                                                                                                                                  |
| -------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| newEpochLength | uint256 | The new length of time between fee distributions. May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/ May emit a `DistributionEpochUpdated` event. |

### updateFee

```solidity
function updateFee() public
```

Updates the `networkFeeResetTimestamp`, the `_fee`, and the
`_h1USD` values.

_It can be called by anyone. H1Developed or Native applications will
also call the function.
May emit a `FeeUpdated` event._

### nextResetTime

```solidity
function nextResetTime() public view returns (uint256)
```

Returns the `networkFeeResetTimestamp`.

#### Return Values

| Name | Type    | Description              |
| ---- | ------- | ------------------------ |
| [0]  | uint256 | The next fee reset time. |

### amountPaidToUponNextDistribution

```solidity
function amountPaidToUponNextDistribution(uint8 index) public view returns (uint256)
```

Returns the fee amount an address should receive.

#### Parameters

| Name  | Type  | Description                                 |
| ----- | ----- | ------------------------------------------- |
| index | uint8 | The index in the array of channels/weights. |

#### Return Values

| Name | Type    | Description       |
| ---- | ------- | ----------------- |
| [0]  | uint256 | The intended fee. |

### getFee

```solidity
function getFee() public view returns (uint256)
```

Returns the `_fee`.

#### Return Values

| Name | Type    | Description      |
| ---- | ------- | ---------------- |
| [0]  | uint256 | The current fee. |

### getDevH1USD

```solidity
function getDevH1USD() public view returns (uint256)
```

Returns the `_h1USD` value. To be used in H1 Developed
Applications.

#### Return Values

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| [0]  | uint256 | The current `_h1USD` value. |

### getChannels

```solidity
function getChannels() public view returns (address[])
```

Returns all channels.

#### Return Values

| Name | Type      | Description   |
| ---- | --------- | ------------- |
| [0]  | address[] | The channels. |

### getWeights

```solidity
function getWeights() public view returns (uint256[])
```

Return all the weights.

#### Return Values

| Name | Type      | Description  |
| ---- | --------- | ------------ |
| [0]  | uint256[] | The weights. |

### getOracleAddress

```solidity
function getOracleAddress() public view returns (address)
```

Returns the fee oracle address.

#### Return Values

| Name | Type    | Description             |
| ---- | ------- | ----------------------- |
| [0]  | address | The fee oracle address. |

### getChannelWeightByIndex

```solidity
function getChannelWeightByIndex(uint8 index) public view returns (address, uint256)
```

Returns a channel's address and its weight.

#### Parameters

| Name  | Type  | Description                                 |
| ----- | ----- | ------------------------------------------- |
| index | uint8 | The index in the array of channels/weights. |

#### Return Values

| Name | Type    | Description                           |
| ---- | ------- | ------------------------------------- |
| [0]  | address | The channel's address and its weight. |
| [1]  | uint256 |                                       |

### getTotalContractShares

```solidity
function getTotalContractShares() public view returns (uint256)
```

Returns the contract shares.

#### Return Values

| Name | Type    | Description          |
| ---- | ------- | -------------------- |
| [0]  | uint256 | The contract shares. |

### getLastDistribution

```solidity
function getLastDistribution() public view returns (uint256)
```

Returns the block timestamp that the most recent fee distribution occurred.

#### Return Values

| Name | Type    | Description                                        |
| ---- | ------- | -------------------------------------------------- |
| [0]  | uint256 | The timestamp of the most recent fee distribution. |

### getMinDevFee

```solidity
function getMinDevFee() public view returns (uint256)
```

Returns the min fee, in USD, that a developer may charge.

#### Return Values

| Name | Type    | Description                                       |
| ---- | ------- | ------------------------------------------------- |
| [0]  | uint256 | The min fee, in USD, that a developer may charge. |

### getMaxDevFee

```solidity
function getMaxDevFee() public view returns (uint256)
```

Returns the max fee, in USD, that a developer may charge.

#### Return Values

| Name | Type    | Description                                       |
| ---- | ------- | ------------------------------------------------- |
| [0]  | uint256 | The max fee, in USD, that a developer may charge. |

### queryOracle

```solidity
function queryOracle() public view returns (uint256)
```

Returns one (1) USD worth of H1.

#### Return Values

| Name | Type    | Description              |
| ---- | ------- | ------------------------ |
| [0]  | uint256 | One (1) USD worth of H1. |

### \_distributeFees

```solidity
function _distributeFees() internal
```

_Internal helper function that encapsulates the fee distribution logic.
Note that functions calling this function should include a reentrancy
guard.
May emit a `FeesDistributed` event._

### \_refreshOracle

```solidity
function _refreshOracle() internal returns (bool)
```

Refreshes the oracle.

#### Return Values

| Name | Type | Description                         |
| ---- | ---- | ----------------------------------- |
| [0]  | bool | Whether the refresh was successful. |

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

`_authorizeUpgrade` this function is overridden to
protect the contract by only allowing the admin to upgrade it.

#### Parameters

| Name              | Type    | Description                 |
| ----------------- | ------- | --------------------------- |
| newImplementation | address | new implementation address. |

### \_indexOf

```solidity
function _indexOf(address channel) internal view returns (uint8)
```

Returns the index of an address in the `channels` array, if it exists.

_If the address is not found in the `channels` array, this function
will revert with a `ChannelNotFound` error._

#### Parameters

| Name    | Type    | Description                                                           |
| ------- | ------- | --------------------------------------------------------------------- |
| channel | address | The address of the channel for which an index should must be checked. |

#### Return Values

| Name | Type  | Description                     |
| ---- | ----- | ------------------------------- |
| [0]  | uint8 | Returns the index as a `uint8`. |

### \_validateChannelAddress

```solidity
function _validateChannelAddress(address channel) internal view returns (bool)
```

Helper function to validate an address before it is added to
the channels array.

Validates that an address:

1. does not equal the zero address; and
2. is not already in the channels array.

#### Parameters

| Name    | Type    | Description                  |
| ------- | ------- | ---------------------------- |
| channel | address | The address to be validated. |

#### Return Values

| Name | Type | Description                        |
| ---- | ---- | ---------------------------------- |
| [0]  | bool | bool Whether the address is valid. |

### \_getFeeForPayment

```solidity
function _getFeeForPayment() internal view returns (uint256)
```

Returns the current active H1 Native Application fee.

#### Return Values

| Name | Type    | Description                                                                                                         |
| ---- | ------- | ------------------------------------------------------------------------------------------------------------------- |
| [0]  | uint256 | the current or prior fee, depending on which is lower while in grace period. Else, the normal fee will be returned. |

### \_getDevH1USD

```solidity
function _getDevH1USD() internal view returns (uint256)
```

Returns the current period's value of one (1) USD worth of H1.

#### Return Values

| Name | Type    | Description                                                                                                             |
| ---- | ------- | ----------------------------------------------------------------------------------------------------------------------- |
| [0]  | uint256 | the current or prior value, depending on which is lower while in grace period. Else, the normal value will be returned. |

### \_validateWeight

```solidity
function _validateWeight(uint256 weight) internal pure returns (bool)
```

Helper function to check whether a weight is non-zero.

_For a weight to be considered valid it must be greater than 0._

#### Parameters

| Name   | Type    | Description          |
| ------ | ------- | -------------------- |
| weight | uint256 | The weight to check. |

#### Return Values

| Name | Type | Description                                   |
| ---- | ---- | --------------------------------------------- |
| [0]  | bool | True is the weight is valid, false otherwise. |

### \_canDistribute

```solidity
function _canDistribute() internal view returns (bool)
```

Returns whether a fee distribution can occur.

#### Return Values

| Name | Type | Description                          |
| ---- | ---- | ------------------------------------ |
| [0]  | bool | Wether a fee distribution can occur. |
