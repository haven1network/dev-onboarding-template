// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../fee/interfaces/IFeeContract.sol";

import {Validate, FnSig, FeeProposal, FeeProposalFormatted} from "./components/H1DevelopedUtils.sol";
import "./components/Errors.sol";
import "./components/H1DevelopedAccessControl.sol";
import "./components/H1DevelopedPausable.sol";

/**
 * @title H1DevelopedApplication
 * @author Haven1 Development Team
 * @dev `H1DevelopedApplication` serves as the entry point into the Haven1
 * ecosystem for developers looking to deploy smart contract applications on
 * Haven1.
 *
 * `H1DevelopedApplication` standardizes the following:
 *
 * -   Establishing privileges;
 * -   Pausing and unpausing the contract;
 * -   Upgrading the contract;
 * -   Assigning fees to functions; and
 * -   Handling the payment of those fees.
 *
 * `H1DevelopedApplication` exposes a modifier (`developerFee`) that is to be
 * attached to any function that has a fee associated with it. This modifier
 * will handle the fee logic.
 *
 * IMPORTANT: Contracts that store H1 should __never__ elect to refund the
 * remaining balance when using the `developerFee` modifier as it will send the
 * contract's balance to the user.
 *
 * The `H1DevelopedApplication` does not implement `ReentrancyGuardUpgradeable`.
 * The inheriting contracts must implement this feature where needed.
 */
