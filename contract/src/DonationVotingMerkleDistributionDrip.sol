// // SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {DonationVotingMerkleDistributionBaseStrategy} from "./DonationVotingMerkleDistributionBaseStrategy.sol";
import {IAllo} from "allo-v2/contracts/core/interfaces/IAllo.sol";
import {AddressDriver} from "./interface/IAddressDriver.sol";
import {Caller} from "./interface/ICaller.sol";
import {Drips} from "./interface/IDrips.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {StreamConfigImpl} from "./StreamConfig.sol";

contract DonationVotingMerkleDistributionDrip is DonationVotingMerkleDistributionBaseStrategy {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the allocation
    struct Allocation {
        address recipientId;
        uint256 amount;
        address token;
    }

    /// @notice Stores the details of the distribution when it's a stream.
    struct StreamDistribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a batch allocation is successful
    /// @param sender The sender of the transaction
    event BatchAllocationSuccessful(address indexed sender);

    /// @notice Emitted when a batch stream distribution is successful
    /// @param sender The sender of the transaction
    event BatchSetStreamSuccessful(address indexed sender, int128 realBalanceDelta);

    /// ================================
    /// ========== Storage =============
    /// ================================
    IERC20 public erc20;

    Drips public drips;
    Caller public caller;
    AddressDriver public driver;

    /// @notice Flag to indicate whether token streaming is required or not.
    bool public stream;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) DonationVotingMerkleDistributionBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Hook called before initializing the strategy.
    /// @param _poolId The 'poolId' to initialize
    /// @param _initializeData The data to be decoded to initialize the strategy
    function _beforeInitialize(uint256 _poolId, InitializeData memory _initializeData) internal override {
        IAllo.Pool memory pool = allo.getPool(_poolId);

        if (pool.token == NATIVE && _initializeData.stream) {
            revert INVALID();
        }

        drips = Drips(_initializeData.drips);
        caller = Caller(_initializeData.dripsCaller);
        driver = AddressDriver(_initializeData.dripsAddressDriver);
        stream = _initializeData.stream;

        if (pool.token != NATIVE) {
            erc20 = IERC20(pool.token);
            erc20.approve(address(driver), type(uint256).max);
        }
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Allocate tokens to recipients, the Allocation[] max is usually 100.
    /// @dev This can only be called during the allocation period. Emits an 'BatchAllocationSuccessful()' event.
    /// @param _data The data to be decoded
    /// @custom:data '(Allocations[] allocations)'
    // /// @param _sender The sender of the transaction
    function _allocate(bytes memory _data, address _sender) internal virtual override onlyActiveAllocation {
        // Decode the '_data' to get the allocations
        Allocation[] memory allocations = abi.decode(_data, (Allocation[]));
        uint256 length = allocations.length;

        // Loop through the allocations and allocate the funds
        for (uint8 i = 0; i < length; i++) {
            _allocateSingle(allocations[i], _sender);
        }

        // Emit batch allocation successful
        emit BatchAllocationSuccessful(_sender);
    }

    /// @notice Allocate funds to recipient.
    /// @dev Emits a 'FundsDistributed()' event
    /// @param _allocation Distribution to be distributed
    /// @param _sender The sender of the transaction
    function _allocateSingle(Allocation memory _allocation, address _sender) internal {
        address recipientId = _allocation.recipientId;
        uint256 amount = _allocation.amount;
        address token = _allocation.token;

        // If the recipient status is not 'Accepted' this will revert, the recipient must be accepted through registration
        if (Status(_getUintRecipientStatus(recipientId)) != Status.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        //TODO: remove this once we can guarantee the safety of bulk native transfers
        // If the token is native reject,
        if (token == NATIVE) {
            revert INVALID();
        }

        // The token must be in the allowed token list and not be native token or zero address
        if (!allowedTokens[token] && !allowedTokens[address(0)]) {
            revert INVALID();
        }

        // If the token is native, the amount must be equal to the value sent, otherwise it reverts
        if (msg.value > 0 && token != NATIVE || token == NATIVE && msg.value != amount) {
            revert INVALID();
        }

        // Transfer the amount to recipient
        if (
            _transferAmountFrom(
                token, TransferData({from: _sender, to: _recipients[recipientId].recipientAddress, amount: amount})
            )
        ) {
            // revert INVALID();

            // Emit that the amount has been allocated to the recipient by the sender
            emit Allocated(recipientId, amount, token, _sender);
        }
    }

    /// @notice Distribute funds to recipients, the Distribution[] max is usually 100.
    /// @dev 'distributionStarted' will be set to 'true' when called. Only the pool manager can call.
    ///      Emits a 'BatchPayoutSuccessful()' event.
    /// @param _data The data to be decoded
    ///  @custom:data if 'stream' is 'true' (AddressDriver.StreamReceiver[] prevStreamReceivers,
    ///                StreamDistribution[] streamDistributions, int128 amt, uint32 duration, uint32 hint1, uint32 hint2)
    ///  @custom:data if 'stream' is 'false'(Distribution[] distributions)
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        if (!distributionStarted) {
            distributionStarted = true;
        }

        if (stream) {
            AddressDriver.StreamReceiver[] memory prevStreamReceivers;
            StreamDistribution[] memory streamDistributions;
            int128 amt;
            uint32 duration;
            uint32 hint1;
            uint32 hint2;

            // Decode the '_data' to get the streamDistributions
            (prevStreamReceivers, streamDistributions, amt, duration, hint1, hint2) = abi.decode(
                _data, (AddressDriver.StreamReceiver[], StreamDistribution[], int128, uint32, uint32, uint32)
            );

            AddressDriver.StreamReceiver[] memory currentStreamReceivers =
                _buildStreamReceiver(streamDistributions, duration);

            int128 realBalanceDelta = driver.setStreams(
                address(erc20), prevStreamReceivers, amt, currentStreamReceivers, hint1, hint2, address(this)
            );

            // Emit that the batch payout was successful
            emit BatchSetStreamSuccessful(_sender, realBalanceDelta);
        } else {
            // Decode the '_data' to get the distributions
            Distribution[] memory distributions = abi.decode(_data, (Distribution[]));
            uint256 length = distributions.length;

            // Loop through the distributions and distribute the funds
            for (uint256 i = 0; i < length; i++) {
                _distributeSingle(distributions[i]);
            }

            // Emit that the batch payout was successful
            emit BatchPayoutSuccessful(_sender);
        }
    }

    /// @notice Distribute funds to recipient.
    /// @dev Emits a 'FundsDistributed()' event
    /// @param _distribution Distribution to be distributed
    function _distributeSingle(Distribution memory _distribution) internal override {
        uint256 index = _distribution.index;
        address recipientId = _distribution.recipientId;
        uint256 amount = _distribution.amount;
        bytes32[] memory merkleProof = _distribution.merkleProof;

        address recipientAddress = _recipients[recipientId].recipientAddress;

        // Validate the distribution and transfer the funds to the recipient, otherwise revert if not valid
        if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            // Set the distribution as distributed
            _setDistributed(index);

            // Update the pool amount
            poolAmount -= amount;

            // Transfer the amount to the recipient
            _transferAmount(pool.token, payable(recipientAddress), amount);

            // Emit that the funds have been distributed to the recipient
            emit FundsDistributed(amount, recipientAddress, pool.token, recipientId);
        } else {
            revert RECIPIENT_ERROR(recipientId);
        }
    }

    function _buildStreamReceiver(StreamDistribution[] memory _distributions, uint32 _duration)
        internal
        returns (AddressDriver.StreamReceiver[] memory)
    {
        uint256 length = _distributions.length;

        AddressDriver.StreamReceiver[] memory receivers = new AddressDriver.StreamReceiver[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 index = _distributions[i].index;
            address recipientId = _distributions[i].recipientId;
            uint256 amount = _distributions[i].amount;
            bytes32[] memory merkleProof = _distributions[i].merkleProof;

            address recipientAddress = _recipients[recipientId].recipientAddress;

            if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
                // Set the distribution as distributed
                _setDistributed(index);

                // Update the pool amount
                poolAmount -= amount;

                receivers[i].accountId = driver.calcAccountId(recipientAddress);
                // TODO: use merkleRoot for id instead of 0
                receivers[i].config =
                    StreamConfigImpl.create(0, calculateFlowRate(uint128(amount), _duration), 0, _duration);
            } else {
                revert RECIPIENT_ERROR(recipientId);
            }
        }

        return receivers;
    }

    /// @notice Calculate Precision Token Unit flow rate per second
    /// @dev This function calculates the precision token unit flow rate per second based on the tokens to send
    ///      and the streaming duration in seconds.
    /// @param tokensToSend_ The number of tokens to be sent
    /// @param duration_ The duration of the streaming in seconds
    /// @return The calculated precision token unit flow rate per second
    function calculateFlowRate(uint128 tokensToSend_, uint32 duration_) internal returns (uint160) {
        uint160 flowRate = tokensToSend_ * 10 ** 9 / duration_;
        if (flowRate < drips.minAmtPerSec()) {
            return drips.minAmtPerSec();
        }
        return flowRate;
    }
}
