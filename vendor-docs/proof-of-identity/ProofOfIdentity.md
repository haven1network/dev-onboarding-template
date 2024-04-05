# Solidity API

## ProofOfIdentity

Currently tracked attributes, their ID and types:

| ID  | Attribute         | Type    | Example Return |
| --- | ----------------- | ------- | -------------- |
| 0   | primaryID         | bool    | true           |
| 1   | countryCode       | string  | "sg"           |
| 2   | proofOfLiveliness | bool    | true           |
| 3   | userType          | uint256 | 1              |
| 4   | competencyRating  | uint256 | 88             |

Each attribute will also have a corresponding `expiry` and an `updatedAt`
field.

The following fields are guaranteed to have a non-zero entry for users who
successfully completed their identity check:

-   primaryID;
-   countryCode;
-   proofOfLiveliness; and
-   userType.

There are explicit getters for all five (5) of the currently supported
attributes.

Note that while this contract is upgradable, provisions have been made to
allow attributes to be added without the need for upgrading. An event will be
emitted (`AttributeAdded`) if an attribute is added. If an attribute is added
but the contract has not been upgraded to provide a new explicit getter,
you can use one of the four (4) generic getters to retrieve the information.

### OPERATOR_ROLE

```solidity
bytes32 OPERATOR_ROLE
```

_The operator role._

### \_attributes

```solidity
mapping(address => mapping(uint256 => struct Attribute)) _attributes
```

_Maps an address to an "attribute id" to an `Attribute`._

### \_attributeToName

```solidity
mapping(uint256 => string) _attributeToName
```

_Maps the ID of an attribute to its name._

### \_attributeToType

```solidity
mapping(uint256 => enum SupportedAttributeType) _attributeToType
```

_Maps the ID of an attribute to its expected type.
E.g., 0 (primaryID) => "SupportedAttributeType.BOOL"
For the string name of these types see:_

### \_tokenURI

```solidity
mapping(uint256 => string) _tokenURI
```

_Maps a tokenID to a custom URI._

### \_addressToTokenID

```solidity
mapping(address => uint256) _addressToTokenID
```

_Mapping owner addresses to their token ID.
The compliment storage of {ERC721Upgradeable-\_owners}_

### AttributeSet

```solidity
event AttributeSet(address account, uint256 attribute)
```

Emits the address for which an attribute was set and the
attribute's ID.

#### Parameters

| Name      | Type    | Description                                  |
| --------- | ------- | -------------------------------------------- |
| account   | address | The address for which the attribute was set. |
| attribute | uint256 | The ID of the attribute that was set.        |

### AttributeAdded

```solidity
event AttributeAdded(uint256 id, string name)
```

Emits the ID of the newly added attribute and its name.

#### Parameters

| Name | Type    | Description                          |
| ---- | ------- | ------------------------------------ |
| id   | uint256 | The ID of the newly added attribute. |
| name | string  | The attribute's name.                |

### IdentityIssued

```solidity
event IdentityIssued(address account, uint256 tokenID)
```

Emits the address for which an idenity was issued and the ID
of the NFT.

#### Parameters

| Name    | Type    | Description                           |
| ------- | ------- | ------------------------------------- |
| account | address | The account that received the ID NFT. |
| tokenID | uint256 | The token ID that was issued.         |

### TokenURIUpdated

```solidity
event TokenURIUpdated(address account, uint256 tokenID, string uri)
```

Emits the address of the account for which the token URI was
updated, the token ID and the new URI.

#### Parameters

| Name    | Type    | Description                                |
| ------- | ------- | ------------------------------------------ |
| account | address | The account for which the URI was updated. |
| tokenID | uint256 | The ID of the associated token.            |
| uri     | string  | The new URI.                               |

### AccountSuspended

```solidity
event AccountSuspended(address account, string reason)
```

Emits the address of the suspended account and the suspension
reason.

#### Parameters

| Name    | Type    | Description                     |
| ------- | ------- | ------------------------------- |
| account | address | The account that was suspended. |
| reason  | string  | The reason for the suspension.  |

### AccountUnsuspended

```solidity
event AccountUnsuspended(address account)
```

Emits the address of the account that was unsuspended.

#### Parameters

| Name    | Type    | Description                       |
| ------- | ------- | --------------------------------- |
| account | address | The account that was unsuspended. |

