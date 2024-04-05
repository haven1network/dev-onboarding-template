// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/BytesConversion.sol";
import "./libraries/AttributeUtils.sol";
import "./interfaces/vendor/IPermissionsInterface.sol";
import "./interfaces/vendor/IAccountManager.sol";

/**
 * @title Proof Of Identity
 * @author Haven1 Development Team
 * @dev Currently tracked attributes, their ID and types:
 *
 * | ID |     Attribute     |  Type   | Example Return |
 * |----|-------------------|---------|----------------|
 * |  0 | primaryID         | bool    | true           |
 * |  1 | countryCode       | string  | "sg"           |
 * |  2 | proofOfLiveliness | bool    | true           |
 * |  3 | userType          | uint256 | 1              |
 * |  4 | competencyRating  | uint256 | 88             |
 *
 * Each attribute will also have a corresponding `expiry` and an `updatedAt`
 * field.
 *
 * The following fields are guaranteed to have a non-zero entry for users who
 * successfully completed their identity check:
 *  - primaryID;
 *  - countryCode;
 *  - proofOfLiveliness;  and
 *  - userType.
 *
 * There are explicit getters for all five (5) of the currently supported
 * attributes.
 *
 * Note that while this contract is upgradable, provisions have been made to
 * allow attributes to be added without the need for upgrading. An event will be
 * emitted (`AttributeAdded`) if an attribute is added. If an attribute is added
 * but the contract has not been upgraded to provide a new explicit getter,
 * you can use one of the four (4) generic getters to retrieve the information.
 */
