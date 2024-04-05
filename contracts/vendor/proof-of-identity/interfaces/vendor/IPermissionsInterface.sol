// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPermissionsInterface {
    function assignAccountRole(
        address _account,
        string calldata _orgId,
        string calldata _roleId
    ) external;

    function updateAccountStatus(
        string calldata _orgId,
        address _account,
        uint256 _action
    ) external;
}
