// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract FixedFeeOracle is AccessControl {
    /* STATE VARIABLES
    ==================================================*/
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 private _val;

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/
    constructor(address association_, address networkOperator_, uint256 val_) {
        _grantRole(DEFAULT_ADMIN_ROLE, association_);
        _grantRole(OPERATOR_ROLE, association_);
        _grantRole(OPERATOR_ROLE, networkOperator_);
        _val = val_;
    }

    /* External
    ========================================*/
    function refreshOracle() external pure returns (bool) {
        return true;
    }

    function updateVal(uint256 v) external onlyRole(OPERATOR_ROLE) {
        _val = v;
    }

    function consult() external view returns (uint256) {
        return _val;
    }
}