### ProofOfIdentity\_\_InvalidAttribute

```solidity
error ProofOfIdentity__InvalidAttribute(uint256 attribute)
```

Error to be thrown when an invalid attribute ID has been supplied.

#### Parameters

| Name      | Type    | Description                                 |
| --------- | ------- | ------------------------------------------- |
| attribute | uint256 | The invalid attribute ID that was supplied. |

### ProofOfIdentity\_\_InvalidExpiry

```solidity
error ProofOfIdentity__InvalidExpiry(uint256 expiry)
```

Error to be thrown when an invalid expiry has been supplied.

#### Parameters

| Name   | Type    | Description                                  |
| ------ | ------- | -------------------------------------------- |
| expiry | uint256 | The address of the already verified account. |

### ProofOfIdentity\_\_AlreadyVerified

```solidity
error ProofOfIdentity__AlreadyVerified(address account)
```

Error to be thrown when an attempt to issue an ID to an already
verified account is made.

#### Parameters

| Name    | Type    | Description                                  |
| ------- | ------- | -------------------------------------------- |
| account | address | The address of the already verified account. |

### ProofOfIdentity\_\_IsNotVerified

```solidity
error ProofOfIdentity__IsNotVerified(address account)
```

Error to be thrown when an attempt to access a feature that
requires an account to be verified.

#### Parameters

| Name    | Type    | Description                            |
| ------- | ------- | -------------------------------------- |
| account | address | The address of the unverified account. |

### ProofOfIdentity\_\_IDNotTransferable

```solidity
error ProofOfIdentity__IDNotTransferable()
```

Error to be thrown when an attempt to transfer a Proof of
Identity NFT is made.

### ProofOfIdentity\_\_InvalidTokenID

```solidity
error ProofOfIdentity__InvalidTokenID(uint256 tokenID)
```

Error to be thrown when an invalid token ID has been supplied.

#### Parameters

