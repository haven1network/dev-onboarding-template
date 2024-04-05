// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../proof-of-identity/interfaces/vendor/IAccountManager.sol";

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
contract MockAccountManager is IAccountManager {
    mapping(address => uint256) private _accountAccessList;

    function getAccountStatus(address account) public view returns (uint256) {
        return _accountAccessList[account];
    }

    /**
     * @notice updates the account status to the passed status value
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
        string calldata,
        address _account,
        uint _action
    ) external {
        // this is all the impl we need for testing
        if (_action == 1) {
            _accountAccessList[_account] = 4;
        }

        if (_action == 2) {
            _accountAccessList[_account] = 2;
        }
    }

    function assignAccountRole(
        address _account,
        string calldata,
        string calldata,
        bool
    ) external {
        _accountAccessList[_account] = 2;
    }
}
