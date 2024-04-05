// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev account status is denoted by a fixed integer value. The values are
 * as below:
 *        0 - Not in list
 *        1 - Account pending approval
 *        2 - Active
 *        3 - Inactive
 *        4 - Suspended
 *        5 - Blacklisted
 *        6 - Revoked
 *        7 - Recovery Initiated for blacklisted accounts and pending approval
 *            from network admins
 */
interface IAccountManager {
    function getAccountStatus(address _account) external view returns (uint256);

    /**
     * @notice updates the account status to the passed status value
     * @param _orgId - org id
     * @param _account - account id
     * @param _action - new status of the account
     * @dev the following actions are allowed
     *            1 - Suspend the account
     *            2 - Reactivate a suspended account
     *            3 - Blacklist an account
     *            4 - Initiate recovery for black listed account
     *            5 - Complete recovery of black listed account and update status to active
     */
    function updateAccountStatus(
        string calldata _orgId,
        address _account,
        uint _action
    ) external;

    function assignAccountRole(
        address _account,
        string calldata _orgId,
        string calldata _roleId,
        bool _adminRole
    ) external;
}