| Name    | Type    | Description            |
| ------- | ------- | ---------------------- |
| tokenID | uint256 | The supplied token ID. |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address association, address networkOperator, address deployer, address permissionsInterface, address accountManager) external
```

### issueIdentity

```solidity
function issueIdentity(address account, bool primaryID, string countryCode, bool proofOfLiveliness, uint256 userType, uint256[4] expiries, string uri) external
```

Issues a Proof of Identity NFT to the `account`.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `ProofOfIdentity__AlreadyVerified`.
-   May revert with `ProofOfIdentity__InvalidAttribute`.
-   May revert with `ProofOfIdentity__InvalidExpiry`.
-   May emit an `AttributeSet` event.
-   May emit an `IdentityIssued` event.

#### Parameters

| Name              | Type       | Description                                                    |
| ----------------- | ---------- | -------------------------------------------------------------- |
| account           | address    | The address of the account to receive the NFT.                 |
| primaryID         | bool       | Whether the account has verified a primary ID.                 |
| countryCode       | string     | The ISO 3166-1 alpha-2 country code of the account.            |
| proofOfLiveliness | bool       | Whether the account has completed a proof of liveliness check. |
| userType          | uint256    | The account type of the user: 1 = retail. 2 = institution.     |
| expiries          | uint256[4] |                                                                |
| uri               | string     |                                                                |

### setStringAttribute

```solidity
function setStringAttribute(address account, uint256 id, uint256 exp, string data) external
```

Sets an attribute, the value for which is of type `string`.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `ProofOfIdentity__IsNotVerified`.
-   May revert with `ProofOfIdentity__InvalidAttribute`.
-   May revert with `ProofOfIdentity__InvalidExpiry`.
-   May emit an `AttributeSet` event.

#### Parameters

| Name    | Type    | Description                                        |
| ------- | ------- | -------------------------------------------------- |
| account | address | The address for which the attribute should be set. |
| id      | uint256 | The ID of the attribute to set.                    |
| exp     | uint256 | The timestamp of expiry of the attribute.          |
| data    | string  | The attribute data to set as a `string`.           |

### setU256Attribute

```solidity
function setU256Attribute(address account, uint256 id, uint256 exp, uint256 data) external
```

Sets an attribute, the value for which is of type `uint256`.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `ProofOfIdentity__IsNotVerified`.
-   May revert with `ProofOfIdentity__InvalidAttribute`.
-   May revert with `ProofOfIdentity__InvalidExpiry`.
-   May emit an `AttributeSet` event.

#### Parameters

| Name    | Type    | Description                                        |
| ------- | ------- | -------------------------------------------------- |
| account | address | The address for which the attribute should be set. |
| id      | uint256 | The ID of the attribute to set.                    |
| exp     | uint256 | The timestamp of expiry of the attribute.          |
| data    | uint256 | The attribute data to set as `uint256`.            |

### setBoolAttribute

```solidity
function setBoolAttribute(address account, uint256 id, uint256 exp, bool data) external
```

Sets an attribute, the value for which is of type `bool`.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `ProofOfIdentity__IsNotVerified`.
-   May revert with `ProofOfIdentity__InvalidAttribute`.
-   May revert with `ProofOfIdentity__InvalidExpiry`.
-   May emit an `AttributeSet` event.

#### Parameters

| Name    | Type    | Description                                        |
| ------- | ------- | -------------------------------------------------- |
| account | address | The address for which the attribute should be set. |
| id      | uint256 | The ID of the attribute to set.                    |
| exp     | uint256 | The timestamp of expiry of the attribute.          |
| data    | bool    | The attribute data to set as `bool`.               |

### setBytesAttribute

```solidity
function setBytesAttribute(address account, uint256 id, uint256 exp, bytes data) external
```

Sets an attribute, the value for which is of type `bytes`.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May revert with `ProofOfIdentity__IsNotVerified`.
-   May revert with `ProofOfIdentity__InvalidAttribute`.
-   May revert with `ProofOfIdentity__InvalidExpiry`.
-   May emit an `AttributeSet` event.

#### Parameters

| Name    | Type    | Description                                        |
| ------- | ------- | -------------------------------------------------- |
| account | address | The address for which the attribute should be set. |
| id      | uint256 | The ID of the attribute to set.                    |
| exp     | uint256 | The timestamp of expiry of the attribute.          |
| data    | bytes   | The attribute data to set as `bytes`.              |

### setAttributeCount

```solidity
function setAttributeCount(uint256 count) external
```

Sets the attribute count.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/

#### Parameters

| Name  | Type    | Description    |
| ----- | ------- | -------------- |
| count | uint256 | The new count. |

### addAttribute

```solidity
function addAttribute(string name, enum SupportedAttributeType attrType) external
```

Adds an attribute to the contract.

_The current attribute count is used as the next attribute ID, and
is then incremented._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit an `AttributeAdded` event.

#### Parameters

| Name     | Type                        | Description                |
| -------- | --------------------------- | -------------------------- |
| name     | string                      | The attribute's name.      |
| attrType | enum SupportedAttributeType | The type of the attribute. |

### setTokenURI

```solidity
function setTokenURI(address account, uint256 tokenId, string tokenUri) external
```

Updates the URI of a token.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit a `TokenURIUpdated` event.

#### Parameters

| Name     | Type    | Description                                   |
| -------- | ------- | --------------------------------------------- |
| account  | address | the target account of the tokenUri to update. |
| tokenId  | uint256 |                                               |
| tokenUri | string  | the URI data to update for the token Id.      |

### suspendAccount

```solidity
function suspendAccount(address account, string reason) external
```

Suspends an account.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit an `AccountSuspended` event.

#### Parameters

| Name    | Type    | Description                    |
| ------- | ------- | ------------------------------ |
| account | address | The account to suspend.        |
| reason  | string  | The reason for the suspension. |

### unsuspendAccount

```solidity
function unsuspendAccount(address account) external
```

Unsuspends an account.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit an `AccountUnsuspended` event.

#### Parameters

| Name    | Type    | Description               |
| ------- | ------- | ------------------------- |
| account | address | The account to unsuspend. |

### getPrimaryID

```solidity
function getPrimaryID(address account) external view returns (bool, uint256, uint256)
```

Returns a tuple containing whether or not a user has validated
their primary ID, the expiry of the attribute and the last time it was
updated.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                                          |
| ---- | ------- | ---------------------------------------------------- |
| [0]  | bool    | Whether the account's primary ID has been validated. |
| [1]  | uint256 | The expiry of the attribute.                         |
| [2]  | uint256 | The last time the attribute was updated.             |

### getCountryCode

```solidity
function getCountryCode(address account) external view returns (string, uint256, uint256)
```

Returns a tuple containing a user's country code (lowercase), the
expiry of the attribute and the last time it was updated.

_The country code adheres to the ISO 3166-1 alpha-2 standard.
For more information, see:
`https://localizely.com/iso-3166-1-alpha-2-list/#`_

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | string  | The user's country code (lowercase).     |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getProofOfLiveliness

