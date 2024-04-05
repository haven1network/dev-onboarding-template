# Solidity API

## H1DevelopedPausable

Wraps Open Zeppelin's `PausableUpgradeable`.
Contains the protected public `pause` and `unpause` functions.

_This contract does not contain any state variables. Even so, a very
small gap has been provided to accommodate the addition of state variables
should the need arise._

### \_\_H1DevelopedPausable_init

```solidity
function __H1DevelopedPausable_init() internal
```

Initializes the `H1DevelopedPausable` contract.

### \_\_H1DevelopedPausable_init_unchained

```solidity
function __H1DevelopedPausable_init_unchained() internal
```

_see {H1DevelopedPausable-\_\_H1DevelopedPausable_init}_

### pause

```solidity
function pause() public
```

Pauses the contract.

_Only callable by an account with the role: `PAUSER_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit a `Paused` event.

### unpause

```solidity
function unpause() public
```

Unpauses the contract.

_Only callable by an account with the role: `UNPAUSER_ROLE`._

-   May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
-   May emit an `Unpaused` event.
