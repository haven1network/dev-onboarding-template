// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFeeOracle.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title FeeContract
 * @author Haven1 Development Team
 *
 * @notice This contract collects and distributes application fees from user
 * application transactions.
 *
 * @dev The primary function of this contract is to ensure
 * proper distribution of fees from Haven1 applications to distribution
 * channels.
 */
contract FeeContract is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /* STATE VARIABLES
    ==================================================*/

    /**
     * @notice The role to control the contract.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice Stores the time frame that must be waited before distributing
     * fees to channels.
     */
    uint256 public distributionEpoch;

    /**
     * @notice Stores the time frame that must be waited before updating the
     * fees amount.
     */
    uint256 public feeUpdateEpoch;

    /**
     * @dev Addresses used for fee distribution.
     * `_channels[i]` corresponds to `_weights[i]`.
     */
    address[] internal _channels;

    /**
     * @dev Weights for distribution amounts.
     * `_weights[i]` corresponds to `_channels[i]`.
     */
    uint256[] internal _weights;

    /**
     * @dev the oracle address
     */
    address private _oracle;

    /**
     * @dev The application fee as amount of H1 tokens.
     */
    uint256 private _fee;

    /**
     * * @dev the previous application fee, used in the grace period
     */
    uint256 private _feePrior;

    /**
     * @dev The min fee, in USD, that a developer may charge. Stored to a
     * precision of 18 dec.
     * @custom:oz-renamed-from _minDevFeeMultiple
     */
    uint256 private _minDevFee;

    /**
     * @dev The max fee, in USD, that a developer may charge. Stored to a
     * precision of 18 dec.
     * @custom:oz-renamed-from _maxDevFeeMultiple
     */
    uint256 private _maxDevFee;

    /**
     * @dev The total amount that we divide an address' shares by to compute
     * payments.
     */
    uint256 private _contractShares;

    /**
     * @dev Timestamp of last fee distribution.
     */
    uint256 private _lastDistribution;

    /**
     * @dev Timestamp in which the fee needs to be reset across the network.
     */
    uint256 private _networkFeeResetTimestamp;

    /**
     * @dev The end time of the grace period
     */
    uint256 private _networkFeeGraceTimestamp;

    /**
     * @dev The grace period in seconds.
     */
    uint256 private _gracePeriod;

    /**
     * @dev whitelisted grace contract
     */
    mapping(address => bool) private _graceContracts;

    /**
     * @dev The H1 Native Application Fee, denominated in USD, stored to 18 dec.
     */
    uint256 private _feeUSD;

    /**
     * @dev One (1) USD worth of H1 - current period.
     * Stored to a precision of 18 decimals.
     */
    uint256 private _h1USD;

    /**
     * @dev One (1) USD worth of H1 - previous period.
     * Stored to a precision of 18 decimals.
     */
    uint256 private _h1USDPrev;

    /**
     * @dev The share of the developer fee that the Haven1 Association receives.
     * Stored to a precision of 18 decimals.
     */
    uint256 private _asscShare;

    /**
     * @dev Represents the scaling factor used for converting plain integers to
     * a higher precision.
     */
    uint256 private constant SCALE = 10 ** 18;

    /* EVENTS
    ==================================================*/

    /**
     * @notice Emits the address sending the funds and amount paid.
     * @param from The source account.
     * @param txOrigin The origin of the transaction.
     * @param amount The amount of fees received.
     */
    event FeesReceived(
        address indexed from,
        address indexed txOrigin,
        uint256 amount
    );

    /**
     * @notice Emits the address receiving the fee, and the fee amount.
     * @param to The destination account.
     * @param amount The amount of fees distributed.
     */
    event FeesDistributed(address indexed to, uint256 amount);

    /**
     * @notice Emits the new fee amount.
     * @param newFee The new fee amount.
     */
    event FeeUpdated(uint256 newFee);

    /**
     * @notice Emits the address, shares, and total shares of the contract.
     * @param newChannelAddress The address of the new channel.
     * @param channelWeight The weight of the new channel.
     * @param contractShares The total shares of the contract.
     */
    event ChannelAdded(
        address indexed newChannelAddress,
        uint256 channelWeight,
        uint256 contractShares
    );

    /**
     * @notice Emits address of the adjusted channel, the new channel weight and
     * current share amount.
     *
     * @param adjustedChannel The address of the adjusted channel.
     * @param newChannelWeight The address of the adjusted channel.
     * @param currentContractShares The current contract shares.
     */
    event ChannelAdjusted(
        address indexed adjustedChannel,
        uint256 newChannelWeight,
        uint256 currentContractShares
    );

    /**
     * @notice Emits the address that was removed and the new total shares amount.
     * @param channelRemoved The channel that was removed.
     * @param newTotalSharesAmount The channel that was removed.
     */
    event ChannelRemoved(
        address indexed channelRemoved,
        uint256 newTotalSharesAmount
    );

    /**
     * @notice Emits the new minimum fee.
     * @param newFee The new minimum multiple.
     */
    event MinFeeUpdated(uint256 newFee);

    /**
     * @notice Emits the new maximum fee.
     * @param newFee The new maximum multiple.
     */
    event MaxFeeUpdated(uint256 newFee);

    /**
     * @notice Emits the new oracle address.
     * @param oracleAddress The new oracle address.
     */
    event OracleUpdated(address oracleAddress);

    /**
     * @notice Emits the new epoch length.
     * @param epoch The new epoch length.
     */
    event FeeEpochUpdated(uint256 epoch);

    /**
     * @notice Emits the new epoch length.
     * @param epoch The new epoch length.
     */
    event DistributionEpochUpdated(uint256 epoch);

    /* ERRORS
    ==================================================*/

    /**
     * @dev Error to inform users that funds have failed to transfer.
     */
    error FeeContract__TransferFailed();

    /**
     * @dev Error to inform users that the min duration before a fee
     * distribution can occur has not yet been met.
     */
    error FeeContract__EpochLengthNotYetMet();

    /**
     * @dev Error to inform users an invalid address has been passed to the
     * function.
     * @param account The invalid address that was used.
     */
    error FeeContract__InvalidAddress(address account);

    /**
     * @dev Error to inform users an invalid weight has been passed to the
     * function.
     * @param weight The invalid weight.
     */
    error FeeContract__InvalidWeight(uint256 weight);

    /**
     * @dev Error to inform users that no more addresses can be added to the
     * channels array.
     */
    error FeeContract__ChannelLimitReached();

    /**
     * @dev Error to inform users an invalid address has been passed to the
     * function.
     */
    error FeeContract__ChannelWeightMisalignment();

    /**
     * @dev Error to inform users that the requested channel was not found.
     * @param channel The address of the channel that was requested but not
     * found.
     */
    error FeeContract__ChannelNotFound(address channel);

    /**
     * @dev Error to inform users a request to update the fee failed.
     */
    error FeeContract__FeeUpdateFailed();

    /**
     * @dev Error to inform users that the fee is invalid.
     */
    error FeeContract__InvalidFee();

    /* FUNCTIONS
    ==================================================*/
    /* Constructor and Receive
    ========================================*/

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Gives the contract the ability to receive H1 from external
     * addresses.
     *
     * @dev `msg.data` must be empty.
     * May emit a `FeesReceived` event.
     */
    receive() external payable {
        emit FeesReceived(msg.sender, tx.origin, msg.value);
    }

    /* External
    ========================================*/
    /**
     * @notice Initializes variables during deployment.
     * @param oracle The address for the fee oracle.
     * @param channels The channels that receive payments.
     * @param weights The amount of shares each channel receives.
     * @param haven1Association The address that can add or revoke privileges.
     * @param networkOperator The address that calls restricted functions.
     * @param deployer The address responsible for deploying the contract.
     * @param minDevFee The min multiple on network fee allowed for devs.
     * @param maxDevFee The max multiple on network fee allowed for devs.
     * @param asscShare The share of the dev fee the Association is to receive.
     * @param gracePeriod The grace period, in seconds.
     *
     * @dev There cannot be more than ten channels.
     * Each channel must have a matching weight explicitly supplied.
     */
    function initialize(
        address oracle,
        address[] memory channels,
        uint256[] memory weights,
        address haven1Association,
        address networkOperator,
        address deployer,
        uint256 minDevFee,
        uint256 maxDevFee,
        uint256 asscShare,
        uint256 gracePeriod
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, haven1Association);
        _grantRole(OPERATOR_ROLE, haven1Association);
        _grantRole(OPERATOR_ROLE, networkOperator);
        _grantRole(OPERATOR_ROLE, deployer);

        uint256 chanLength = channels.length;
        uint256 weightsLength = weights.length;

        if (chanLength > 10 || weightsLength > 10) {
            revert FeeContract__ChannelLimitReached();
        }

        // Each channel must have a matching weight explicitly supplied
        if (chanLength != weightsLength) {
            revert FeeContract__ChannelWeightMisalignment();
        }

        // ensure that the min fee does not exceed the max fee
        if (minDevFee > maxDevFee) {
            revert FeeContract__InvalidFee();
        }

        IFeeOracle(oracle).refreshOracle();

        _minDevFee = minDevFee;
        _maxDevFee = maxDevFee;
        _feeUSD = 1 * SCALE; // initial fee is one (1) USD worth of H1.
        _asscShare = asscShare;

        _fee = (IFeeOracle(oracle).consult() * _feeUSD) / SCALE;
        _h1USD = IFeeOracle(oracle).consult();
        _lastDistribution = block.timestamp;

        setDistributionEpoch(86400);
        setFeeUpdateEpoch(86400);

        _gracePeriod = gracePeriod;

        _networkFeeResetTimestamp = block.timestamp + feeUpdateEpoch;
        _oracle = oracle;

        for (uint8 i; i < channels.length; ++i) {
            address channel = channels[i];
            uint256 weight = weights[i];

            // Zero address must not be passed in
            // Each address must be unique
            if (!_validateChannelAddress(channel)) {
                revert FeeContract__InvalidAddress(channel);
            }

            // Weight cannot be zero
            if (!_validateWeight(weight)) {
                revert FeeContract__InvalidWeight(weight);
            }

            _contractShares += weight;
            _channels.push(channel);
            _weights.push(weight);
        }
    }

    /**
     * @notice Adds a new channel with a given weight.
     * @param _newChannelAddress The new channel to add.
     * @param _weight The weight for the new channel.
     *
     * @dev We allow 10 channels to ensure distribution can be managed. This
     * function ensures that there are no duplicate addresses or zero addresses.
     *
     * The total weight is tracked by `CONTRACT_SHARES` which we use to divide
     * each address's shares by then send the correct amounts to each channel.
     *
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `ChannelAdded` event.
     */
    function addChannel(
        address _newChannelAddress,
        uint256 _weight
    ) external onlyRole(OPERATOR_ROLE) {
        if (_channels.length == 10) {
            revert FeeContract__ChannelLimitReached();
        }

        if (!_validateChannelAddress(_newChannelAddress)) {
            revert FeeContract__InvalidAddress(_newChannelAddress);
        }

        if (!_validateWeight(_weight)) {
            revert FeeContract__InvalidWeight(_weight);
        }

        _channels.push(_newChannelAddress);
        _weights.push(_weight);

        _contractShares += _weight;

        emit ChannelAdded(_newChannelAddress, _weight, _contractShares);
    }

    /**
     * @notice Adjusts a channel and its weight.
     * @param _oldChannelAddress The address of the channel to update.
     * @param _newChannelAddress The address of the channel that replaces the old one.
     * @param _newWeight The amount of total shares the new address will receive.
     *
     * @dev The sum of all the channel's weights is tracked by `CONTRACT_SHARES`
     * which we adjust here by subtracting the old weight number and adding the
     * new one.
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `FeeContract__ChannelNotFound`.
     * May emit a `ChannelAdjusted` event.
     */
    function adjustChannel(
        address _oldChannelAddress,
        address _newChannelAddress,
        uint256 _newWeight
    ) external onlyRole(OPERATOR_ROLE) {
        if (!_validateChannelAddress(_newChannelAddress)) {
            revert FeeContract__InvalidAddress(_newChannelAddress);
        }

        if (!_validateWeight(_newWeight)) {
            revert FeeContract__InvalidWeight(_newWeight);
        }

        // indexOf will revert if the index is not found.
        uint8 index = _indexOf(_oldChannelAddress);

        // update the contract shares
        _contractShares -= _weights[index];
        _contractShares += _newWeight;

        // update the channel address and its weight
        _weights[index] = _newWeight;
        _channels[index] = _newChannelAddress;

        emit ChannelAdjusted(_newChannelAddress, _newWeight, _contractShares);
    }

    /**
     * @notice Removes a channel and it's weight.
     * @param _channel The address being removed.
     *
     * @dev The total weight is tracked by `CONTRACT_SHARES`.
     * which we subtract the value from in the middle of this function.
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `FeeContract__ChannelNotFound`.
     * May emit a `ChannelRemoved` event.
     */
    function removeChannel(address _channel) external onlyRole(OPERATOR_ROLE) {
        // indexOf will revert if the index is not found.
        uint8 index = _indexOf(_channel);

        address removedAddress = _channels[index];

        // Because the order of the channels array does not matter, we can use
        // this more performant method to remove the validator. We must simply
        // ensure that the weights array is updated to keep alignment.
        _channels[index] = _channels[_channels.length - 1];
        _channels.pop();

        _contractShares -= _weights[index];

        _weights[index] = _weights[_weights.length - 1];
        _weights.pop();

        emit ChannelRemoved(removedAddress, _contractShares);
    }

    /**
     * @notice Distributes fees to channels.
     *
     * @dev This function can be called when enough time has passed since the
     * last distribution.
     * The balance of the contract is distributed to channels.
     * May revert with `FeeContract__EpochLengthNotYetMet`.
     * May emit a `FeesDistributed` event.
     */
    function distributeFees() external nonReentrant {
        if (!_canDistribute()) revert FeeContract__EpochLengthNotYetMet();
        _distributeFees();
    }

    /**
     * @notice Forces a fee distribution.
     *
     * @dev Can only be called by an operator. To be used in case the funds
     * need to be distributed immediately.
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `FeesDistributed` event.
     */
    function forceDistributeFees()
        external
        onlyRole(OPERATOR_ROLE)
        nonReentrant
    {
        _distributeFees();
    }

    /**
     * @notice Sets the minimum fee for developer applications. __Must__ be to a
     * precision of 18 decimals.
     *
     * @param fee The minimum fee, in USD, that a developer may charge.
     *
     * @dev May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `MinFeeUpdated` event.
     */
    function setMinFee(uint256 fee) external onlyRole(OPERATOR_ROLE) {
        _minDevFee = fee;
        emit MinFeeUpdated(fee);
    }

    /**
     * @notice Sets the maximum fee for developer applications. __Must__ be to a
     * precision of 18 decimals.
     *
     * @param fee The highest fee, in USD, that a developer may charge.
     *
     * @dev May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `MaxFeeUpdated` event.
     */
    function setMaxFee(uint256 fee) external onlyRole(OPERATOR_ROLE) {
        _maxDevFee = fee;
        emit MaxFeeUpdated(fee);
    }

    /**
     * @notice Sets the oracle address.
     * @param newOracle The new oracle address.
     * @dev May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May revert with `FeeContract__InvalidAddress`.
     * May emit an `OracleUpdated` event.
     */
    function setOracle(address newOracle) external onlyRole(OPERATOR_ROLE) {
        if (newOracle == address(0)) {
            revert FeeContract__InvalidAddress(newOracle);
        }

        _oracle = newOracle;

        emit OracleUpdated(newOracle);
    }

    /**
     * @notice Adjust the grace period as an admin.
     * @param gracePeriod The new grace period.
     */
    function setGracePeriod(
        uint256 gracePeriod
    ) external onlyRole(OPERATOR_ROLE) {
        _gracePeriod = gracePeriod;
    }

    /**
     * @notice Sets or removes the `msg.sender` as a grace contract.
     * @param enterGrace Whether to set the `msg.sender` as a grace contract.
     */
    function setGraceContract(bool enterGrace) external {
        _graceContracts[msg.sender] = enterGrace;
    }

    /**
     * @notice Updates the `_feeUSD` value.
     * @param feeUSD_ The new fee, in USD. __Must__ be to a precision of 18
     * decimals.
     * @dev Example:
     * -    1.75 USD: `1750000000000000000`
     * -    1.00 USD: `1000000000000000000`
     * -    0.50 USD: `500000000000000000`
     *
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function setFeeUSD(uint256 feeUSD_) external onlyRole(OPERATOR_ROLE) {
        _feeUSD = feeUSD_;
    }

    /**
     * @notice Updates the `_asscShare` value.
     * @param asscShare_ The new share of the developer fee that the Association
     * will receive. __Must__ be to a precision of 18 decimals.
     * @dev Example:
     * -    10%: `100000000000000000`
     * -    15%: `150000000000000000`
     *
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function setAsscShare(uint256 asscShare_) external onlyRole(OPERATOR_ROLE) {
        _asscShare = asscShare_;
    }

    /**
     * @notice Returns the current fee value in USD to a precision of 18
     * decimals.
     * @return The current fee value in USD to a precision of 18 decimals.
     */
    function getFeeUSD() external view returns (uint256) {
        return _feeUSD;
    }

    /**
     * @notice Returns the current share the Association receives of the
     * developer fee to a precision of 18 decimals.
     * @return The current share the Association receives of the developer fee
     * to a precision of 18 decimals.
     */
    function getAsscShare() external view returns (uint256) {
        return _asscShare;
    }

    /* Public
    ========================================*/

    /**
     * @notice Adjusts how often the fee value can be updated.
     * @param newEpochLength The length of the new time between oracle updates.
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `FeeEpochUpdated` event.
     */
    function setFeeUpdateEpoch(
        uint256 newEpochLength
    ) public onlyRole(OPERATOR_ROLE) {
        feeUpdateEpoch = newEpochLength;
        emit FeeEpochUpdated(newEpochLength);
    }

    /**
     * @notice Adjusts how frequently a fee distribution can occur.
     * @param newEpochLength The new length of time between fee distributions.
     * May revert with:
     * /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     * May emit a `DistributionEpochUpdated` event.
     */
    function setDistributionEpoch(
        uint256 newEpochLength
    ) public onlyRole(OPERATOR_ROLE) {
        distributionEpoch = newEpochLength;
        emit DistributionEpochUpdated(newEpochLength);
    }

    /**
     * @notice Updates the `networkFeeResetTimestamp`, the `_fee`, and the
     * `_h1USD` values.
     *
     * @dev It can be called by anyone. H1Developed or Native applications will
     * also call the function.
     * May emit a `FeeUpdated` event.
     */
    function updateFee() public {
        if (block.timestamp <= _networkFeeResetTimestamp) return;

        _refreshOracle();

        uint256 oracleVal = queryOracle();
        _feePrior = _fee;
        _fee = (oracleVal * _feeUSD) / SCALE;

        _h1USDPrev = _h1USD;
        _h1USD = oracleVal;

        _networkFeeResetTimestamp = feeUpdateEpoch + block.timestamp;
        _networkFeeGraceTimestamp = block.timestamp + _gracePeriod;

        emit FeeUpdated(_fee);
    }

    /**
     * @notice Returns the `networkFeeResetTimestamp`.
     * @return The next fee reset time.
     */
    function nextResetTime() public view returns (uint256) {
        return _networkFeeResetTimestamp;
    }

    /**
     * @notice Returns the fee amount an address should receive.
     * @param index The index in the array of channels/weights.
     * @return The intended fee.
     */
    function amountPaidToUponNextDistribution(
        uint8 index
    ) public view returns (uint256) {
        return (_weights[index] * address(this).balance) / _contractShares;
    }

    /**
     * @notice Returns the `_fee`.
     * @return The current fee.
     */
    function getFee() public view returns (uint256) {
        if (_graceContracts[msg.sender]) {
            return _getFeeForPayment();
        }
        return _fee;
    }

    /**
     * @notice Returns the `_h1USD` value. To be used in H1 Developed
     * Applications.
     * @return The current `_h1USD` value.
     */
    function getDevH1USD() public view returns (uint256) {
        if (_graceContracts[msg.sender]) {
            return _getDevH1USD();
        }
        return _h1USD;
    }

    /**
     * @notice Returns all channels.
     * @return The channels.
     */
    function getChannels() public view returns (address[] memory) {
        return _channels;
    }

    /**
     * @notice Return all the weights.
     * @return The weights.
     */
    function getWeights() public view returns (uint256[] memory) {
        return _weights;
    }

    /**
     * @notice Returns the fee oracle address.
     * @return The fee oracle address.
     */
    function getOracleAddress() public view returns (address) {
        return _oracle;
    }

    /**
     * @notice Returns a channel's address and its weight.
     * @param index The index in the array of channels/weights.
     * @return The channel's address and its weight.
     */
    function getChannelWeightByIndex(
        uint8 index
    ) public view returns (address, uint256) {
        return (_channels[index], _weights[index]);
    }

    /**
     * @notice Returns the contract shares.
     * @return The contract shares.
     */
    function getTotalContractShares() public view returns (uint256) {
        return _contractShares;
    }

    /**
     * @notice Returns the block timestamp that the most recent fee distribution occurred.
     * @return The timestamp of the most recent fee distribution.
     */
    function getLastDistribution() public view returns (uint256) {
        return _lastDistribution;
    }

    /**
     * @notice Returns the min fee, in USD, that a developer may charge.
     * @return The min fee, in USD, that a developer may charge.
     */
    function getMinDevFee() public view returns (uint256) {
        return _minDevFee;
    }

    /**
     * @notice Returns the max fee, in USD, that a developer may charge.
     * @return The max fee, in USD, that a developer may charge.
     */
    function getMaxDevFee() public view returns (uint256) {
        return _maxDevFee;
    }

    /**
     * @notice Returns one (1) USD worth of H1.
     * @return One (1) USD worth of H1.
     */
    function queryOracle() public view returns (uint256) {
        return IFeeOracle(_oracle).consult();
    }

    /* Internal
    ========================================*/

    /**
     * @dev Internal helper function that encapsulates the fee distribution logic.
     * Note that functions calling this function should include a reentrancy
     * guard.
     * May emit a `FeesDistributed` event.
     */
    function _distributeFees() internal {
        uint256 amount = address(this).balance;

        for (uint8 i; i < _channels.length; ++i) {
            uint256 share = (amount * _weights[i]) / _contractShares;

            (bool sent, ) = _channels[i].call{value: share}("");

            if (!sent) revert FeeContract__TransferFailed();

            emit FeesDistributed(_channels[i], share);
        }

        _lastDistribution = block.timestamp;
    }

    /**
     * @notice Refreshes the oracle.
     * @return Whether the refresh was successful.
     */
    function _refreshOracle() internal returns (bool) {
        return IFeeOracle(_oracle).refreshOracle();
    }

    /**
     * @notice `_authorizeUpgrade` this function is overridden to
     * protect the contract by only allowing the admin to upgrade it.
     * @param newImplementation new implementation address.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @notice Returns the index of an address in the `channels` array, if it exists.
     * @param channel The address of the channel for which an index should must
     * be checked.
     *
     * @return Returns the index as a `uint8`.
     *
     * @dev If the address is not found in the `channels` array, this function
     * will revert with a `ChannelNotFound` error.
     */
    function _indexOf(address channel) internal view returns (uint8) {
        for (uint8 i; i < _channels.length; ++i) {
            if (_channels[i] == channel) {
                return i;
            }
        }

        revert FeeContract__ChannelNotFound(channel);
    }

    /**
     * @notice Helper function to validate an address before it is added to
     * the channels array.
     *
     * @param channel The address to be validated.
     * @return bool Whether the address is valid.
     *
     * @dev Validates that an address:
     * 1. does not equal the zero address; and
     * 2. is not already in the channels array.
     */
    function _validateChannelAddress(
        address channel
    ) internal view returns (bool) {
        if (channel == address(0)) return false;

        for (uint8 i; i < _channels.length; ++i) {
            if (_channels[i] == channel) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Returns the current active H1 Native Application fee.
     * @return the current or prior fee, depending on which is lower while in
     * grace period. Else, the normal fee will be returned.
     */
    function _getFeeForPayment() internal view returns (uint256) {
        if (_networkFeeGraceTimestamp > block.timestamp) {
            return (_feePrior < _fee) ? _feePrior : _fee;
        }
        return _fee;
    }

    /**
     * @notice Returns the current period's value of one (1) USD worth of H1.
     * @return the current or prior value, depending on which is lower while in
     * grace period. Else, the normal value will be returned.
     */
    function _getDevH1USD() internal view returns (uint256) {
        if (_networkFeeGraceTimestamp > block.timestamp) {
            return (_h1USDPrev < _h1USD) ? _h1USDPrev : _h1USD;
        }
        return _h1USD;
    }

    /**
     * @notice Helper function to check whether a weight is non-zero.
     * @param weight The weight to check.
     * @return True is the weight is valid, false otherwise.
     * @dev For a weight to be considered valid it must be greater than 0.
     */
    function _validateWeight(uint256 weight) internal pure returns (bool) {
        return weight > 0;
    }

    /**
     * @notice Returns whether a fee distribution can occur.
     * @return Wether a fee distribution can occur.
     */
    function _canDistribute() internal view returns (bool) {
        return block.timestamp > _lastDistribution + distributionEpoch;
    }
}