```solidity
function getProofOfLiveliness(address account) external view returns (bool, uint256, uint256)
```

Returns a tuple containing whether a user's proof of liveliness
check has been completed, the expiry of the attribute and the last time
it was updated.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| [0]  | bool    | Whether the user's proof of liveliness check has been completed |
| [1]  | uint256 | The expiry of the attribute.                                    |
| [2]  | uint256 | The last time the attribute was updated.                        |

### getUserType

```solidity
function getUserType(address account) external view returns (uint256, uint256, uint256)
```

Returns a tuple containing a user's account type, the expiry of
the attribute and the last time it was updated.

-   1 = Retail
-   2 = Institution

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | uint256 | The user's account type                  |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getCompetencyRating

```solidity
function getCompetencyRating(address account) external view returns (uint256, uint256, uint256)
```

Returns a tuple containing a user's competency rating, the expiry
of the attribute and the last time it was updated.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | uint256 | The user's competency rating.            |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getStringAttribute

```solidity
function getStringAttribute(uint256 id, address account) external view returns (string, uint256, uint256)
```

Returns a tuple containing the string attribute, the expiry of
the attribute and the last time it was updated. Note that if an invalid ID
is passed in, the call with revert.
If an address for which the attribute has not yet been set is passed in,
the default `("", 0, 0)` case will be returned.

-   May revert with `ProofOfIdentity__InvalidAttribute`.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| id      | uint256 | The attribute ID to fetch.                                     |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | string  | The string attribute.                    |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getU256Attribute

```solidity
function getU256Attribute(uint256 id, address account) external view returns (uint256, uint256, uint256)
```

Returns a tuple containing the uint256 attribute, the expiry of
the attribute and the last time it was updated. Note that if an invalid ID
is passed in, the call with revert.
If an address for which the attribute has not yet been set is passed in,
the default `(0, 0, 0)` case will be returned.

-   May revert with `ProofOfIdentity__InvalidAttribute`.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| id      | uint256 | The attribute ID to fetch.                                     |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | uint256 | The uint256 attribute.                   |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getBoolAttribute

```solidity
function getBoolAttribute(uint256 id, address account) external view returns (bool, uint256, uint256)
```

Returns a tuple containing the bool attribute, the expiry of
the attribute and the last time it was updated. Note that if an invalid ID
is passed in, the call with revert.
If an address for which the attribute has not yet been set is passed in,
the default `(false, 0, 0)` case will be returned.

-   May revert with `ProofOfIdentity__InvalidAttribute`.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| id      | uint256 | The attribute ID to fetch.                                     |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | bool    | The bool attribute.                      |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getBytesAttribute

```solidity
function getBytesAttribute(uint256 id, address account) external view returns (bytes, uint256, uint256)
```

Returns a tuple containing the bytes attribute, the expiry of
the attribute and the last time it was updated. Note that if an invalid ID
is passed in, the call with revert.
If an address for which the attribute has not yet been set is passed in,
the default `("0x", 0, 0)` case will be returned.

-   May revert with `ProofOfIdentity__InvalidAttribute`.

#### Parameters

| Name    | Type    | Description                                                    |
| ------- | ------- | -------------------------------------------------------------- |
| id      | uint256 | The attribute ID to fetch.                                     |
| account | address | The address of the account for which the attribute is fetched. |

#### Return Values

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| [0]  | bytes   | The bytes attribute.                     |
| [1]  | uint256 | The expiry of the attribute.             |
| [2]  | uint256 | The last time the attribute was updated. |

### getAttributeName

```solidity
function getAttributeName(uint256 id) external view returns (string)
```

Helper function that returns an attribute's name. Note that
it will return an empty string (`""`) if the attribute ID provided is
invalid.

#### Parameters

| Name | Type    | Description                                            |
| ---- | ------- | ------------------------------------------------------ |
| id   | uint256 | The ID of the attribute for which the name is fetched. |

#### Return Values

| Name | Type   | Description                |
| ---- | ------ | -------------------------- |
| [0]  | string | The name of the attribute. |

