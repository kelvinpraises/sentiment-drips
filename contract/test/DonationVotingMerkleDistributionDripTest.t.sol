// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Test contracts
import {Test, console2} from "forge-std/Test.sol";

// Interfaces
import {IStrategy} from "allo-v2/contracts/core/interfaces/IStrategy.sol";

// Strategy libraries
import {DonationVotingMerkleDistributionDrip} from "../src/DonationVotingMerkleDistributionDrip.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from "../src/DonationVotingMerkleDistributionBaseStrategy.sol";

// Core libraries
import {Errors} from "allo-v2/contracts/core/libraries/Errors.sol";
import {Metadata} from "allo-v2/contracts/core/libraries/Metadata.sol";
import {Native} from "allo-v2/contracts/core/libraries/Native.sol";
import {Anchor} from "allo-v2/contracts/core/Anchor.sol";

// Setup libraries
import {AlloSetup} from "./shared/AlloSetup.sol";
import {RegistrySetupFull} from "./shared/RegistrySetup.sol";
import {EventSetup} from "./shared/EventSetup.sol";

// Drips libraries
import {AddressDriver} from "../src/interface/IAddressDriver.sol";
import {Caller} from "../src/interface/ICaller.sol";
import {Drips} from "../src/interface/IDrips.sol";
import {IERC20, ERC20PresetFixedSupply} from "openzeppelin/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract DonationVotingMerkleDistributionDripTest is Test, AlloSetup, RegistrySetupFull, EventSetup, Native, Errors {
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);
    event BatchAllocationSuccessful(address indexed sender);
    event BatchPayoutSuccessful(address indexed sender);
    event BatchSetStreamSuccessful(address indexed sender, int128 realBalanceDelta);
    event ProfileCreated(
        bytes32 profileId, uint256 nonce, string name, Metadata metadata, address indexed owner, address indexed anchor
    );
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status);

    bool public useRegistryAnchor;
    bool public metadataRequired;
    bool public stream;

    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;
    uint256 public poolId;

    address[] public allowedTokens;
    address public token;

    DonationVotingMerkleDistributionDrip public strategy;
    Metadata public poolMetadata;
    // drips

    Drips public drips;
    Caller public caller;
    AddressDriver public driver;
    IERC20 public erc20;

    address public admin = address(1);

    // Setup the tests
    function setUp() public virtual {
        // others
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        // drips
        Drips dripsLogic = Drips(deployCode("Drips.sol", abi.encode(10)));
        drips = Drips(deployCode("Managed.sol:ManagedProxy", abi.encode(dripsLogic, address(this))));

        caller = Caller(deployCode("Caller.sol"));

        // Make AddressDriver's driver ID non-0 to test if it's respected by AddressDriver
        drips.registerDriver(address(1));
        drips.registerDriver(address(1));
        uint32 driverId = drips.registerDriver(address(this));
        AddressDriver driverLogic =
            AddressDriver(deployCode("AddressDriver.sol", abi.encode(drips, address(caller), driverId)));
        driver = AddressDriver(deployCode("Managed.sol:ManagedProxy", abi.encode(driverLogic, admin)));
        drips.updateDriverAddress(driverId, address(driver));

        // others

        registrationStartTime = uint64(block.timestamp + 10);
        registrationEndTime = uint64(block.timestamp + 300);
        allocationStartTime = uint64(block.timestamp + 301);
        allocationEndTime = uint64(block.timestamp + 600);

        useRegistryAnchor = true;
        metadataRequired = true;
        stream = stream;

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = DonationVotingMerkleDistributionDrip(_deployStrategy());

        allowedTokens = new address[](2);

        erc20 = new ERC20PresetFixedSupply("test", "test", type(uint256).max, pool_admin());

        allowedTokens[0] = NATIVE;
        allowedTokens[1] = address(erc20);

        vm.prank(allo_owner());
        allo().updatePercentFee(0);

        vm.startPrank(pool_admin());
        erc20.approve(address(allo()), type(uint256).max);
        erc20.transfer(randomAddress2(), erc20.totalSupply() / 100);

        poolId = allo().createPoolWithCustomStrategy(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            ),
            address(erc20),
            1e18,
            poolMetadata,
            pool_managers()
        );

        vm.stopPrank();
    } // ✅

    function _deployStrategy() internal virtual returns (address payable) {
        return payable(
            address(
                new DonationVotingMerkleDistributionDrip(
                address(allo()),
                "DonationVotingMerkleDistributionDrip"
                )
            )
        );
    } // ✅

    function test_deployment() public {
        assertEq(address(strategy.getAllo()), address(allo()));
        assertEq(strategy.getStrategyId(), keccak256(abi.encode("DonationVotingMerkleDistributionDrip")));
    } // ✅

    function test_initialize() public {
        assertEq(strategy.getPoolId(), poolId);
        assertEq(strategy.useRegistryAnchor(), useRegistryAnchor);
        assertEq(strategy.metadataRequired(), metadataRequired);
        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime);
        // TODO: add other initialization predicates
        assertTrue(strategy.allowedTokens(NATIVE));
    } // ✅

    function testRevert_initialize_withNoAllowedToken() public {
        strategy = new DonationVotingMerkleDistributionDrip(address(allo()), "DonationVotingMerkleDistributionDrip");
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    new address[](0)
                )
            )
        );
        assertTrue(strategy.allowedTokens(address(0)));
    } // ✅

    function testRevert_initialize_withNotAllowedToken() public {
        DonationVotingMerkleDistributionDrip testStrategy =
            new DonationVotingMerkleDistributionDrip(address(allo()), "DonationVotingMerkleDistributionDrip");
        address[] memory tokensAllowed = new address[](1);
        tokensAllowed[0] = makeAddr("token");
        vm.prank(address(allo()));
        testStrategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    tokensAllowed
                )
            )
        );
        assertFalse(testStrategy.allowedTokens(makeAddr("not-allowed-token")));
    } // ✅

    function test_initialize_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );
    } // ✅

    function testRevert_initialize_ALREADY_INITIALIZED() public {
        vm.expectRevert(ALREADY_INITIALIZED.selector);

        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );
    } // ✅

    function testRevert_initialize_INVALID() public {
        strategy = new DonationVotingMerkleDistributionDrip(address(allo()), "DonationVotingMerkleDistributionDrip");
        // when _registrationStartTime is in past
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    uint64(block.timestamp - 1),
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );

        // when _registrationStartTime > _registrationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    uint64(block.timestamp),
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );

        // when _registrationStartTime > _allocationStartTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    uint64(block.timestamp),
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );

        // when _allocationStartTime > _allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    uint64(block.timestamp),
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );

        // when  _registrationEndTime > _allocationEndTime
        vm.expectRevert(INVALID.selector);
        vm.prank(address(allo()));
        strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    useRegistryAnchor,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    registrationStartTime - 1,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );
    } // ✅

    // Tests that the correct recipient is returned
    function test_getRecipient() public {
        address recipientId = __register_recipient();
        DonationVotingMerkleDistributionBaseStrategy.Recipient memory recipient = strategy.getRecipient(recipientId);
        assertTrue(recipient.useRegistryAnchor);
        assertEq(recipient.recipientAddress, recipientAddress());
        assertEq(recipient.metadata.protocol, 1);
        assertEq(keccak256(abi.encode(recipient.metadata.pointer)), keccak256(abi.encode("metadata")));
    } // ✅

    // Tests that the correct recipient status is returned
    function test_getRecipientStatus() public {
        address recipientId = __register_recipient();
        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Pending));
    } // ✅

    //  Tests that the correct recipient status is returned for an appeal
    function test_register_getRecipientStatus_appeal() public {
        address recipientId = __register_reject_recipient();
        bytes memory data = __generateRecipientWithId(profile1_anchor());

        vm.expectEmit(false, false, false, true);
        emit UpdatedRegistration(profile1_anchor(), data, profile1_member1(), 4);

        vm.prank(address(allo()));
        strategy.registerRecipient(data, profile1_member1());

        IStrategy.Status recipientStatus = strategy.getRecipientStatus(recipientId);
        assertEq(uint8(recipientStatus), uint8(IStrategy.Status.Appealed));
    } // ✅ TODO: Implement this on the frontend!

    // Tests that the pool manager can update the recipient status
    function test_reviewRecipients() public {
        __register_accept_recipient();
        assertEq(strategy.statusesBitMap(0), 2);
    } // ✅

    // Tests that you can only review recipients when registration is active
    function testRevert_reviewRecipients_REGISTRATION_NOT_ACTIVE() public {
        __register_recipient();
        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);
        vm.warp(allocationStartTime + 1);

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 1});
        strategy.reviewRecipients(statuses);
    } // ✅

    // Tests that only the pool admin can review recipients
    function testRevert_reviewRecipients_UNAUTHORIZED() public {
        __register_recipient();
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.warp(registrationStartTime + 1);

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({index: 0, statusRow: 1});

        strategy.reviewRecipients(statuses);
    } // ✅

    function test_getPayouts() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));

        address[] memory recipientsIds = new address[](2);
        recipientsIds[0] = profile1_anchor();
        recipientsIds[1] = makeAddr("noRecipient");

        bytes[] memory data = new bytes[](2);

        data[0] = abi.encode(distributions[0]);
        data[1] = abi.encode(
            DonationVotingMerkleDistributionBaseStrategy.Distribution({
                index: 1,
                recipientId: makeAddr("noRecipient"),
                amount: 1e18,
                merkleProof: new bytes32[](0)
            })
        );

        IStrategy.PayoutSummary[] memory summary = strategy.getPayouts(recipientsIds, data);

        assertEq(summary[0].amount, 1e18);
        assertEq(summary[1].amount, 0);
    } // ✅ TODO: to need or not to need

    // Tests that the strategy timestamps can be updated and updated correctly
    function test_updatePoolTimestamps() public {
        vm.expectEmit(false, false, false, true);
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10, pool_admin()
        );

        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );

        assertEq(strategy.registrationStartTime(), registrationStartTime);
        assertEq(strategy.registrationEndTime(), registrationEndTime);
        assertEq(strategy.allocationStartTime(), allocationStartTime);
        assertEq(strategy.allocationEndTime(), allocationEndTime + 10);
    } // ✅ TODO: Implement this on the front end!

    function testRevert_updatePoolTimestamps_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.updatePoolTimestamps(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime + 10
        );
    } // ✅

    function testRevert_updatePoolTimestamps_INVALID() public {
        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(
            uint64(block.timestamp - 1), registrationEndTime, allocationStartTime, allocationEndTime
        );
    } // ✅

    function testRevert_withdraw_NOT_ALLOWED_30days() public {
        vm.warp(allocationEndTime + 1 days);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.withdraw(1e18);
    } // ✅

    function testRevert_withdraw_NOT_ALLOWED_exceed_amount() public {
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.withdraw(2e18);
    } // ✅

    function testRevert_withdraw_UNAUTHORIZED() public {
        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(randomAddress());
        strategy.withdraw(1e18);
    } // ✅

    function test_withdraw() public {
        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = erc20.balanceOf(pool_admin());

        vm.prank(pool_admin());
        strategy.withdraw(1e18);

        assertEq(erc20.balanceOf(pool_admin()), balanceBefore + 1e18);
    } // ✅

    function test_updateDistribution() public {
        vm.warp(allocationEndTime + 1);

        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectEmit(false, false, false, true);
        emit DistributionUpdated(merkleRoot, metadata);

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, metadata);
    } // ✅

    function testRevert_updateDistribution_INVALID() public {
        test_distribute();
        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.expectRevert(INVALID.selector);
        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, metadata);
    } // ✅

    function testRevert_updateDistribution_ALLOCATION_NOT_ENDED() public {
        vm.expectRevert(ALLOCATION_NOT_ENDED.selector);

        vm.prank(pool_admin());
        strategy.updateDistribution("", Metadata({protocol: 1, pointer: "metadata"}));
    } // ✅

    function testRevert_updateDistribution_UNAUTHORIZED() public {
        vm.warp(allocationEndTime + 1);
        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(randomAddress());
        strategy.updateDistribution("", Metadata({protocol: 1, pointer: "metadata"}));
    } // ✅

    function test_isDistributionSet_True() public {
        vm.warp(allocationEndTime + 1);

        bytes32 merkleRoot = keccak256(abi.encode("merkleRoot"));
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.prank(pool_admin());
        strategy.updateDistribution(merkleRoot, metadata);

        assertTrue(strategy.isDistributionSet());
    } // ✅ TODO: Implement this on the frontend!

    function test_isDistributionSet_False() public {
        assertFalse(strategy.isDistributionSet());
    } // ✅

    function test_hasBeenDistributed_True() public {
        test_distribute();
        assertTrue(strategy.hasBeenDistributed(0));
    } // ✅ TODO: Implement this on the frontend!

    function test_hasBeenDistributed_False() public {
        assertFalse(strategy.hasBeenDistributed(0));
    } // ✅

    function test_isValidAllocator() public {
        assertTrue(strategy.isValidAllocator(address(0)));
        assertTrue(strategy.isValidAllocator(makeAddr("random")));
    } // ✅

    function test_isPoolActive() public {
        assertFalse(strategy.isPoolActive());
        vm.warp(registrationStartTime + 1);
        assertTrue(strategy.isPoolActive());
    } // ✅ TODO: Implement this on the frontend!

    function test_registerRecipient_new_withRegistryAnchor() public {
        DonationVotingMerkleDistributionBaseStrategy _strategy =
            new DonationVotingMerkleDistributionDrip(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    false,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );

        vm.warp(registrationStartTime + 1);

        bytes memory data = abi.encode(recipientAddress(), profile1_anchor(), Metadata(1, "metadata"));

        vm.expectEmit(false, false, false, true);
        emit Registered(profile1_anchor(), abi.encode(data, 0), address(profile1_member1()));

        vm.prank(address(allo()));
        address recipientId = _strategy.registerRecipient(data, profile1_member1());

        DonationVotingMerkleDistributionBaseStrategy.Status status = _strategy.getRecipientStatus(recipientId);
        assertEq(uint8(IStrategy.Status.Pending), uint8(status));
    } // ✅ TODO: Implement this on the frontend!

    function testRevert_registerRecipient_new_withRegistryAnchor_UNAUTHORIZED() public {
        DonationVotingMerkleDistributionBaseStrategy _strategy =
            new DonationVotingMerkleDistributionDrip(address(allo()), "DonationVotingStrategy");
        vm.prank(address(allo()));
        _strategy.initialize(
            poolId,
            abi.encode(
                DonationVotingMerkleDistributionBaseStrategy.InitializeData(
                    false,
                    metadataRequired,
                    stream,
                    registrationStartTime,
                    registrationEndTime,
                    allocationStartTime,
                    allocationEndTime,
                    address(drips),
                    address(caller),
                    address(driver),
                    allowedTokens
                )
            )
        );

        vm.warp(registrationStartTime + 1);

        bytes memory data = abi.encode(recipientAddress(), profile1_anchor(), Metadata(1, "metadata"));

        vm.expectRevert(UNAUTHORIZED.selector);
        vm.prank(address(allo()));
        _strategy.registerRecipient(data, profile2_member1());
    } // ✅

    function testRevert_registerRecipient_UNAUTHORIZED() public {
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(UNAUTHORIZED.selector);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        strategy.registerRecipient(data, profile2_member1());
    } // ✅

    function testRevert_registerRecipient_REGISTRATION_NOT_ACTIVE() public {
        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        strategy.registerRecipient(data, profile1_member1());
    } // ✅

    function testRevert_registerRecipient_RECIPIENT_ERROR() public {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));

        vm.prank(address(allo()));

        bytes memory data = abi.encode(profile1_anchor(), address(0), metadata);
        strategy.registerRecipient(data, profile1_member1());
    } // ✅

    function testRevert_registerRecipient_INVALID_METADATA() public {
        Metadata memory metadata = Metadata({protocol: 0, pointer: "metadata"});
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(INVALID_METADATA.selector);

        vm.prank(address(allo()));

        bytes memory data = abi.encode(profile1_anchor(), recipientAddress(), metadata);
        strategy.registerRecipient(data, profile1_member1());
    } // ✅

    function test_allocate() public virtual {
        __register_accept_recipient_allocate();
    } // ✅ TODO: Implement this on the frontend!

    function testRevert_allocate_ALLOCATION_NOT_ACTIVE() public {
        vm.expectRevert(ALLOCATION_NOT_ACTIVE.selector);

        DonationVotingMerkleDistributionDrip.Allocation[] memory allocations =
            new DonationVotingMerkleDistributionDrip.Allocation[](1);

        DonationVotingMerkleDistributionDrip.Allocation memory allocation0 = DonationVotingMerkleDistributionDrip
            .Allocation({recipientId: randomAddress(), amount: 1e18, token: address(123)});

        allocations[0] = allocation0;

        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(allocations));
    } // ✅ TODO: Implement this on the frontend!

    function testRevert_allocate_RECIPIENT_ERROR() public {
        vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, randomAddress()));

        DonationVotingMerkleDistributionDrip.Allocation[] memory allocations =
            new DonationVotingMerkleDistributionDrip.Allocation[](1);

        DonationVotingMerkleDistributionDrip.Allocation memory allocation0 = DonationVotingMerkleDistributionDrip
            .Allocation({recipientId: randomAddress(), amount: 1e18, token: address(123)});

        allocations[0] = allocation0;

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(allocations));
    } // ✅

    function testRevert_allocate_INVALID_invalidToken() public virtual {
        address recipientId = __register_accept_recipient();

        vm.expectRevert(INVALID.selector);

        DonationVotingMerkleDistributionDrip.Allocation[] memory allocations =
            new DonationVotingMerkleDistributionDrip.Allocation[](1);

        DonationVotingMerkleDistributionDrip.Allocation memory allocation0 = DonationVotingMerkleDistributionDrip
            .Allocation({recipientId: recipientId, amount: 1e18, token: address(456)});

        allocations[0] = allocation0;

        vm.warp(allocationStartTime + 1);
        vm.deal(pool_admin(), 1e20);
        vm.prank(pool_admin());
        allo().allocate(poolId, abi.encode(allocations));
    } // ✅

    // TODO: fix bulk NATIVE allocate
    // function testRevert_allocate_INVALID_amountMismatch() public {
    //     address recipientId = __register_accept_recipient();

    //     vm.expectRevert(INVALID.selector);

    //     DonationVotingMerkleDistributionDrip.Allocation[] memory allocations =
    //         new DonationVotingMerkleDistributionDrip.Allocation[](1);

    //     DonationVotingMerkleDistributionDrip.Allocation memory allocation0 =
    //         DonationVotingMerkleDistributionDrip.Allocation({recipientId: recipientId, amount: 1e18, token: NATIVE});

    //     allocations[0] = allocation0;

    //     vm.warp(allocationStartTime + 1);
    //     vm.deal(pool_admin(), 1e20);
    //     vm.prank(pool_admin());
    //     allo().allocate{value: 1e17}(poolId, abi.encode(allocations));
    // }

    function test_distribute() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        (, DonationVotingMerkleDistributionDrip.StreamDistribution[] memory streamDistributions) =
            __getMerkleRootAndStreamDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.startPrank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));
        allo().fundPool(poolId, 3e18);
        vm.stopPrank();

        if (stream) {
            vm.expectEmit(false, false, false, true);
            emit BatchSetStreamSuccessful(pool_admin(), 3e18);

            vm.prank(address(allo()));
            strategy.distribute(
                new address[](0),
                abi.encode(new AddressDriver.StreamReceiver[](0), streamDistributions, 3e18, 60, 0, 0),
                pool_admin()
            );
        } else {
            vm.expectEmit(true, false, false, true);
            emit FundsDistributed(
                1e18,
                0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849,
                address(erc20),
                0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641
            );

            vm.expectEmit(true, false, false, true);
            emit FundsDistributed(
                2e18,
                0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99,
                address(erc20),
                0x4E0aB029b2128e740fA408a26aC5f314e769469f
            );

            vm.expectEmit(false, false, false, true);
            emit BatchPayoutSuccessful(pool_admin());

            vm.prank(address(allo()));
            strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
        }
    } // ✅

    function testRevert_distribute_twice_to_same_recipient() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        (, DonationVotingMerkleDistributionDrip.StreamDistribution[] memory streamDistributions) =
            __getMerkleRootAndStreamDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.startPrank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));
        allo().fundPool(poolId, 3e18);
        vm.stopPrank();

        if (stream) {
            vm.prank(address(allo()));
            strategy.distribute(
                new address[](0),
                abi.encode(new AddressDriver.StreamReceiver[](0), streamDistributions, 3e18, 60, 0, 0),
                pool_admin()
            );

            vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));

            vm.prank(address(allo()));
            strategy.distribute(
                new address[](0),
                abi.encode(new AddressDriver.StreamReceiver[](0), streamDistributions, 3e18, 60, 0, 0),
                pool_admin()
            );
        } else {
            vm.prank(address(allo()));
            strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());

            vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));

            vm.prank(address(allo()));
            strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
        }
    } // ✅

    function testRevert_distribute_wrongProof() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        (, DonationVotingMerkleDistributionDrip.StreamDistribution[] memory streamDistributions) =
            __getMerkleRootAndStreamDistributions();

        __register_accept_recipient();
        __register_recipient2();

        vm.warp(allocationEndTime + 1);

        vm.startPrank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));
        allo().fundPool(poolId, 3e18);
        vm.stopPrank();

        distributions[0].merkleProof[0] = bytes32(0);
        streamDistributions[0].merkleProof[0] = bytes32(0);

        if (stream) {
            vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));

            vm.prank(address(allo()));
            strategy.distribute(
                new address[](0),
                abi.encode(new AddressDriver.StreamReceiver[](0), streamDistributions, 3e18, 60, 0, 0),
                pool_admin()
            );
        } else {
            vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile1_anchor()));

            vm.prank(address(allo()));
            strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
        }
    } // ✅

    function testRevert_distribute_RECIPIENT_ERROR() public {
        (bytes32 merkleRoot, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions) =
            __getMerkleRootAndDistributions();

        (, DonationVotingMerkleDistributionDrip.StreamDistribution[] memory streamDistributions) =
            __getMerkleRootAndStreamDistributions();

        __register_accept_recipient();

        vm.warp(allocationEndTime + 1);

        vm.startPrank(pool_admin());
        strategy.updateDistribution(merkleRoot, Metadata(1, "metadata"));
        allo().fundPool(poolId, 3e18);
        vm.stopPrank();

        if (stream) {
            vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));

            vm.prank(address(allo()));
            strategy.distribute(
                new address[](0),
                abi.encode(new AddressDriver.StreamReceiver[](0), streamDistributions, 3e18, 60, 0, 0),
                pool_admin()
            );
        } else {
            vm.expectRevert(abi.encodeWithSelector(RECIPIENT_ERROR.selector, profile2_anchor()));

            vm.prank(address(allo()));
            strategy.distribute(new address[](0), abi.encode(distributions), pool_admin());
        }
    } // ✅

    /// ====================
    /// ===== Helpers ======
    /// ====================

    function __generateRecipientWithId(address _recipientId) internal returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress(), metadata);
    }

    function __register_recipient() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = strategy.registerRecipient(data, profile1_member1());
    }

    function __register_recipient2() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        vm.prank(address(allo()));
        bytes memory data = abi.encode(profile2_anchor(), randomAddress(), metadata);
        recipientId = strategy.registerRecipient(data, profile2_member1());
    }

    // TODO: Create a js version
    function __buildStatusRow(uint256 _recipientIndex, uint256 _status)
        internal
        pure
        returns (DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus memory applicationStatus)
    {
        uint256 colIndex = (_recipientIndex % 64) * 4;
        uint256 currentRow = 0;

        uint256 newRow = currentRow & ~(15 << colIndex);
        uint256 statusRow = newRow | (_status << colIndex);

        applicationStatus = DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus({
            index: _recipientIndex,
            statusRow: statusRow
        });
    }

    function __register_reject_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Rejected));

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusUpdated(0, statuses[0].statusRow, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses);
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Accepted));

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusUpdated(0, statuses[0].statusRow, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses);
    }

    function __register_accept_recipient2() internal returns (address recipientId) {
        recipientId = __register_recipient2();

        address[] memory recipientIds = new address[](1);
        recipientIds[0] = recipientId;

        DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[] memory statuses =
            new DonationVotingMerkleDistributionBaseStrategy.ApplicationStatus[](1);
        statuses[0] = __buildStatusRow(0, uint8(IStrategy.Status.Accepted));

        vm.expectEmit(false, false, false, true);
        emit RecipientStatusUpdated(0, statuses[0].statusRow, pool_admin());

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses);
    }

    function __getMerkleRootAndDistributions()
        internal
        pure
        returns (bytes32, DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory)
    {
        DonationVotingMerkleDistributionBaseStrategy.Distribution[] memory distributions =
            new DonationVotingMerkleDistributionBaseStrategy.Distribution[](2);

        DonationVotingMerkleDistributionBaseStrategy.Distribution memory distribution0 =
        DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 0,
            recipientId: 0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641,
            // recipientAddress: '0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849',
            amount: 1e18,
            merkleProof: new bytes32[](1)
        });
        distribution0.merkleProof[0] = 0x84de05a8497b125afa0c428b43e98c4378eb0f8eadae82538ee2b53e44bea806;

        DonationVotingMerkleDistributionBaseStrategy.Distribution memory distribution1 =
        DonationVotingMerkleDistributionBaseStrategy.Distribution({
            index: 1,
            recipientId: 0x4E0aB029b2128e740fA408a26aC5f314e769469f,
            // recipientAddress: '0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99',
            amount: 2e18,
            merkleProof: new bytes32[](1)
        });
        distribution1.merkleProof[0] = 0x4a3e9be6ab6503dfc6dd903fddcbabf55baef0c6aaca9f2cce2dc6d6350303f5;

        distributions[0] = distribution0;
        distributions[1] = distribution1;

        bytes32 merkleRoot = 0xbd6f4408f5de99e3401b90770fc87cc4e23b76c093f812d61df2bce4b881d88c;

        return (merkleRoot, distributions);

        //        distributions [
        //   [
        //     0,
        //     '0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641',
        //     '0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849',
        //     BigNumber { value: "1000000000000000000" }
        //   ],
        //   [
        //     1,
        //     '0x4E0aB029b2128e740fA408a26aC5f314e769469f',
        //     '0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99',
        //     BigNumber { value: "2000000000000000000" }
        //   ]
        // ]
        // tree.root 0xbd6f4408f5de99e3401b90770fc87cc4e23b76c093f812d61df2bce4b881d88c
        // proof0.root [
        //   '0x84de05a8497b125afa0c428b43e98c4378eb0f8eadae82538ee2b53e44bea806'
        // ]
        // proof1.root [
        //   '0x4a3e9be6ab6503dfc6dd903fddcbabf55baef0c6aaca9f2cce2dc6d6350303f5'
        // ]
    }

    function __getMerkleRootAndStreamDistributions()
        internal
        pure
        returns (bytes32, DonationVotingMerkleDistributionDrip.StreamDistribution[] memory)
    {
        DonationVotingMerkleDistributionDrip.StreamDistribution[] memory streamDistributions =
            new DonationVotingMerkleDistributionDrip.StreamDistribution[](2);

        DonationVotingMerkleDistributionDrip.StreamDistribution memory streamDistribution0 =
        DonationVotingMerkleDistributionDrip.StreamDistribution({
            index: 0,
            recipientId: 0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641,
            // recipientAddress: '0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849',
            amount: 1e18,
            merkleProof: new bytes32[](1)
        });
        streamDistribution0.merkleProof[0] = 0x84de05a8497b125afa0c428b43e98c4378eb0f8eadae82538ee2b53e44bea806;

        DonationVotingMerkleDistributionDrip.StreamDistribution memory streamDistribution1 =
        DonationVotingMerkleDistributionDrip.StreamDistribution({
            index: 1,
            recipientId: 0x4E0aB029b2128e740fA408a26aC5f314e769469f,
            // recipientAddress: '0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99',
            amount: 2e18,
            merkleProof: new bytes32[](1)
        });
        streamDistribution1.merkleProof[0] = 0x4a3e9be6ab6503dfc6dd903fddcbabf55baef0c6aaca9f2cce2dc6d6350303f5;

        // switched positions so that Streams receivers can be sorted
        streamDistributions[0] = streamDistribution1;
        streamDistributions[1] = streamDistribution0;

        bytes32 merkleRoot = 0xbd6f4408f5de99e3401b90770fc87cc4e23b76c093f812d61df2bce4b881d88c;

        return (merkleRoot, streamDistributions);

        //        distributions [
        //   [
        //     0,
        //     '0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641',
        //     '0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849',
        //     BigNumber { value: "1000000000000000000" }
        //   ],
        //   [
        //     1,
        //     '0x4E0aB029b2128e740fA408a26aC5f314e769469f',
        //     '0x0c73C6E53042522CDd21Bd8F1C63e14e66869E99',
        //     BigNumber { value: "2000000000000000000" }
        //   ]
        // ]
        // tree.root 0xbd6f4408f5de99e3401b90770fc87cc4e23b76c093f812d61df2bce4b881d88c
        // proof0.root [
        //   '0x84de05a8497b125afa0c428b43e98c4378eb0f8eadae82538ee2b53e44bea806'
        // ]
        // proof1.root [
        //   '0x4a3e9be6ab6503dfc6dd903fddcbabf55baef0c6aaca9f2cce2dc6d6350303f5'
        // ]
    }

    function __register_accept_recipient_allocate() internal returns (address) {
        address recipientId = __register_accept_recipient();
        address recipientId2 = __register_accept_recipient2();

        vm.warp(allocationStartTime + 1);
        vm.deal(randomAddress(), 1e18);
        vm.startPrank(randomAddress2());

        erc20.approve(address(strategy), type(uint256).max);
        uint256 balance = erc20.balanceOf(randomAddress2());

        DonationVotingMerkleDistributionDrip.Allocation[] memory allocations =
            new DonationVotingMerkleDistributionDrip.Allocation[](2);

        DonationVotingMerkleDistributionDrip.Allocation memory allocation0 = DonationVotingMerkleDistributionDrip
            .Allocation({recipientId: recipientId, amount: 50000, token: address(erc20)});

        DonationVotingMerkleDistributionDrip.Allocation memory allocation1 = DonationVotingMerkleDistributionDrip
            .Allocation({recipientId: recipientId2, amount: 50000, token: address(erc20)});

        allocations[0] = allocation0;
        allocations[1] = allocation1;

        vm.expectEmit(false, false, false, true);
        emit Allocated(recipientId, 50000, address(erc20), randomAddress2());

        vm.expectEmit(false, false, false, true);
        emit Allocated(recipientId2, 50000, address(erc20), randomAddress2());

        vm.expectEmit(false, false, false, true);
        emit BatchAllocationSuccessful(randomAddress2());

        allo().allocate(poolId, abi.encode(allocations));
        vm.stopPrank();

        assertEq(erc20.balanceOf(randomAddress2()), balance - (50000 + 50000), "Invalid balance 1");
        assertEq(erc20.balanceOf(recipientAddress()), 50000, "Invalid balance 2");
        assertEq(erc20.balanceOf(randomAddress()), 50000, "Invalid balance 3");
        // assertEq(erc20.balanceOf(address(strategy)), 0, "Invalid balance 4");

        return recipientId;
    }

    // test to allocate tokens that exceeds balance
    // use if statement to check if the main token is Native or Erc-20
}