contract ProofOfIdentity is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /* TYPE DECLARATIONS
    ==================================================*/
    using BytesConversion for bytes;
    using AttributeUtils for Attribute;
    using AttributeUtils for SupportedAttributeType;

    /* STATE VARIABLES
    ==================================================*/
    /**
     * @dev The operator role.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @dev The Quorum org.
     */
    string private constant ORG = "HAVEN1";

    /**
     * @dev Maps an address to an "attribute id" to an `Attribute`.
     */
    mapping(address => mapping(uint256 => Attribute)) internal _attributes;

    /**
     * @dev Maps the ID of an attribute to its name.
     */
    mapping(uint256 => string) internal _attributeToName;

    /**
     * @dev Maps the ID of an attribute to its expected type.
     * E.g., 0 (primaryID) => "SupportedAttributeType.BOOL"
     * For the string name of these types see:
     */
    mapping(uint256 => SupportedAttributeType) internal _attributeToType;

    /**
     * @dev Maps a tokenID to a custom URI.
     */
    mapping(uint256 => string) internal _tokenURI;

    /**
     * @dev Mapping owner addresses to their token ID.
     * The compliment storage of {ERC721Upgradeable-_owners}
     */
    mapping(address => uint256) internal _addressToTokenID;

    /**
     * @dev Tracks the token IDs.
     */
    uint256 private _tokenIDCounter;

    /**
     * @dev Holds the total amount of attributes tracked in this version of the
     * contract. As the attribute IDs are zero-indexed, this number also
     * represents the ID to be used for the __next__ attribute.
     */
    uint256 private _attributeCount;

    /**
     * @dev Stores the Quorum Network permissions interface address.
     */
    IPermissionsInterface private _permissionsInterface;

    /**
     * @dev Stores the Quorum Network permissions interface address.
     */
    IAccountManager private _accountManager;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Emits the address for which an attribute was set and the
     * attribute's ID.
     * @param account The address for which the attribute was set.
     * @param attribute The ID of the attribute that was set.
     */
    event AttributeSet(address indexed account, uint256 attribute);

    /**
     * @notice Emits the ID of the newly added attribute and its name.
     * @param id The ID of the newly added attribute.
     * @param name The attribute's name.
     */
    event AttributeAdded(uint256 indexed id, string name);

    /**
     * @notice Emits the address for which an idenity was issued and the ID
     * of the NFT.
     * @param account The account that received the ID NFT.
     * @param tokenID The token ID that was issued.
     */
    event IdentityIssued(address indexed account, uint256 indexed tokenID);

    /**
     * @notice Emits the address of the account for which the token URI was
     * updated, the token ID and the new URI.
     *
     * @param account The account for which the URI was updated.
     * @param tokenID The ID of the associated token.
     * @param uri The new URI.
     */
    event TokenURIUpdated(
        address indexed account,
        uint256 indexed tokenID,
        string uri
    );

    /**
     * @notice Emits the address of the suspended account and the suspension
     * reason.
     *
     * @param account The account that was suspended.
     * @param reason The reason for the suspension.
     */
    event AccountSuspended(address indexed account, string reason);

    /**
     * @notice Emits the address of the account that was unsuspended.
     * @param account The account that was unsuspended.
     */
    event AccountUnsuspended(address indexed account);

    /* ERRORS
    ==================================================*/
    /**
     * @notice Error to be thrown when an invalid attribute ID has been supplied.
     * @param attribute The invalid attribute ID that was supplied.
     */
    error ProofOfIdentity__InvalidAttribute(uint256 attribute);

    /**
     * @notice Error to be thrown when an invalid expiry has been supplied.
     * @param expiry The address of the already verified account.
     */
    error ProofOfIdentity__InvalidExpiry(uint256 expiry);

    /**
     * @notice Error to be thrown when an attempt to issue an ID to an already
     * verified account is made.
     *
     * @param account The address of the already verified account.
     */
    error ProofOfIdentity__AlreadyVerified(address account);

    /**
     * @notice Error to be thrown when an attempt to access a feature that
     * requires an account to be verified.
     *
     * @param account The address of the unverified account.
     */
    error ProofOfIdentity__IsNotVerified(address account);

    /**
     * @notice Error to be thrown when an attempt to transfer a  Proof of
     * Identity NFT is made.
     */
    error ProofOfIdentity__IDNotTransferable();

    /**
     * @notice Error to be thrown when an invalid token ID has been supplied.
     * @param tokenID The supplied token ID.
     */
    error ProofOfIdentity__InvalidTokenID(uint256 tokenID);

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External
    ========================================*/
    function initialize(
        address association,
        address networkOperator,
        address deployer,
        address permissionsInterface,
        address accountManager
    ) external initializer {
        __AccessControl_init();
        __ERC721_init("Proof of Identity", "H1-ID");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, association);
        _grantRole(OPERATOR_ROLE, association);
        _grantRole(OPERATOR_ROLE, networkOperator);
        _grantRole(OPERATOR_ROLE, deployer);

        _permissionsInterface = IPermissionsInterface(permissionsInterface);
        _accountManager = IAccountManager(accountManager);

        _attributeCount = 5;
    }

    /**
     * @notice Issues a Proof of Identity NFT to the `account`.
     * @param account The address of the account to receive the NFT.
     * @param primaryID Whether the account has verified a primary ID.
     * @param countryCode The ISO 3166-1 alpha-2 country code of the account.
     * @param proofOfLiveliness Whether the account has completed a proof of liveliness check.
     * @param userType The account type of the user: 1 = retail. 2 = institution.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `ProofOfIdentity__AlreadyVerified`.
     * May revert with `ProofOfIdentity__InvalidAttribute`.
     * May revert with `ProofOfIdentity__InvalidExpiry`.
     * May emit an `AttributeSet` event.
     * May emit an `IdentityIssued` event.
     */
    function issueIdentity(
        address account,
        bool primaryID,
        string calldata countryCode,
        bool proofOfLiveliness,
        uint256 userType,
        uint256[4] memory expiries,
        string calldata uri
    ) external onlyRole(OPERATOR_ROLE) {
        if (balanceOf(account) > 0) {
            revert ProofOfIdentity__AlreadyVerified(account);
        }

        // test to make sure all expiries are valid
        for (uint8 i; i < 4; i++) {
            uint256 exp = expiries[i];
            if (!_validateExpiry(exp)) {
                revert ProofOfIdentity__InvalidExpiry(exp);
            }
        }

        // increase counters and account keeping
        _tokenIDCounter++;

        uint256 id = _tokenIDCounter;

        _tokenURI[id] = uri;
        _addressToTokenID[account] = id;

        _setAttr(account, 0, expiries[0], abi.encode(primaryID));
        _setAttr(account, 1, expiries[1], abi.encode(countryCode));
        _setAttr(account, 2, expiries[2], abi.encode(proofOfLiveliness));
        _setAttr(account, 3, expiries[3], abi.encode(userType));

        _mint(account, id);
        _permissionsInterface.assignAccountRole(account, ORG, "VTCALL");

        emit IdentityIssued(account, id);
    }

    /**
     * @notice Sets an attribute, the value for which is of type `string`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as a `string`.
     *
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `ProofOfIdentity__IsNotVerified`.
     * May revert with `ProofOfIdentity__InvalidAttribute`.
     * May revert with `ProofOfIdentity__InvalidExpiry`.
     * May emit an `AttributeSet` event.
     */
    function setStringAttribute(
        address account,
        uint256 id,
        uint256 exp,
        string calldata data
    ) external onlyRole(OPERATOR_ROLE) {
        if (balanceOf(account) == 0) {
            revert ProofOfIdentity__IsNotVerified(account);
        }

        if (!_validateID(id, SupportedAttributeType.STRING)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        if (!_validateExpiry(exp)) revert ProofOfIdentity__InvalidExpiry(exp);

        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @notice Sets an attribute, the value for which is of type `uint256`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as `uint256`.
     *
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `ProofOfIdentity__IsNotVerified`.
     * May revert with `ProofOfIdentity__InvalidAttribute`.
     * May revert with `ProofOfIdentity__InvalidExpiry`.
     * May emit an `AttributeSet` event.
     */
    function setU256Attribute(
        address account,
        uint256 id,
        uint256 exp,
        uint256 data
    ) external onlyRole(OPERATOR_ROLE) {
        if (balanceOf(account) == 0) {
            revert ProofOfIdentity__IsNotVerified(account);
        }

        if (!_validateID(id, SupportedAttributeType.U256)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        if (!_validateExpiry(exp)) revert ProofOfIdentity__InvalidExpiry(exp);

        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @notice Sets an attribute, the value for which is of type `bool`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as `bool`.
     *
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `ProofOfIdentity__IsNotVerified`.
     * May revert with `ProofOfIdentity__InvalidAttribute`.
     * May revert with `ProofOfIdentity__InvalidExpiry`.
     * May emit an `AttributeSet` event.
     */
    function setBoolAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bool data
    ) external onlyRole(OPERATOR_ROLE) {
        if (balanceOf(account) == 0) {
            revert ProofOfIdentity__IsNotVerified(account);
        }

        if (!_validateID(id, SupportedAttributeType.BOOL)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        if (!_validateExpiry(exp)) revert ProofOfIdentity__InvalidExpiry(exp);
        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @notice Sets an attribute, the value for which is of type `bytes`.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set as `bytes`.
     *
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `ProofOfIdentity__IsNotVerified`.
     * May revert with `ProofOfIdentity__InvalidAttribute`.
     * May revert with `ProofOfIdentity__InvalidExpiry`.
     * May emit an `AttributeSet` event.
     */
    function setBytesAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bytes calldata data
    ) external onlyRole(OPERATOR_ROLE) {
        if (balanceOf(account) == 0) {
            revert ProofOfIdentity__IsNotVerified(account);
        }

        if (!_validateID(id, SupportedAttributeType.BYTES)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        if (!_validateExpiry(exp)) revert ProofOfIdentity__InvalidExpiry(exp);
        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @notice Sets the attribute count.
     * @param count The new count.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function setAttributeCount(uint256 count) external onlyRole(OPERATOR_ROLE) {
        _attributeCount = count;
    }

    /**
     * @notice Adds an attribute to the contract.
     * @param name The attribute's name.
     * @param attrType The type of the attribute.
     *
     * @dev The current attribute count is used as the next attribute ID, and
     * is then incremented.
     * May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit an `AttributeAdded` event.
     */
    function addAttribute(
        string calldata name,
        SupportedAttributeType attrType
    ) external onlyRole(OPERATOR_ROLE) {
        uint256 id = _attributeCount;
        incrementAttributeCount();
        setAttributeName(id, name);
        setAttributeType(id, attrType);
        emit AttributeAdded(id, name);
    }

    /**
     * @notice Updates the URI of a token.
     * @param account the target account of the tokenUri to update.
     * @param tokenUri the URI data to update for the token Id.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `TokenURIUpdated` event.
     */
    function setTokenURI(
        address account,
        uint256 tokenId,
        string calldata tokenUri
    ) external onlyRole(OPERATOR_ROLE) {
        if (!_exists(tokenId)) revert ProofOfIdentity__InvalidTokenID(tokenId);
        _tokenURI[tokenId] = tokenUri;
        emit TokenURIUpdated(account, tokenId, tokenUri);
    }

    /**
     * @notice Suspends an account.
     * @param account The account to suspend.
     * @param reason The reason for the suspension.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit an `AccountSuspended` event.
     */
    function suspendAccount(
        address account,
        string calldata reason
    ) external onlyRole(OPERATOR_ROLE) {
        _permissionsInterface.updateAccountStatus(ORG, account, 1);
        emit AccountSuspended(account, reason);
    }

    /**
     * @notice Unsuspends an account.
     * @param account The account to unsuspend.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit an `AccountUnsuspended` event.
     */
    function unsuspendAccount(
        address account
    ) external onlyRole(OPERATOR_ROLE) {
        _permissionsInterface.updateAccountStatus(ORG, account, 2);
        emit AccountUnsuspended(account);
    }

    /**
     * @notice Returns a tuple containing whether or not a user has validated
     * their primary ID, the expiry of the attribute and the last time it was
     * updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return Whether the account's primary ID has been validated.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getPrimaryID(
        address account
    ) external view returns (bool, uint256, uint256) {
        Attribute memory attr = _attributes[account][0];
        return (attr.data.toBool(), attr.expiry, attr.updatedAt);
    }

    /**
     * @notice Returns a tuple containing a user's country code (lowercase), the
     * expiry of the attribute and the last time it was updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return The user's country code (lowercase).
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev The country code adheres to the ISO 3166-1 alpha-2 standard.
     * For more information, see:
     * `https://localizely.com/iso-3166-1-alpha-2-list/#`
     */
    function getCountryCode(
        address account
    ) external view returns (string memory, uint256, uint256) {
        Attribute memory attr = _attributes[account][1];
        return (attr.data.toString(), attr.expiry, attr.updatedAt);
    }

    /**
     * @notice Returns a tuple containing whether a user's proof of liveliness
     * check has been completed, the expiry of the attribute and the last time
     * it was updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return Whether a user's proof of liveliness check has been completed.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getProofOfLiveliness(
        address account
    ) external view returns (bool, uint256, uint256) {
        Attribute memory attr = _attributes[account][2];
        return (attr.data.toBool(), attr.expiry, attr.updatedAt);
    }

    /**
     * @notice Returns a tuple containing a user's account type, the expiry of
     * the attribute and the last time it was updated.
     * 1 = Retail
     * 2 = Institution
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return The user's account type.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getUserType(
        address account
    ) external view returns (uint256, uint256, uint256) {
        Attribute memory attr = _attributes[account][3];
        return (attr.data.toU256(), attr.expiry, attr.updatedAt);
    }

    /**
     * @notice Returns a tuple containing a user's competency rating, the expiry
     * of the attribute and the last time it was updated.
     *
     * @param account The address of the account for which the attribute is fetched.
     *
     * @return The user's competency rating.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getCompetencyRating(
        address account
    ) external view returns (uint256, uint256, uint256) {
        Attribute memory attr = _attributes[account][4];
        return (attr.data.toU256(), attr.expiry, attr.updatedAt);
    }

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
     * @return The string attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev May revert with `ProofOfIdentity__InvalidAttribute`.
     */
    function getStringAttribute(
        uint256 id,
        address account
    ) external view returns (string memory, uint256, uint256) {
        if (!_validateID(id, SupportedAttributeType.STRING)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        Attribute memory attr = _attributes[account][id];
        return (attr.data.toString(), attr.expiry, attr.updatedAt);
    }

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
     * @return The uint256 attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev May revert with `ProofOfIdentity__InvalidAttribute`.
     */
    function getU256Attribute(
        uint256 id,
        address account
    ) external view returns (uint256, uint256, uint256) {
        if (!_validateID(id, SupportedAttributeType.U256)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        Attribute memory attr = _attributes[account][id];
        return (attr.data.toU256(), attr.expiry, attr.updatedAt);
    }

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
     * @return The bool attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev May revert with `ProofOfIdentity__InvalidAttribute`.
     */
    function getBoolAttribute(
        uint256 id,
        address account
    ) external view returns (bool, uint256, uint256) {
        if (!_validateID(id, SupportedAttributeType.BOOL)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        Attribute memory attr = _attributes[account][id];
        return (attr.data.toBool(), attr.expiry, attr.updatedAt);
    }

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
     * @return The bytes attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev May revert with `ProofOfIdentity__InvalidAttribute`.
     */
    function getBytesAttribute(
        uint256 id,
        address account
    ) external view returns (bytes memory, uint256, uint256) {
        if (!_validateID(id, SupportedAttributeType.BYTES)) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        Attribute memory attr = _attributes[account][id];
        return (attr.data.toBytes(), attr.expiry, attr.updatedAt);
    }

    /**
     * @notice Helper function that returns an attribute's name. Note that
     * it will return an empty string (`""`) if the attribute ID provided is
     * invalid.
     *
     * @param id The ID of the attribute for which the name is fetched.
     * @return The name of the attribute.
     */
    function getAttributeName(
        uint256 id
    ) external view returns (string memory) {
        return _attributeToName[id];
    }

    /**
     * @notice Returns if a given account is suspended.
     * @param account The account the check.
     * @return True if suspended, false otherwise.
     */
    function isSuspended(address account) external view returns (bool) {
        return _accountManager.getAccountStatus(account) != 2;
    }

    /**
     * @notice Returns an account's token ID.
     * @param account The address for which the token ID should be retrieved.
     * @return The token ID.
     */
    function tokenID(address account) external view returns (uint256) {
        return _addressToTokenID[account];
    }

    /**
     * @notice Returns the current token ID counter value.
     * @return The token ID counter value.
     */
    function tokenIDCounter() external view returns (uint256) {
        return _tokenIDCounter;
    }

    /**
     * @notice Returns amount of attributes currently tracked by the contract.
     * @return The amount of attributes currently tracked by the contract.
     * @dev Note that the attribute IDs are zero-indexed, so the max valid ID
     * is `attributeCount() - 1;`
     */
    function attributeCount() external view returns (uint256) {
        return _attributeCount;
    }

    /* Public
    ========================================*/
    /**
     * @notice Sets the name of an ID.
     * @param id The ID of the attribute for which the name is to be set.
     * @param name The name to set.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function setAttributeName(
        uint256 id,
        string calldata name
    ) public onlyRole(OPERATOR_ROLE) {
        if (id >= _attributeCount) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }
        _attributeToName[id] = name;
    }

    /**
     * @notice Sets the type of the attribute.
     * @param id The ID of the attribute for which the type is to be set.
     * @param attrType The type of the attribute
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function setAttributeType(
        uint256 id,
        SupportedAttributeType attrType
    ) public onlyRole(OPERATOR_ROLE) {
        _attributeToType[id] = attrType;
    }

    /**
     * @notice Increments the attribute count.
     * @dev May revert with:
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function incrementAttributeCount() public onlyRole(OPERATOR_ROLE) {
        _attributeCount++;
    }

    /**
     * @notice Helper function that returns an attribute's type.
     * E.g., 0 (primaryID) => "bool"
     * E.g., 1 (countryCode) => "string"
     *
     * @param id The ID of the attribute for which the type is fetched.
     *
     * @return The type of the attribute.
     * @dev May revert with `ProofOfIdentity__InvalidAttribute`.
     */
    function getAttributeType(uint256 id) public view returns (string memory) {
        if (id >= _attributeCount) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        return _attributeToType[id].toString();
    }

    /**
     * @notice Returns the URI for a given token ID.
     * @param tokenId token ID for which a URI should be fetched.
     * @return The token URI.
     * @dev May revert with `ProofOfIdentity__InvalidTokenID`.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert ProofOfIdentity__InvalidTokenID(tokenId);
        return _tokenURI[tokenId];
    }

    /**
     * @dev Overrides OpenZeppelin's `supportsInterface` implementation to
     * ensure the same interfaces can support access control and ERC721.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* Internal
    ========================================*/
    /**
     * @notice Sets an attribute.
     * @param account The address for which the attribute should be set.
     * @param id The ID of the attribute to set.
     * @param exp The timestamp of expiry of the attribute.
     * @param data The attribute data to set in bytes.
     *
     * @dev Internal helper function that is responsible for setting attributes
     * for the first time.
     *
     * May emit an `AttributeSet` event.
     */
    function _setAttr(
        address account,
        uint256 id,
        uint256 exp,
        bytes memory data
    ) internal {
        Attribute storage attr = _attributes[account][id];

        attr.setAttribute(exp, block.timestamp, data);

        emit AttributeSet(account, id);
    }

    /**
     * @dev Overrides OpenZeppelin's {ERC721Upgradeable} `_beforeTokenTransfer`
     * implementation to prevent transferring Proof of Identity NFTs.
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256,
        uint256
    ) internal virtual override {
        if (from != address(0)) {
            revert ProofOfIdentity__IDNotTransferable();
        }
    }

    /**
     * @dev Overrides OpenZeppelin `_authorizeUpgrade` in order to ensure only the
     * admin role can upgrade the contracts.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /* Private
    ========================================*/

    /**
     * @notice Validates a given attribute ID.
     * @param id The ID to validate.
     * @param expectedType The expected type of the ID.
     * @dev For an ID to be valid it simply must be within the range of possible
     * IDs and match the expected type.
     */
    function _validateID(
        uint256 id,
        SupportedAttributeType expectedType
    ) private view returns (bool) {
        return (id < _attributeCount) && (_attributeToType[id] == expectedType);
    }

    /**
     * @notice Validates a given expiry.
     * @param expiry The expiry to validate.
     * @return True if valid, false otherwise.
     *
     * @dev For an expiry to be valid it must be greater than the current
     * `block.timestamp`. There are no minimum requirements as to how much
     * greater than the current `block.timestamp`.
     */
    function _validateExpiry(uint256 expiry) private view returns (bool) {
        return expiry > block.timestamp;
    }
}
