// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Error to throw when the zero address has been supplied and it
 * is not allowed.
 */
error Auction__ZeroAddress();

/**
 * @notice Error to throw when an invalid auction kind has been provided.
 * @param provided The auction kind that was provided.
 */
error Auction__InvalidAuctionKind(uint256 provided);

/**
 * @notice Error to throw when an invalid auction length has been provided.
 * @param length The auction length that was provided.
 * @param min The minimum length that is required.
 */
error Auction__InvalidAuctionLength(uint256 length, uint256 min);

/**
 * @notice Error to throw when a feature that requires the auction to be
 * started is accessed while it is inactive.
 */
error Auction__AuctionNotStarted();

/**
 * @notice Error to throw when a feature that requires the auction to be
 * inactive is accessed while it is active.
 */
error Auction__AuctionActive();

/**
 * @notice Error to throw when a feature that requires the auction to be
 * active is accessed after it has finished.
 */
error Auction__AuctionFinished();

/**
 * @notice Error to throw when an account does not have a Proof of Identity
 * NFT.
 */
error Auction__NoIdentityNFT();

/**
 * @notice Error to throw when an account is suspended.
 */
error Auction__Suspended();

/**
 * @notice Error to throw when an attribute has expired.
 * @param attribute The name of the required attribute.
 * @param expiry The expiry of the attribute.
 */
error Auction__AttributeExpired(string attribute, uint256 expiry);

/**
 * @notice Error to throw when an the user type is invalid.
 * @param userType The `userType` of the account.
 * @param required The required `userType`.
 */
error Auction__UserType(uint256 userType, uint256 required);

/**
 * @notice Error to throw when a bid is placed but it is not high enough.
 * @param bid The bid placed.
 * @param highestBid The current highest bid.
 */
error Auction__BidTooLow(uint256 bid, uint256 highestBid);

/**
 * @notice Error to throw when a bidder tries to outbid (/raise) themselves.
 */
error Auction__AlreadyHighestBidder();

/**
 * @notice Error to throw when payable function receives no value.
 */
error Auction__ZeroValue();

/**
 * @notice Error to throw when a transfer has failed.
 */
error Auction__TransferFailed();
