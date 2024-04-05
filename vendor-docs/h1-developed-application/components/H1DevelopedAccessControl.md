# Solidity API

## H1DevelopedAccessControl

_Contains the various roles to be used throughout the
`H1DevelopedApplication` contracts._

_Note that inheriting contracts may also wish to add extra roles. As
such, the last contract in the inheritance chain should call
`__AccessControl_init()`._

_This contract contains only constants which are inlined on compilation.
Despite this, a gap has still been provided to cater for future upgrades._

### PAUSER_ROLE

```solidity
bytes32 PAUSER_ROLE
```

_The Pauser role. Has the ability to pause the contract._

### UNPAUSER_ROLE

```solidity
bytes32 UNPAUSER_ROLE
```

_The Unpauser role. Has the ability to unpause the contract._

### DEV_ADMIN_ROLE

```solidity
bytes32 DEV_ADMIN_ROLE
```

_The Dev Admin role. For use in the inheriting contract._

### \_\_H1DevelopedAccessControl_init

```solidity
function __H1DevelopedAccessControl_init(address association, address developer) internal
```

Initializes the `H1DevelopedAccessControl` contract.

_May revert with `H1Developed__InvalidAddress`._

#### Parameters

| Name        | Type    | Description                                                                                                              |
| ----------- | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| association | address | The address of the Haven1 Association. Will be assigned roles: `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE`, and `UNPAUSER_ROLE`. |
| developer   | address | The address of the contract's developer. Will be assigned roles: `PAUSER_ROLE` and `DEV_ADMIN_ROLE`.                     |

### \_\_H1DevelopedAccessControl_init_unchained

```solidity
function __H1DevelopedAccessControl_init_unchained(address association, address developer) internal
```

_see {H1DevelopedRoles-**H1DevelopedAccessControl**init}_
