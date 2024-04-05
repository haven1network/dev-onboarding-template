// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {Validate} from "./H1DevelopedUtils.sol";

/**
 * @title H1DevelopedAccessControl
 * @author Haven1 Development Team
 *
 * @notice Contains the various roles to be used throughout the
 * `H1DevelopedApplication` contracts.
 *
 * @dev Note that inheriting contracts may also wish to add extra roles. As
 * such, the last contract in the inheritance chain should call
 * `__AccessControl_init()`.
 *
 * This contract contains only constants which are inlined on compilation.
 * Despite this, a gap has still been provided to cater for future upgrades.
 */
contract H1DevelopedAccessControl is Initializable, AccessControlUpgradeable {
    /* STATE VARIABLES
    ==================================================*/

    /**
     * @dev The Pauser role. Has the ability to pause the contract.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev The Unpauser role. Has the ability to unpause the contract.
     */
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    /**
     * @dev The Dev Admin role. For use in the inheriting contract.
     */
    bytes32 public constant DEV_ADMIN_ROLE = keccak256("DEV_ADMIN_ROLE");

    /* FUNCTIONS
    ==================================================*/

    /**
     * @notice Initializes the `H1DevelopedAccessControl` contract.
     *
     * @param association The address of the Haven1 Association. Will be
     * assigned roles: `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE`, and `UNPAUSER_ROLE`.
     *
     * @param developer The address of the contract's developer. Will be
     * assigned roles: `PAUSER_ROLE` and `DEV_ADMIN_ROLE`.
     *
     * @dev May revert with `H1Developed__InvalidAddress`.
     */
    function __H1DevelopedAccessControl_init(
        address association,
        address developer
    ) internal onlyInitializing {
        __H1DevelopedAccessControl_init_unchained(association, developer);
    }

    /**
     * @dev see {H1DevelopedRoles-__H1DevelopedAccessControl__init}
     */
    function __H1DevelopedAccessControl_init_unchained(
        address association,
        address developer
    ) internal onlyInitializing {
        Validate.addrExn(association, "Init: association");
        Validate.addrExn(developer, "Init: developer");

        _grantRole(DEFAULT_ADMIN_ROLE, association);

        _grantRole(PAUSER_ROLE, association);
        _grantRole(PAUSER_ROLE, developer);

        _grantRole(UNPAUSER_ROLE, association);

        _grantRole(DEV_ADMIN_ROLE, developer);
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
     * For e.g., if the starting `__gap` is `50` and a new variable is added
     * (256 bits in size or part thereof), the gap must now be reduced to `49`.
     */
    uint256[50] private __gap;
}
