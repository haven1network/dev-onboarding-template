// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../vendor/h1-developed-application/H1DevelopedApplication.sol";

/**
 * @title SimpleStorage
 * @author Haven1 Development Team
 *
 * @notice A Simple Storage contract to demonstrate the features of the
 * `H1DevelopedApplication` contract.
 *
 * A developer fee is added to the increment and decrement functions.
 *
 * The developer account can reset the count.
 */
contract SimpleStorage is H1DevelopedApplication {
    /* TYPE DECLARATIONS
    ==================================================*/
    enum Direction {
        DECR,
        INCR
    }

    /* STATE VARIABLES
    ==================================================*/
    uint256 private _count;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Alerts that the count has been incremented. Emits the new count.
     * @param addr The address that incremented the count.
     * @param dir The count direction.
     * @param count The new count.
     * @param fee The fee paid.
     */
    event Count(
        address indexed addr,
        Direction indexed dir,
        uint256 count,
        uint256 fee
    );

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External
    ========================================*/
    /**
     * @notice Initializes the `SimpleStorage` contract.
     *
     * @param feeContract The FeeContract address.
     *
     * @param association The Association address.
     *
     * @param developer The developer address.
     *
     * @param feeCollector The address that is sent the earned developer fees.
     *
     * @param fnSigs An array of function signatures for which specific fees
     * will be set.
     *
     * @param fnFees An array of fees that will be set for their `fnSelector`
     * counterparts.
     */
    function initialize(
        address feeContract,
        address association,
        address developer,
        address feeCollector,
        string[] memory fnSigs,
        uint256[] memory fnFees
    ) external initializer {
        __H1DevelopedApplication_init(
            feeContract,
            association,
            developer,
            feeCollector,
            fnSigs,
            fnFees
        );

        __AccessControl_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Increments the `_count` by one.
     * Only callable when the contract is not paused.
     *
     * @dev May revert with `Pausable: paused`.
     * May revert with `H1Developed__InsufficientFunds`.
     * May emit a `CountIncremented` event.
     * May emit a `FeePaid` event.
     */
    function incrementCount()
        external
        payable
        whenNotPaused
        developerFee(false, true)
    {
        _count++;
        uint256 fee = getFnFeeAdj(msg.sig);
        emit Count(msg.sender, Direction.INCR, _count, fee);
    }

    /**
     * @notice Decrements the `_count` by one.
     * Only callable when the contract is not paused.
     *
     * @dev May revert with `Pausable: paused`.
     * May revert with `H1Developed__InsufficientFunds`.
     * May emit a `CountDecremented` event.
     * May emit a `FeePaid` event.
     */
    function decrementCount()
        external
        payable
        whenNotPaused
        developerFee(false, true)
    {
        if (_count > 0) {
            _count--;
        }

        uint256 fee = getFnFeeAdj(msg.sig);
        emit Count(msg.sender, Direction.DECR, _count, fee);
    }

    /**
     * @notice Allows the developer to reset the `_count` to zero (0).
     *
     * @dev Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function resetCount() external whenNotPaused onlyRole(DEV_ADMIN_ROLE) {
        _count = 0;
        emit Count(msg.sender, Direction.DECR, _count, 0);
    }

    /**
     * @notice Retruns the current `_count`.
     * @return The current `_count`.
     */
    function count() external view returns (uint256) {
        return _count;
    }
}
