// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libraries/AttributeUtils.sol";

/**
 * @title IProofOfIdentity
 * @dev The interface for the ProofOfIdentity contract.
 */
interface IProofOfIdentity {
    /**
     * @notice Issues a Proof of Identity NFT to the `account`.
     * @param account The address of the account to receive the NFT.
     * @param primaryID Whether the account has verified a primary ID.
     * @param countryCode The ISO 3166-1 alpha-2 country code of the account.
     * @param proofOfLiveliness Whether the account has completed a proof of liveliness check.
     * @param userType The account type of the user: 1 = retail. 2 = institution.
     */
    function issueIdentity(
        address account,
        bool primaryID,
        string calldata countryCode,
        bool proofOfLiveliness,
        uint256 userType,
        uint256[4] memory expiries,
        string calldata uri
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `string`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as a `string`.
     */
    function setStringAttribute(
        address account,
        uint256 id,
        uint256 exp,
        string calldata data
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `uint256`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as `uint256`.
     */
    function setU256Attribute(
        address account,
        uint256 id,
        uint256 exp,
        uint256 data
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `bool`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as `bool`.
     */
    function setBoolAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bool data
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `bytes`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as `bytes`.
     */
    function setBytesAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bytes calldata data
    ) external;

    /**
     * @notice Sets the attribute count.
     * @param count The new count.
     */
    function setAttributeCount(uint256 count) external;

    /**
     * @notice Adds an attribute to the contract.
     * @param name The attribute's name.
     * @param attrType The type of the attribute.
     */
    function addAttribute(
        string calldata name,
        SupportedAttributeType attrType
    ) external;

    /**
     * @notice Updates the URI of a token.
     * @param account the target account of the tokenUri to update.
     * @param tokenUri the URI data to update for the token Id.
     */
    function setTokenURI(
        address account,
        uint256 tokenId,
        string calldata tokenUri
    ) external;

    /**
     * @notice Suspends an account.
     * @param account The account to suspend.
     * @param reason The reason for the suspension.
     */
    function suspendAccount(address account, string calldata reason) external;

    /**
     * @notice Unsuspends an account.
     * @param account The account to unsuspend.
     */
    function unsuspendAccount(address account) external;

    /**
     * @notice Returns a tuple containing whether or not a user has validated
     * their primary ID, the expiry of the attribute and the last time it was
     * updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing whether the account's primary ID has been
     * validated, the expiry of the attribute and the last time it was updated.
     * Returned in the following form: `(bool, uint256, uint256)`
     */
    function getPrimaryID(
        address account
    ) external view returns (bool, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's country code (lowercase), the
     * expiry of the attribute and the last time it was updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing a user's country code (lowercase), the expiry
     * of the attribute and the last time it was updated. Returned in the
     * following form: `(string memory, uint256, uint256)`
     */
    function getCountryCode(
        address account
    ) external view returns (string memory, uint256, uint256);

    /**
     * @notice Returns a tuple containing whether a user's proof of liveliness
     * check has been completed, the expiry of the attribute and the last time
     * it was updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing whether a user's proof of liveliness check
     * has been completed, the expiry of the attribute and the last time it was
     * updated. Returned in the following form: `(bool, uint256, uint256)`
     */
    function getProofOfLiveliness(
        address account
    ) external view returns (bool, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's account type, the expiry of
     * the attribute and the last time it was updated.
     * 1 = Retail
     * 2 = Institution
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing a user's account type, the expiry of the
     * attribute and the last time it was updated.
     * Returned in the following form: `(uint256, uint256, uint256)`
     */
    function getUserType(
        address account
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's competency rating, the expiry
     * of the attribute and the last time it was updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing a user's competency rating, the expiry of the
     * attribute and the last time it was updated.
     * Returned in the following form: `(uint256, uint256, uint256)`
     */
    function getCompetencyRating(
        address account
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Returns a tuple containing the string attribute, the expiry of
     * the attribute and the last time it was updated. Note that if an invalid ID
     * is passed in, the call with revert.
     * If an address for which the attribute has not yet been set is passed in,
     * the default `("", 0, 0)` case will be returned.
     *
     * @param id The attribute ID to fetch.
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing the string attribute, the expiry of the
     * attribute and the last time it was updated. Returned in the following
     * form: `(string memory, uint256, uint256)`
     */
    function getStringAttribute(
        uint256 id,
        address account
    ) external view returns (string memory, uint256, uint256);

    /**
     * @notice Returns a tuple containing the uint256 attribute, the expiry of
     * the attribute and the last time it was updated. Note that if an invalid ID
     * is passed in, the call with revert.
     * If an address for which the attribute has not yet been set is passed in,
     * the default `(0, 0, 0)` case will be returned.
     *
     * @param id The attribute ID to fetch.
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing the uint256 attribute, the expiry of the
     * attribute and the last time it was updated. Returned in the following
     * form: `(uint256, uint256, uint256)`
     */
    function getU256Attribute(
        uint256 id,
        address account
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Returns a tuple containing the bool attribute, the expiry of
     * the attribute and the last time it was updated. Note that if an invalid ID
     * is passed in, the call with revert.
     * If an address for which the attribute has not yet been set is passed in,
     * the default `(false, 0, 0)` case will be returned.
     *
     * @param id The attribute ID to fetch.
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing the uint256 attribute, the expiry of the
     * attribute and the last time it was updated. Returned in the following
     * form: `(bool, uint256, uint256)`
     */
    function getBoolAttribute(
        uint256 id,
        address account
    ) external view returns (bool, uint256, uint256);

    /**
     * @notice Returns a tuple containing the bytes attribute, the expiry of
     * the attribute and the last time it was updated. Note that if an invalid ID
     * is passed in, the call with revert.
     * If an address for which the attribute has not yet been set is passed in,
     * the default `("0x", 0, 0)` case will be returned.
     *
     * @param id The attribute ID to fetch.
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return A tuple containing the uint256 attribute, the expiry of the
     * attribute and the last time it was updated. Returned in the following
     * form: `(bytes, uint256, uint256)`
     */
    function getBytesAttribute(
        uint256 id,
        address account
    ) external view returns (bytes memory, uint256, uint256);

    /**
     * @notice Helper function that returns an attribute's name. Note that
     * it will return an empty string (`""`) if the attribute ID provided is
     * invalid.
     * @param id The ID of the attribute for which the name is fetched.
     * @return The name of the attribute.
     */
    function getAttributeName(uint256 id) external view returns (string memory);

    /**
     * @notice Returns if a given account is suspended.
     * @param account The account the check.
     * @return True if suspended, false otherwise.
     */
    function isSuspended(address account) external view returns (bool);

    /**
     * @notice Returns an account's token ID.
     * @param account The address for which the token ID should be retrieved.
     * @return The token ID.
     */
    function tokenID(address account) external view returns (uint256);

    /**
     * @notice Returns the current token ID counter value.
     * @return The token ID counter value.
     */
    function tokenIDCounter() external view returns (uint256);

    /**
     * @notice Returns amount of attributes currently tracked by the contract.
     * @return The amount of attributes currently tracked by the contract.
     */
    function attributeCount() external view returns (uint256);

    /**
     * @notice Helper function that returns an attribute's type.
     * E.g., 0 (primaryID) => "bool"
     * E.g., 1 (countryCode) => "string"
     *
     * @param id The ID of the attribute for which the type is fetched.
     *
     * @return The type of the attribute.
     */
    function getAttributeType(uint256 id) external view returns (string memory);

    /**
     * Returns the number of tokens in `owner`'s account.
     * @param owner The address of the owner whose balance will be checked.
     */
    function balanceOf(address owner) external view returns (uint256);
}