### isSuspended

```solidity
function isSuspended(address account) external view returns (bool)
```

Returns if a given account is suspended.

#### Parameters

| Name    | Type    | Description            |
| ------- | ------- | ---------------------- |
| account | address | The account the check. |

#### Return Values

| Name | Type | Description                         |
| ---- | ---- | ----------------------------------- |
| [0]  | bool | True if suspended, false otherwise. |

### tokenID

```solidity
function tokenID(address account) external view returns (uint256)
```

Returns an account's token ID.

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| account | address | The address for which the token ID should be retrieved. |

#### Return Values

| Name | Type    | Description   |
| ---- | ------- | ------------- |
| [0]  | uint256 | The token ID. |

### tokenIDCounter

```solidity
function tokenIDCounter() external view returns (uint256)
```

Returns the current token ID counter value.

#### Return Values

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| [0]  | uint256 | The token ID counter value. |

### attributeCount

```solidity
function attributeCount() external view returns (uint256)
```

Returns amount of attributes currently tracked by the contract.

_Note that the attribute IDs are zero-indexed, so the max valid ID
is `attributeCount() - 1;`_

#### Return Values

| Name | Type    | Description                                                 |
| ---- | ------- | ----------------------------------------------------------- |
| [0]  | uint256 | The amount of attributes currently tracked by the contract. |

### setAttributeName

```solidity
function setAttributeName(uint256 id, string name) public
```

Sets the name of an ID.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/

#### Parameters

| Name | Type    | Description                                              |
| ---- | ------- | -------------------------------------------------------- |
| id   | uint256 | The ID of the attribute for which the name is to be set. |
| name | string  | The name to set.                                         |

### setAttributeType

```solidity
function setAttributeType(uint256 id, enum SupportedAttributeType attrType) public
```

Sets the type of the attribute.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/

#### Parameters

| Name     | Type                        | Description                                              |
| -------- | --------------------------- | -------------------------------------------------------- |
| id       | uint256                     | The ID of the attribute for which the type is to be set. |
| attrType | enum SupportedAttributeType | The type of the attribute                                |

### incrementAttributeCount

```solidity
function incrementAttributeCount() public
```

Increments the attribute count.

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/

### getAttributeType

```solidity
function getAttributeType(uint256 id) public view returns (string)
```

Helper function that returns an attribute's type.
E.g., 0 (primaryID) => "bool"
E.g., 1 (countryCode) => "string"

-   May revert with `ProofOfIdentity__InvalidAttribute`.

#### Parameters

| Name | Type    | Description                                            |
| ---- | ------- | ------------------------------------------------------ |
| id   | uint256 | The ID of the attribute for which the type is fetched. |

#### Return Values

| Name | Type   | Description                |
| ---- | ------ | -------------------------- |
| [0]  | string | The type of the attribute. |

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view virtual returns (string)
```

Returns the URI for a given token ID.

-   May revert with `ProofOfIdentity__InvalidTokenID`.

#### Parameters

| Name    | Type    | Description                                 |
| ------- | ------- | ------------------------------------------- |
| tokenId | uint256 | token ID for which a URI should be fetched. |

#### Return Values

| Name | Type   | Description    |
| ---- | ------ | -------------- |
| [0]  | string | The token URI. |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

_Overrides OpenZeppelin's `supportsInterface` implementation to
ensure the same interfaces can support access control and ERC721._

### \_setAttr

```solidity
function _setAttr(address account, uint256 id, uint256 exp, bytes data) internal
```

Sets an attribute.

_Internal helper function that is responsible for setting attributes._

-   May emit an `AttributeSet` event.

#### Parameters

| Name    | Type    | Description                                        |
| ------- | ------- | -------------------------------------------------- |
| account | address | The address for which the attribute should be set. |
| id      | uint256 | The ID of the attribute to set.                    |
| exp     | uint256 | The timestamp of expiry of the attribute.          |
| data    | bytes   | The attribute data to set in bytes.                |

### \_beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address, uint256, uint256) internal virtual
```

_Overrides OpenZeppelin's {ERC721Upgradeable} `_beforeTokenTransfer`
implementation to prevent transferring Proof of Identity NFTs._

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Overrides OpenZeppelin `_authorizeUpgrade` in order to ensure only the
admin role can upgrade the contracts._