abstract contract H1DevelopedApplication is
    Initializable,
    UUPSUpgradeable,
    H1DevelopedAccessControl,
    H1DevelopedPausable
{
    /* TYPE DECLARATIONS
    ==================================================*/
    using FnSig for bytes;

    /* STATE VARIABLES
    ==================================================*/
    /**
     * @dev Represents the scaling factor used for converting integers to a
     * higher precision.
     */
    uint256 private constant SCALE = 10 ** 18;

    /**
     * @dev The `FeeContract` that will be interacted with to get fee
     * information, make fee payments etc.
     * Can be updated by {H1DevelopedApplication-setFeeContract}.
     */
    IFeeContract private _feeContract;

    /**
     * @dev The address of the association.
     * Can be updated by {H1DevelopedApplication-setAssociation}.
     */
    address private _association;

    /**
     * @dev The address of the developer.
     * Can be updated by {H1DevelopedApplication-setDeveloper}.
     */
    address private _developer;

    /**
     * @dev The address of the wallet or contract that will collect the
     * developer fees.
     * Can be updated via {H1DevelopedApplication-setDevFeeCollector}.
     */
    address private _devFeeCollector;

    /**
     * @dev The remaining msg.value after the fee has been paid.
     */
    uint256 private _msgValueAfterFee;

    /**
     * @dev A mapping from a function selector to its associated fee.
     */
    mapping(bytes4 => uint256) private _fnFees;

    /**
     * @dev A mapping from function selectors to its function signature, stored
     * as bytes. {FnSig-toString} can be used to convert the bytes back into a
     * human-readable function signature.
     */
    mapping(bytes4 => bytes) private _fnSigs;

    /**
     * @dev List of current fee proposals.
     */
    FeeProposal[] private _feeProposals;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Emits the fee sent to the Fee Contract and to the developer.
     * @param fnSig The function signature against which the fee was applied.
     * @param feeContract The fee sent to the Fee Contract.
     * @param developer The fee sent to the developer.
     */
    event FeePaid(string indexed fnSig, uint256 feeContract, uint256 developer);

    /**
     * @notice Emits the function signature of for which the fee is proposed
     * and the associated fee.
     * @param fnSig The function signature for which the fee is proposed.
     * @param fee The proposed fee.
     */
    event FeeProposed(string indexed fnSig, uint256 fee);

    /**
     * @notice Emits the function signature of for which the fee is set and the
     * associated fee.
     * @param fnSig The function signature for which the fee is set.
     * @param fee The set fee.
     */
    event FeeSet(string indexed fnSig, uint256 fee);

    /**
     * @notice Emits the function signature of for which the fee is rejected and
     * the associated fee.
     * @param fnSig The function signature for which the fee is rejected.
     * @param fee The rejected fee.
     */
    event FeeRejected(string indexed fnSig, uint256 fee);

    /**
     * @notice Emits the function selector for which the admin removed a fee.
     * @param fnSelector The function selector for which the fee was removed.
     * @param fee The fee that was removed.
     */
    event AdminRemovedFee(bytes4 indexed fnSelector, uint256 fee);

    /**
     * @notice Emits the address of the new FeeContract.
     * @param feeContract The address of the new FeeContract.
     */
    event FeeContractAddressUpdated(address indexed feeContract);

    /**
     * @notice Emits the address of the new Association.
     * @param association The address of the new Association.
     */
    event AssociationAddressUpdated(address indexed association);

    /**
     * @notice Emits the address of the new developer.
     * @param developer The address of the new developer.
     */
    event DeveloperAddressUpdated(address indexed developer);

    /**
     * @notice Emits the address of the new dev fee collector.
     * @param devFeeCollector The address of the new dev fee collector.
     */
    event DevFeeCollectorUpdated(address indexed devFeeCollector);

    /**
     * @notice Emits the address of the new dev fee collector.
     * @param devFeeCollector The address of the new fee collector.
     */
    event DevFeeCollectorUpdatedAdmin(address indexed devFeeCollector);

    /* MODIFIERS
    ==================================================*/
    /**
     * @notice This modifier handles the payment of the developer fee.
     * It should be used in functions that need to pay the fee.
     *
     * @param payableFunction If true, the function using this modifier is by
     * default payable and `msg.value` should be reduced by the fee.
     *
     * @param refundRemainingBalance Whether the remaining balance after the
     * function execution should be refunded to the sender.
     *
     * @dev Checks if fee is not only sent via msg.value, but also available as
     * balance in the contract to correctly return underfunded multicalls via
     * delegatecall.
     * May revert with `H1Developed__InsufficientFunds`.
     * May emit a `FeePaid` event.
     */
    modifier developerFee(bool payableFunction, bool refundRemainingBalance) {
        _updateFee();
        uint256 fee = getFnFeeAdj(msg.sig);

        if (msg.value < fee || (address(this).balance < fee)) {
            revert H1Developed__InsufficientFunds(address(this).balance, fee);
        }

        if (payableFunction) {
            _msgValueAfterFee = (msg.value - fee);
        }

        _payFee(fee);

        _;

        if (refundRemainingBalance && address(this).balance > 0) {
            _safeTransfer(msg.sender, address(this).balance);
        }

        delete _msgValueAfterFee;
    }

    /* FUNCTIONS
    ==================================================*/
    /* Init
    ========================================*/
    /**
     * @notice Initializes the `H1DevelopedApplication` contract.
     *
     * @param feeContract_ The address of the `FeeContract`.
     *
     * @param association_ The address of the Haven1 Association.
     *
     * @param developer_ The address of the contract's developer.
     *
     * @param devFeeCollector_ The address of the fee collector.
     *
     * @param fnSigs_ An array of function signatures for which specific
     * fees will be set.
     *
     * @param fnFees_ An array of fees that will be set for their `fnSelector`
     * counterparts.
     *
     * @dev If the length of the `fnSignatures` and `fnFees` do not match, the
     * deployment will fail. They can be of length zero (0) if you do not wish
     * to immediately set any specific fees.
     *
     * May revert with `H1Developed__InvalidAddress`.
     * May revert with `H1Developed__ArrayLengthMismatch`.
     */
    function __H1DevelopedApplication_init(
        address feeContract_,
        address association_,
        address developer_,
        address devFeeCollector_,
        string[] memory fnSigs_,
        uint256[] memory fnFees_
    ) internal onlyInitializing {
        __H1DevelopedAccessControl_init(association_, developer_);
        __H1DevelopedPausable_init();

        __H1DevelopedApplication_init_unchained(
            feeContract_,
            association_,
            developer_,
            devFeeCollector_,
            fnSigs_,
            fnFees_
        );
    }

    /**
     * @dev see {H1DevelopedApplication-__H1DevelopedApplication_init}
     */
    function __H1DevelopedApplication_init_unchained(
        address feeContract_,
        address association_,
        address developer_,
        address devFeeCollector_,
        string[] memory fnSigs_,
        uint256[] memory fnFees_
    ) internal onlyInitializing {
        Validate.addrExn(feeContract_, "Init: feeContract");
        Validate.addrExn(association_, "Init: association");
        Validate.addrExn(developer_, "Init: developer");
        Validate.addrExn(devFeeCollector_, "Init: devFeeCollector");

        _feeContract = IFeeContract(feeContract_);
        _association = association_;
        _developer = developer_;
        _devFeeCollector = devFeeCollector_;

        // Gas Optimization: cache length
        uint256 l = fnSigs_.length;
        uint256 lFees = fnFees_.length;

        if (l != lFees) {
            revert H1Developed__ArrayLengthMismatch(l, lFees);
        }

        if (l > 0) {
            uint256 minFee = _feeContract.getMinDevFee();
            uint256 maxFee = _feeContract.getMaxDevFee();

            for (uint256 i; i < l; i++) {
                string memory sig = fnSigs_[i];
                bytes4 sel = getFnSelector(sig);
                uint256 fee = fnFees_[i];

                Validate.feeExn(fee, minFee, maxFee);
                _fnFees[sel] = fee;
                _fnSigs[sel] = bytes(sig);
            }
        }

        IFeeContract(feeContract_).setGraceContract(true);
    }

    /* Public
    ========================================*/

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
     *
     * @dev Example usage: `getFnFee("0xa9059cbb")`.
     */
    function getFnFeeAdj(bytes4 fnSelector) public view returns (uint256) {
        uint256 minFee = _feeContract.getMinDevFee();
        uint256 maxFee = _feeContract.getMaxDevFee();
        uint256 fee = _fnFees[fnSelector];

        // ensure fee is not less than min fee
        // respect zero (0) fees
        if (fee > 0 && fee < minFee) {
            fee = minFee;
        } else if (fee > maxFee) {
            // ensure fee is not greater than the max fee
            fee = maxFee;
        }

        return (fee * _oneUSDH1()) / SCALE;
    }

    /**
     * @notice Returns the function selector for a given function signature.
     * @param fnSignature The signature of the function.
     * @return The function selector for the given function signature.
     * @dev Example usage: `transfer(address,uint256)`
     */
    function getFnSelector(
        string memory fnSignature
    ) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(fnSignature)));
    }

    /* External
    ========================================*/

    /**
     * @notice Proposes a new fee for a given function. To propose multiple fees
     * at once, see {H1DevelopedApplication-proposeFees}.
     *
     * @param fnSig The signature of the function for which a fee is proposed.
     * @param fee The proposed fee.
     *
     * @dev Note that a function's signature is different from its selector.
     * Function Signature Example: `transfer(address,uint256)`.
     * Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `H1Developed__InvalidFeeAmount`.
     * May emit a `FeeProposed` event.
     */
    function proposeFee(
        string memory fnSig,
        uint256 fee
    ) external onlyRole(DEV_ADMIN_ROLE) {
        if (bytes(fnSig).length == 0) {
            revert H1Developed__InvalidFnSignature(fnSig);
        }

        uint256 minFee = _feeContract.getMinDevFee();
        uint256 maxFee = _feeContract.getMaxDevFee();
        Validate.feeExn(fee, minFee, maxFee);
        _proposeFee(fnSig, fee);

        emit FeeProposed(fnSig, fee);
    }

    /**
     * @notice Proposes fees for a list of functions.
     *
     * @param fnSigs The list of function signatures for which fees are
     * proposed.
     *
     * @param fnFees The list of proposed fees.
     *
     * @dev Note that a function's signature is different from its selector.
     * Function Signature Example: `transfer(address,uint256)`
     *
     * Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `H1Developed__InvalidFeeAmount`.
     * May revert with `H1Developed__ArrayLengthMismatch`.
     * May revert with `H1Developed__ArrayLengthZero`.
     * May emit multiple `FeeProposed` events.
     */
    function proposeFees(
        string[] memory fnSigs,
        uint256[] memory fnFees
    ) external onlyRole(DEV_ADMIN_ROLE) {
        // Gas Optimization: cache length
        uint256 l = fnSigs.length;
        uint256 lFees = fnFees.length;

        if (l != lFees) {
            revert H1Developed__ArrayLengthMismatch(l, lFees);
        }

        if (l == 0) {
            revert H1Developed__ArrayLengthZero();
        }

        uint256 minFee = _feeContract.getMinDevFee();
        uint256 maxFee = _feeContract.getMaxDevFee();

        for (uint256 i; i < l; i++) {
            string memory sig = fnSigs[i];
            uint256 fee = fnFees[i];

            if (bytes(sig).length == 0) {
                revert H1Developed__InvalidFnSignature(sig);
            }

            Validate.feeExn(fee, minFee, maxFee);
            _proposeFee(sig, fee);
            emit FeeProposed(sig, fee);
        }
    }

    /**
     * @notice Approves the proposed fee at the given index.
     * @param index The index of the fee to approve from the `_feeProposals` list.
     *
     * @dev Removes the approved fee out of the `_feeProposals` list.
     * Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `H1Developed__ArrayLengthMismatch`.
     * May revert with `H1Developed__IndexOutOfBounds`.
     * May emit a `FeeSet` event.
     */
    function approveFee(uint256 index) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 l = _feeProposals.length; // Gas Optimization: cache length

        if (l == 0) {
            revert H1Developed__ArrayLengthZero();
        }

        if (index >= l) {
            revert H1Developed__IndexOutOfBounds(index, l - 1);
        }

        // index is now known to be within bounds
        FeeProposal memory p = _feeProposals[index];
        bytes4 sel = p.fnSig.toFnSelector();
        _fnFees[sel] = p.fee;
        _fnSigs[sel] = p.fnSig;

        // remove the approved fee
        _feeProposals[index] = _feeProposals[l - 1];
        _feeProposals.pop();

        emit FeeSet(p.fnSig.toString(), p.fee);
    }

    /**
     * @notice Approves all currently proposed fees.
     *
     * @dev Resets the `_feeProposals` list.
     * Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `H1Developed__ArrayLengthZero`.
     * May emit multiple `FeeSet` events.
     */
    function approveAllFees() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 l = _feeProposals.length; // Gas Optimization: cache length
        if (l == 0) {
            revert H1Developed__ArrayLengthZero();
        }

        for (uint256 i; i < l; i++) {
            FeeProposal memory p = _feeProposals[i];
            bytes4 sel = p.fnSig.toFnSelector();
            _fnFees[sel] = p.fee;
            _fnSigs[sel] = p.fnSig;
            emit FeeSet(p.fnSig.toString(), p.fee);
        }

        delete _feeProposals;
    }

    /**
     * @notice Rejects the proposed fee at the given index.
     * @param index The index of the fee to reject from the `_feeProposals` list.
     *
     * @dev Removes the rejected fee out of the `_feeProposals` list.
     * Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with: `H1Developed__ArrayLengthZero`.
     * May revert with: `H1Developed__IndexOutOfBounds`.
     * May emit a `FeeRejected` event.
     */
    function rejectFee(uint256 index) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 l = _feeProposals.length; // Gas Optimization: cache length

        if (l == 0) {
            revert H1Developed__ArrayLengthZero();
        }

        if (index >= l) {
            revert H1Developed__IndexOutOfBounds(index, l - 1);
        }

        FeeProposal memory p = _feeProposals[index];

        // remove the rejected fee
        _feeProposals[index] = _feeProposals[l - 1];
        _feeProposals.pop();

        emit FeeRejected(p.fnSig.toString(), p.fee);
    }

    /**
     * @notice Rejects all currently proposed fees.
     *
     * @dev Resets the `_feeProposals` list.
     * Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit multiple `FeeRejected` events.
     */
    function rejectAllFees() external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < _feeProposals.length; i++) {
            FeeProposal memory p = _feeProposals[i];
            emit FeeRejected(p.fnSig.toString(), p.fee);
        }

        delete _feeProposals;
    }

    /**
     * @notice Allows for the approval / rejection of fees in the
     * `_feeProposals` list.
     *
     * @param approvals A list of booleans that indicate whether a given fee at
     * the corresponding index in the `_feeProposals` list should be approved.
     *
     * @dev Resets the `_feeProposals` list.
     * Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with: `H1Developed__ArrayLengthZero`.
     * May revert with: `H1Developed__ArrayLengthMismatch`.
     * May emit multiple `FeeSet` events.
     * May emit multiple `FeeRejected` events.
     */
    function reviewFees(
        bool[] memory approvals
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Gas Optimization: cache length
        uint256 l = _feeProposals.length;
        uint256 approvalsLen = approvals.length;

        if (approvalsLen == 0) {
            revert H1Developed__ArrayLengthZero();
        }

        if (approvalsLen != l) {
            revert H1Developed__ArrayLengthMismatch(l, approvalsLen);
        }

        for (uint256 i; i < l; i++) {
            bool isApproved = approvals[i];
            FeeProposal memory p = _feeProposals[i];

            if (isApproved) {
                bytes4 sel = p.fnSig.toFnSelector();
                _fnFees[sel] = p.fee;
                _fnSigs[sel] = p.fnSig;
                emit FeeSet(p.fnSig.toString(), p.fee);
            } else {
                emit FeeRejected(p.fnSig.toString(), p.fee);
            }
        }

        delete _feeProposals;
    }

    /**
     * @notice Allows the admin account to remove a fee.
     * @param fnSelector The function selector for which the fee is removed.
     *
     * @dev Only callable by an account with the role `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
     * May emit an `AdminRemovedFee` event.
     */
    function removeFeeAdmin(
        bytes4 fnSelector
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 fee = _fnFees[fnSelector];
        _fnFees[fnSelector] = 0;
        emit AdminRemovedFee(fnSelector, fee);
    }

    /**
     * @notice Updates the `_feeContract` address.
     * @param feeContract_ The new FeeContract address.
     *
     * @dev Only callable by an account with the role `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
     * May emit a `Association` event.
     */
    function setFeeContract(
        address feeContract_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeContract = IFeeContract(feeContract_);
        emit FeeContractAddressUpdated(feeContract_);
    }

    /**
     * @notice Updates the `_association` address.
     * @param association_ The new Association address.
     *
     * @dev Only callable by an account with the role `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
     * May emit a `AssociationAddressUpdated` event.
     */
    function setAssociation(
        address association_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _association = association_;
        emit AssociationAddressUpdated(association_);
    }

    /**
     * @notice Updates the `_developer` address.
     * @param developer_ The new developer address.
     *
     * @dev Only callable by an account with the role `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
     * May emit a `DeveloperAddressUpdated` event.
     */
    function setDeveloper(
        address developer_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _developer = developer_;
        emit DeveloperAddressUpdated(developer_);
    }

    /**
     * @notice Updates the `_devFeeCollector` address.
     * @param devFeeCollector_ The new fee collector address.
     *
     * @dev Only callable by an account with the role `DEV_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
     * May emit a `FeeCollectorUpdated` event.
     */
    function setDevFeeCollector(
        address devFeeCollector_
    ) external onlyRole(DEV_ADMIN_ROLE) {
        _devFeeCollector = devFeeCollector_;
        emit DevFeeCollectorUpdated(devFeeCollector_);
    }

    /**
     * @notice Updates the `_devFeeCollector` address.
     * @param devFeeCollector_ The new fee collector address.
     *
     * @dev Only callable by an account with the role `DEFAULT_ADMIN_ROLE`.
     * May revert with: /^AccessControl: account (0x[0-9a-f]{40}) is missing role (-1x[0-9a-f]{64})$/
     * May emit a `FeeCollectorUpdatedAdmin` event.
     */
    function setDevFeeCollectorAdmin(
        address devFeeCollector_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _devFeeCollector = devFeeCollector_;
        emit DevFeeCollectorUpdatedAdmin(devFeeCollector_);
    }

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
        returns (FeeProposalFormatted[] memory)
    {
        uint256 l = _feeProposals.length;
        FeeProposalFormatted[] memory out = new FeeProposalFormatted[](l);
        if (l == 0) {
            return out;
        }

        for (uint256 i; i < l; i++) {
            FeeProposal memory p = _feeProposals[i];
            out[i] = FeeProposalFormatted({
                fee: p.fee,
                fnSig: p.fnSig.toString()
            });
        }

        return out;
    }

    /**
     * @notice Returns the address of the `FeeContract`.
     * @return The address of the `FeeContract`.
     */
    function feeContract() external view returns (address) {
        return address(_feeContract);
    }

    /**
     * @notice Returns the address of the `Association`.
     * @return The address of the `Association`.
     */
    function association() external view returns (address) {
        return _association;
    }

    /**
     * @notice Returns the address of the `developer`.
     * @return The address of the `developer`.
     */
    function developer() external view returns (address) {
        return _developer;
    }

    /**
     * @notice Returns the address of the `_devFeeCollector`.
     * @return The address of the `_devFeeCollector`.
     */
    function devFeeCollector() external view returns (address) {
        return _devFeeCollector;
    }

    /**
     * @notice Returns the unadjusted USD fee, if any, associated with the given
     * function selector.
     *
     * @param fnSelector The function selector for which the fee should be
     * retrieved.
     *
     * @return The fee, if any, associated with the given function selector.
     *
     * @dev Example usage: `getFnFee("0xa9059cbb")`
     */
    function getFnFeeUSD(bytes4 fnSelector) public view returns (uint256) {
        return _fnFees[fnSelector];
    }

    /* Internal
    ========================================*/

    /**
     * @dev Overrides OpenZeppelin `_authorizeUpgrade` in order to ensure only the
     * admin role can upgrade the contracts.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @notice Returns the current `msg.value` after the developer fee has been
     * subtracted.
     * @return The `msg.value` after the developer fee has been subtraced.
     * @dev To be used in place of `msg.value` in functions that take a
     * developer fee.
     */
    function msgValueAfterFee() internal view returns (uint256) {
        return _msgValueAfterFee;
    }

    /* Private
    ========================================*/

    /**
     * @notice Pays the fee to the FeeContract and the developer's fee
     * collector.
     * @dev May revert with: `H1Developed__FeeTransferFailed`.
     * May emit a `FeePaid` event.
     */
    function _payFee(uint256 fee) private {
        uint256 asscShare = _feeContract.getAsscShare();
        uint256 feeToAssc = (fee * asscShare) / SCALE;
        uint256 feeToDev = fee - feeToAssc;

        _safeTransfer(address(_feeContract), feeToAssc);
        _safeTransfer(_devFeeCollector, feeToDev);

        emit FeePaid(_fnSigs[msg.sig].toString(), feeToAssc, feeToDev);
    }

    /**
     * @notice Updates the fee from the FeeContract.
     * @dev This will call the update function in the FeeContract, as well as
     * check if it is time to update the local fee because the time threshold
     * was exceeded.
     */
    function _updateFee() private {
        _feeContract.updateFee();
    }

    /**
     * @dev safeTransfer function copied from OpenZeppelin TransferHelper.sol
     * May revert with: `H1Developed__FeeTransferFailed`.
     * @param to The recipient address.
     * @param amount The amount to send.
     */
    function _safeTransfer(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert H1Developed__FeeTransferFailed(to, amount);
        }
    }

    /**
     * @notice Proposes a new fee for a given function.
     * @param fnSig The signature of the function for which a fee is proposed.
     * @param fee The fee proposed fee.
     *
     * @dev Encodes the function signature to bytes and stores as a
     * `FeeProposal` in the _feeProposals list.
     */
    function _proposeFee(string memory fnSig, uint256 fee) private {
        bytes memory sig = bytes(fnSig);
        _feeProposals.push(FeeProposal({fee: fee, fnSig: sig}));
    }

    /**
     * @notice Returns one (1) USD worth of H1.
     * @return One (1) USD worth of H1.
     */
    function _oneUSDH1() private view returns (uint256) {
        return _feeContract.getDevH1USD();
    }

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
