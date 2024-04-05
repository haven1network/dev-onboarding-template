// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./H1DevelopedAccessControl.sol";

/**
 * @title H1DevelopedPausable
 * @author Haven1 Development Team
 *
 * @notice Wraps Open Zeppelin's `PausableUpgradeable`.
 * Contains the protected public `pause` and `unpause` functions.
 *
 * @dev This contract does not contain any state variables. Even so, a very
 * small gap has been provided to accommodate the addition of state variables
 * should the need arise.
 */
contract H1DevelopedPausable is
    Initializable,
    PausableUpgradeable,
    H1DevelopedAccessControl
{
    /* FUNCTIONS
    ==================================================*/
    /* Init
    ========================================*/

    /**
     * @notice Initializes the `H1DevelopedPausable` contract.
     */
    function __H1DevelopedPausable_init() internal onlyInitializing {
        __Pausable_init();
        __H1DevelopedPausable_init_unchained();
    }

    /**
     * @dev see {H1DevelopedPausable-__H1DevelopedPausable_init}
     */
    function __H1DevelopedPausable_init_unchained() internal onlyInitializing {}

    /* Public
    ========================================*/

    /**
     * @notice Pauses the contract.
     * @dev Only callable by an account with the role: `PAUSER_ROLE`.
     * @dev May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `Paused` event.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only callable by an account with the role: `UNPAUSER_ROLE`.
     * @dev May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit an `Unpaused` event.
     */
    function unpause() public onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    /* GAP
    ==================================================*/

    /**
     * @dev This empty reserved space is put in place to allow future versions
     * to add new variables without shifting down storage in the inheritance
     * chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * As new variables are added, be sure to reduce the gap as required.
     * For e.g., if the starting `__gap` is `25` and a new variable is added
     * (256 bits in size or part thereof), the gap must now be reduced to `24`.
     */
    uint256[25] private __gap;
}
