// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Auction__InvalidAuctionKind, Auction__InvalidAuctionLength, Auction__ZeroAddress} from "./Errors.sol";

struct Config {
    uint256 kind;
    uint256 length;
    uint256 startingBid;
    address nft;
    uint256 nftID;
    address beneficiary;
}

library ConfigUtils {
    /**
     * @dev The minimum time an auction has to last for.
     */
    uint256 internal constant _MIN_AUCTION_LENGTH = 1 days;

    /**
     * @dev Auction Type: Retail.
     * This value means that only accounts marked as `retail` (`1`) on the
     * `ProofOfIdentity` contract will be allowed to participate in the auction.
     */
    uint256 internal constant _RETAIL = 1;

    /**
     * @dev Auction Type: Institution.
     * This value means that only accounts marked as `institution` (`2`) on the
     * `ProofOfIdentity` contract will be allowed to participate in the auction.
     */
    uint256 internal constant _INSTITUTION = 2;

    /**
     * @dev Auction Type: All.
     * Means that both `retial` (`1`) and `institution` (`2`) accounts as will
     * be allowed to participate in the auction.
     */
    uint256 internal constant _ALL = 3;

    /**
     * @notice Validates a given auction configuration.
     *
     * @dev Will revert if any of the configuration items are not validated.
     * May revert with: `Auction__InvalidAuctionType`
     * May revert with: `Auction__InvalidAuctionLength`
     * May revert with: `Auction__ZeroAddress`
     */
    function validateExn(Config memory cfg) internal pure {
        if (cfg.kind == 0 || cfg.kind > _ALL) {
            revert Auction__InvalidAuctionKind(cfg.kind);
        }

        if (cfg.length < _MIN_AUCTION_LENGTH) {
            revert Auction__InvalidAuctionLength(
                cfg.length,
                _MIN_AUCTION_LENGTH
            );
        }

        if (cfg.nft == address(0)) {
            revert Auction__ZeroAddress();
        }

        if (cfg.beneficiary == address(0)) {
            revert Auction__ZeroAddress();
        }
    }
}
