// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {FeeProposalFormatted} from "../components/H1DevelopedUtils.sol";

/**
 * @title IH1DevelopedApplication
 * @dev The interface for the H1DevelopedApplication
 */
interface IH1DevelopedApplication {
    /**
     * @notice Returns the adjusted fee in H1 tokens, if any, associated with
     * the given function selector.
     * If the fee is less than the minimum possible fee, the minimum fee will be
     * returned.
     * If the fee is greater than the maximum possible fee, the maximum fee will
     * be returned.
     *
     * @param fnSelector The function selector for which the fee should be
     * retrieved.
     *
     * @return The fee, if any, associated with the given function selector.
     */
    function getFnFeeAdj(bytes4 fnSelector) external view returns (uint256);

    /**
     * @notice Returns the function selector for a given function signature.
     * @param fnSignature The signature of the function.
     * @return The function selector for the given function signature.
     */
    function getFnSelector(
        string memory fnSignature
    ) external pure returns (bytes4);

    /**
     * @notice Proposes a new fee for a given function. To propose multiple fees
     * at once, see {H1DevelopedApplication-proposeFees}.
     *
     * @param fnSig The signature of the function for which a fee is proposed.
     * @param fee The proposed fee.
     */
    function proposeFee(string memory fnSig, uint256 fee) external;

    /**
     * @notice Proposes fees for a list of functions.
     *
     * @param fnSigs The list of function signatures for which fees are
     * proposed.
     *
     * @param fnFees The list of proposed fees.
     */
    function proposeFees(
        string[] memory fnSigs,
        uint256[] memory fnFees
    ) external;

    /**
     * @notice Approves the proposed fee at the given index.
     * @param index The index of the fee to approve from the `_feeProposals` list.
     */
    function approveFee(uint256 index) external;

    /**
     * @notice Approves all currently proposed fees.
     */
    function approveAllFees() external;

    /**
     * @notice Rejects the proposed fee at the given index.
     * @param index The index of the fee to reject from the `_feeProposals` list.
     */
    function rejectFee(uint256 index) external;

    /**
     * @notice Rejects all currently proposed fees.
     */
    function rejectAllFees() external;

    /**
     * @notice Allows for the approval / rejection of fees in the
     * `_feeProposals` list.
     *
     * @param approvals A list of booleans that indicate whether a given fee at
     * the corresponding index in the `_feeProposals` list should be approved.
     */
    function reviewFees(bool[] memory approvals) external;

    /**
     * @notice Allows the admin account to remove a fee.
     * @param fnSelector The function selector for which the fee is removed.
     */
    function removeFeeAdmin(bytes4 fnSelector) external;

    /**
     * @notice Updates the `_feeContract` address.
     * @param feeContract_ The new FeeContract address.
     */
    function setFeeContract(address feeContract_) external;

    /**
     * @notice Updates the `_association` address.
     * @param association_ The new Association address.
     */
    function setAssociation(address association_) external;

    /**
     * @notice Updates the `_developer` address.
     * @param developer_ The new developer address.
     */
    function setDeveloper(address developer_) external;

    /**
     * @notice Updates the `_devFeeCollector` address.
     * @param devFeeCollector_ The new fee collector address.
     */
    function setDevFeeCollector(address devFeeCollector_) external;

    /**
     * @notice Updates the `_devFeeCollector` address.
     * @param devFeeCollector_ The new fee collector address.
     */
    function setDevFeeCollectorAdmin(address devFeeCollector_) external;

    /**
     * @notice Returns a list of the currently proposed fees and their function
     * signature.
     *
     * @return A list of the currently proposed fees and their function
     * signature.
     */
    function proposedFees()
        external
        view
        returns (FeeProposalFormatted[] memory);

    /**
     * @notice Returns the address of the `FeeContract`.
     * @return The address of the `FeeContract`.
     */
    function feeContract() external view returns (address);

    /**
     * @notice Returns the address of the `Association`.
     * @return The address of the `Association`.
     */
    function association() external view returns (address);

    /**
     * @notice Returns the address of the `developer`.
     * @return The address of the `developer`.
     */
    function developer() external view returns (address);

    /**
     * @notice Returns the address of the `_devFeeCollector`.
     * @return The address of the `_devFeeCollector`.
     */
    function devFeeCollector() external view returns (address);

    /**
     * @notice Returns the unadjusted USD fee, if any, associated with the given
     * function selector.
     *
     * @param fnSelector The function selector for which the fee should be
     * retrieved.
     *
     * @return The fee, if any, associated with the given function selector.
     */
    function getFnFeeUSD(bytes4 fnSelector) external view returns (uint256);
}
