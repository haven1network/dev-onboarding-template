// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../proof-of-identity/interfaces/vendor/IAccountManager.sol";
import "../proof-of-identity/interfaces/vendor/IPermissionsInterface.sol";

contract MockPermissionsInterface is IPermissionsInterface {
    IAccountManager private _accountManager;

    constructor(address accManager) {
        _accountManager = IAccountManager(accManager);
    }

    function assignAccountRole(
        address _account,
        string calldata _orgId,
        string calldata _roleId
    ) external {
        _accountManager.assignAccountRole(_account, _orgId, _roleId, false);
    }

    function updateAccountStatus(
        string calldata _orgId,
        address _account,
        uint256 _action
    ) external {
        _accountManager.updateAccountStatus(_orgId, _account, _action);
    }
}
