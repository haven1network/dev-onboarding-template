// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../vendor/h1-developed-application/H1DevelopedApplication.sol";
import "../../vendor/proof-of-identity/interfaces/IProofOfIdentity.sol";

import "./components/Errors.sol";
import {Config, ConfigUtils} from "./components/NFTAuctionConfig.sol";

/**
 * @title NFTAuction
 * @author Haven1 Development Team
 * @dev Example implementation of using the `ProofOfIdentity` and
 * `H1DevelopedApplication` contracts to create and permission an auction.
 */
contract NFTAuction is H1DevelopedApplication, ReentrancyGuardUpgradeable {
    /* TYPE DECLARATIONS
    ==================================================*/
    using ConfigUtils for Config;

    /* STATE VARIABLES
    ==================================================*/
    /**
     * @dev The address that will receive the funds after the auction is
     * finished.
     */
    address private _beneficiary;

    /**
     * @dev The kind of the auction, either 1, 2 or 3.
     */
    uint256 private _auctionKind;

    /**
     * @dev Whether the auction has started.
     */
    bool private _started;

    /**
     * @dev Whether the auction has ended.
     */
    bool private _finished;

    /**
     * @dev The length, in seconds, of the auction.
     */
    uint256 private _auctionLength;

    /**
     * @dev The unix timestamp of when the auction ends.
     * If 0, the auction has not started.
     * End time = _auctionStartTime + _auctionLength;
     */
    uint256 private _auctionEndTime;

    /**
     * @dev The Proof of Identity Contract.
     */
    IProofOfIdentity private _proofOfIdentity;

    /**
     * @dev The address of the highest bidder.
     */
    address private _highestBidder;

    /**
     * @dev The highest bid.
     */
    uint256 private _highestBid;

    /**
     * @dev The NFT prize.
     */
    IERC721Upgradeable private _nft;

    /**
     * @dev The ID of the NFT prize.
     */
    uint256 private _nftId;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Notifies the start of an auction.
     * @param endTime The unix timestamp of the end of the auction.
     */
    event AuctionStarted(uint256 endTime);

    /**
     * @notice Notifies the end of an auction.
     * @param winner The address of the winner.
     * @param bid The winning bid.
     */
    event AuctionEnded(address indexed winner, uint256 bid);

    /**
     * @notice Emits the address of the bidder and their bid.
     * @param bidder The address of the bidder.
     * @param amount The bid amount.
     */
    event BidPlaced(address indexed bidder, uint256 amount);

    /**
     * Emits the address of the winner and the winning bid.
     * @param winner The address of the winner.
     * @param amount The winning bid.
     */
    event NFTSent(address indexed winner, uint256 amount);

    /* MODIFIERS
    ==================================================*/
    /**
     * @dev Modifier to be used on any functions that require a user be
     * permissioned per this contract's definition.
     *
     * Ensures that the account:
     * -    has a Proof of Identity NFT;
     * -    is not suspended; and
     * -    is of the requisite `userType`.
     *
     * May revert with `Auction__NoIdentityNFT`.
     * May revert with `Auction__Suspended`.
     * May revert with `Auction__UserType`.
     * May revert with `Auction__AttributeExpired`.
     */
    modifier onlyPermissioned(address account) {
        // ensure the account has a Proof of Identity NFT
        if (!_hasID(account)) {
            revert Auction__NoIdentityNFT();
        }

        // ensure the account is not suspended
        if (_isSuspended(account)) {
            revert Auction__Suspended();
        }

        // ensure the account has a valid `userType`
        _validateUserTypeExn(account);
        _;
    }

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the `NFTAuction` contract.
     *
     * @param feeContract_ The address of the `FeeContract`.
     *
     * @param proofOfIdentity_ The address of the `ProofOfIdentity` contract.
     *
     * @param association_ The Association address.
     *
     * @param developer_ The developer address.
     *
     * @param feeCollector_ The address that is sent the earned developer fees.
     *
     * @param fnSigs_ An array of function signatures for which specific fees
     * will be set.
     *
     * @param fnFees_ An array of fees that will be set for their `fnSelector`
     * counterparts.
     *
     * @param auctionConfig_ A struct containing the auction config.
     */
    function initialize(
        address feeContract_,
        address proofOfIdentity_,
        address association_,
        address developer_,
        address feeCollector_,
        string[] memory fnSigs_,
        uint256[] memory fnFees_,
        Config memory auctionConfig_
    ) external initializer {
        _validateAddrExn(feeContract_);
        _validateAddrExn(proofOfIdentity_);
        _validateAddrExn(association_);
        _validateAddrExn(developer_);
        _validateAddrExn(feeCollector_);

        auctionConfig_.validateExn();

        __H1DevelopedApplication_init(
            feeContract_,
            association_,
            developer_,
            feeCollector_,
            fnSigs_,
            fnFees_
        );

        __ReentrancyGuard_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _proofOfIdentity = IProofOfIdentity(proofOfIdentity_);

        _auctionKind = auctionConfig_.kind;
        _auctionLength = auctionConfig_.length;
        _highestBid = auctionConfig_.startingBid;
        _nft = IERC721Upgradeable(auctionConfig_.nft);
        _nftId = auctionConfig_.nftID;
        _beneficiary = auctionConfig_.beneficiary;
    }

    /* External
    ========================================*/
    /**
     * @notice Starts the auction.
     * @dev Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `Auction__AuctionActive`.
     * May revert with `Auction__AuctionFinished`.
     * May emit an `AuctionStarted` event.
     */
    function startAuction() external whenNotPaused onlyRole(DEV_ADMIN_ROLE) {
        // No need to check _finished as once started, `_started` does not get
        // flipped back false
        if (_started) {
            revert Auction__AuctionActive();
        }

        _nft.transferFrom(msg.sender, address(this), _nftId);

        _started = true;
        _auctionEndTime = block.timestamp + _auctionLength;

        emit AuctionStarted(_auctionEndTime);
    }

    /**
     * @notice Places a bid. If the bid placed is not higher than the current
     * highest bid, this function will revert.
     *
     * If the bid is sufficiently high, the previous bid will be refunded to the
     * previous highest bidder.
     *
     * @dev May revert with `Auction__NoIdentityNFT`.
     * May revert with `Auction__Suspended`.
     * May revert with `Auction__UserType`.
     * May revert with `Auction__AttributeExpired`.
     * May revert with `Auction__AuctionNotStarted`.
     * May revert with `Auction__AuctionFinished`.
     * May revert with `Auction__BidTooLow`.
     * May emit a `BidPlaced` event.
     */
    function bid()
        external
        payable
        nonReentrant
        whenNotPaused
        onlyPermissioned(msg.sender)
        developerFee(true, false)
    {
        uint256 val = msgValueAfterFee();
        if (val == 0) {
            revert Auction__ZeroValue();
        }

        if (!hasStarted()) {
            revert Auction__AuctionNotStarted();
        }

        if (hasFinished()) {
            revert Auction__AuctionFinished();
        }

        if (val <= _highestBid) {
            revert Auction__BidTooLow(val, _highestBid);
        }

        if (msg.sender == _highestBidder) {
            revert Auction__AlreadyHighestBidder();
        }

        _refundBid();

        _highestBidder = msg.sender;
        _highestBid = val;

        emit BidPlaced(msg.sender, val);
    }

    /**
     * @notice Ends the auction.
     *
     * @dev May revert with `Auction__AuctionNotStarted`.
     * May revert with `Auction__AuctionActive`.
     * May revert with `Auction__AuctionFinished`.
     * May revert with `Auction__TransferFailed`.
     * May emit an `NFTSent` event.
     * May emit an `AuctionEnded` event.
     */
    function endAuction() external whenNotPaused nonReentrant {
        // test if the auction has started
        if (!hasStarted()) {
            revert Auction__AuctionNotStarted();
        }

        // if the auction has started but the current ts is less than the end
        // time then the auction is still in progress
        if (inProgress()) {
            revert Auction__AuctionActive();
        }

        // test if the auction has finished
        if (_finished) {
            revert Auction__AuctionFinished();
        }

        _finished = true;

        if (_highestBidder != address(0)) {
            _nft.safeTransferFrom(address(this), _highestBidder, _nftId);

            bool success = _withdraw(_beneficiary, address(this).balance);

            if (!success) {
                revert Auction__TransferFailed();
            }

            emit NFTSent(_highestBidder, _highestBid);
        } else {
            _nft.safeTransferFrom(address(this), _beneficiary, _nftId);
        }

        emit AuctionEnded(_highestBidder, _highestBid);
    }

    /**
     * @notice Returns whether an `account` is eligible to participate in the
     * auction.
     *
     * @param acc The account to check.
     *
     * @return True if the account can place a bid, false otherwise.
     *
     * @dev Requires that the account:
     * -    has a Proof of Identity NFT;
     * -    is not suspended; and
     * -    has the requisite `userType`.
     */
    function accountEligible(address acc) external view returns (bool) {
        return _hasID(acc) && !_isSuspended(acc) && _validateUserType(acc);
    }

    /**
     * @notice Returns the highest bidder. If the auction has ended, returns
     * the winner of the auction.
     * @return The address of the highest / winning bidder.
     */
    function getHighestBidder() external view returns (address) {
        return _highestBidder;
    }

    /**
     * @notice Returns the highest bid. If the auction has ended, returns the
     * winning bid.
     * @return The highest / winning bid.
     */
    function getHighestBid() external view returns (uint256) {
        return _highestBid;
    }

    /**
     * @notice Returns the address of the prize NFT and the NFT ID.
     * @return The address of the prize NFT and its ID.
     */
    function getNFT() external view returns (address, uint256) {
        return (address(_nft), _nftId);
    }

    /**
     * @notice Returns the unix timestamp of when the auction is finished.
     * @return The unix timestamp of when the auction is finished.
     */
    function getFinishTime() external view returns (uint256) {
        return _auctionEndTime;
    }

    /**
     * @notice Returns the kind of the auction:
     *   -   1: Retail
     *   -   2: Institution
     *   -   3: All
     *
     * @return The kind of the auction.
     */
    function getAuctionKind() external view returns (uint256) {
        return _auctionKind;
    }

    /**
     * @notice Returns the length, in seconds, of the auction.
     * @return The length, in seconds, of the auction.
     */
    function getAuctionLength() external view returns (uint256) {
        return _auctionLength;
    }

    /**
     * @notice Returns the address of the auction's beneficiary.
     * @return The address of the auction's beneficiary.
     */
    function getBeneficiary() external view returns (address) {
        return address(_beneficiary);
    }

    /* Public
    ========================================*/
    /**
     * @notice Returns whether the auction has started.
     * @return True if it has started, false otherwise.
     */
    function hasStarted() public view returns (bool) {
        return _started;
    }

    /**
     * @notice Returns whether the auction has finished.
     * @return True if it has finished, false otherwise.
     */
    function hasFinished() public view returns (bool) {
        return _finished || block.timestamp > _auctionEndTime;
    }

    /**
     * @notice Returns whether the auction is in progress.
     * @return True if it is in progress, false otherwise.
     */
    function inProgress() public view returns (bool) {
        return _started && block.timestamp < _auctionEndTime;
    }

    /* Private
    ========================================*/
    /**
     * @notice Refunds the previous highest bidder.
     *
     * @dev Will set the current highest bidder to the zero (0) address.
     * Will set the highest bid to zero (0).
     * The calling code must implement `nonReentrant` as this call transfers
     * control to the `_highestBidder`.
     * May revert with `Auction__TransferFailed`.
     */
    function _refundBid() private {
        if (_highestBidder == address(0)) return;

        address prevAddr = _highestBidder;
        uint256 prevBid = _highestBid;

        _highestBidder = address(0);
        _highestBid = 0;

        bool success = _withdraw(prevAddr, prevBid);

        if (!success) {
            revert Auction__TransferFailed();
        }
    }

    /**
     * @notice Sends an `amount` of H1 to the `to` address.
     * @param to The address to send the H1 to.
     * @param amount The amount to send.
     *
     * @return True if transfer succeeded, false otherwise.
     *
     * @dev The calling code must implement `nonReentrant` as this call
     * transfers control to the `_highestBidder`.
     */
    function _withdraw(address to, uint256 amount) private returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        return success;
    }

    /**
     * @notice Validates that a given address is not the zero address.
     * @dev Reverts with `Auction__ZeroAddress` if the given address is the
     * zero address.
     */
    function _validateAddrExn(address addr) private pure {
        if (addr == address(0)) {
            revert Auction__ZeroAddress();
        }
    }

    /**
     * @notice Validates that a given `expiry` is greater than the current
     * `block.timestamp`.
     *
     * @param expiry The expiry to check.
     *
     * @return True if the expiry is greater than the current timestamp, false
     * otherwise.
     */
    function _validateExpiry(uint256 expiry) private view returns (bool) {
        return expiry > block.timestamp;
    }

    /**
     * @notice Returns whether an account holds a Proof of Identity NFT.
     * @param account The account to check.
     * @return True if the account holds a Proof of Identity NFT, else false.
     */
    function _hasID(address account) private view returns (bool) {
        return _proofOfIdentity.balanceOf(account) > 0;
    }

    /**
     * @notice Returns whether an account is suspended.
     * @param account The account to check.
     * @return True if the account is suspended, false otherwise.
     */
    function _isSuspended(address account) private view returns (bool) {
        return _proofOfIdentity.isSuspended(account);
    }

    /**
     * @dev Determines whether a given user type meets the requirements for
     * the action.
     * Note: Does not validate the expiry.
     */
    function _hasType(uint256 userType) private view returns (bool) {
        return (_auctionKind & userType) > 0;
    }

    /**
     * @notice Helper function to check whether a given `account`'s `userType`
     * is valid.
     *
     * @param account The account to check.
     *
     * @return True if the check is valid, false otherwise.
     *
     * @dev For a `userType` to be valid, it must:
     * -    not be expired; and
     * -    the `_auctionType` must either match the `userType`, or be set to
     * -     `_ALL` (`3`).
     */
    function _validateUserType(address account) private view returns (bool) {
        (uint256 user, uint256 exp, ) = _proofOfIdentity.getUserType(account);
        return _hasType(user) && _validateExpiry(exp);
    }

    /**
     * @notice Similar to `_checkUserType`, but rather than returning a `bool`,
     * will revert if the check fails.
     *
     * @param account The account to check.
     *
     * @dev For a `userType` to be valid, it must:
     * -    not be expired; and
     * -    the `_auctionType` must either match the `userType`, or be set to
     * -     `_ALL` (`3`).
     *
     * May revert with `Auction__UserType`.
     * May revert with `Auction__AttributeExpired`.
     */
    function _validateUserTypeExn(address account) private view {
        (uint256 user, uint256 exp, ) = _proofOfIdentity.getUserType(account);

        if (!_hasType(user)) {
            revert Auction__UserType(user, _auctionKind);
        }

        if (!_validateExpiry(exp)) {
            revert Auction__AttributeExpired("userType", exp);
        }
    }
}
