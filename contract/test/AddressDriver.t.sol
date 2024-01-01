// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import {Caller} from "drip-network/Caller.sol";
import {AddressDriver} from "drip-network/AddressDriver.sol";
import {
    AccountMetadata,
    Drips,
    StreamConfigImpl,
    StreamsHistory,
    StreamReceiver,
    SplitsReceiver
} from "drip-network/Drips.sol";
import {ManagedProxy} from "drip-network/Managed.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20, ERC20PresetFixedSupply} from "openzeppelin/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract AddressDriverTest is Test {
    Drips internal drips;
    Caller internal caller;
    AddressDriver internal driver;
    IERC20 internal erc20;

    address internal admin = address(1);
    uint256 internal thisId;
    address internal user = address(2);
    address internal user2 = address(3);
    uint256 internal accountId;
    uint256 internal accountId2;

    function setUp() public {
        Drips dripsLogic = new Drips(10);
        drips = Drips(address(new ManagedProxy(dripsLogic, address(this))));

        caller = new Caller();

        // Make AddressDriver's driver ID non-0 to test if it's respected by AddressDriver
        drips.registerDriver(address(1));
        drips.registerDriver(address(1));
        uint32 driverId = drips.registerDriver(address(this));
        AddressDriver driverLogic = new AddressDriver(drips, address(caller), driverId);
        driver = AddressDriver(address(new ManagedProxy(driverLogic, admin)));
        drips.updateDriverAddress(driverId, address(driver));

        thisId = driver.calcAccountId(address(this));
        accountId = driver.calcAccountId(user);
        accountId2 = driver.calcAccountId(user2);

        erc20 = new ERC20PresetFixedSupply("test", "test", type(uint136).max, address(this));
        erc20.approve(address(driver), type(uint256).max);
        erc20.transfer(user, erc20.totalSupply() / 100);
        vm.prank(user);
        erc20.approve(address(driver), type(uint256).max);
    }

    function testCollect() public {
        uint128 amt = 5;
        vm.prank(user);
        driver.give(thisId, erc20, amt);
        drips.split(thisId, erc20, new SplitsReceiver[](0));
        uint256 balance = erc20.balanceOf(address(this));

        uint128 collected = driver.collect(erc20, address(this));

        assertEq(collected, amt, "Invalid collected");
        assertEq(erc20.balanceOf(address(this)), balance + amt, "Invalid balance");
        assertEq(erc20.balanceOf(address(drips)), 0, "Invalid Drips balance");
    }

    function testCollectTransfersFundsToTheProvidedAddress() public {
        uint128 amt = 5;
        vm.prank(user);
        driver.give(thisId, erc20, amt);
        drips.split(thisId, erc20, new SplitsReceiver[](0));
        address transferTo = address(1234);

        uint128 collected = driver.collect(erc20, transferTo);

        assertEq(collected, amt, "Invalid collected");
        assertEq(erc20.balanceOf(transferTo), amt, "Invalid balance");
        assertEq(erc20.balanceOf(address(drips)), 0, "Invalid Drips balance");
    }

    function testGive() public {
        uint128 amt = 5;
        uint256 balance = erc20.balanceOf(address(this));

        driver.give(accountId, erc20, amt);

        assertEq(erc20.balanceOf(address(this)), balance - amt, "Invalid balance");
        assertEq(erc20.balanceOf(address(drips)), amt, "Invalid Drips balance");
        assertEq(drips.splittable(accountId, erc20), amt, "Invalid received amount");
    }

    function testReceivableStreams() public {
        uint32 duration = 3600 * 24 * 3;
        uint128 decimals = 1000_000_000_000_000_000; // 18
        uint128 amt = 20_000 * decimals;
        uint128 amt1 = 1 * decimals;
        uint128 amt2 = 10_000 * decimals;

        // Top-up
        StreamReceiver[] memory receivers = new StreamReceiver[](2);
        receivers[0] = StreamReceiver(accountId, StreamConfigImpl.create(0, calculateFlowRate(amt1, 60), 0, 60));
        receivers[1] =
            StreamReceiver(accountId2, StreamConfigImpl.create(0, calculateFlowRate(2400000000000, 60), 0, 60));
        uint256 balance = erc20.balanceOf(address(this));

        int128 realBalanceDelta =
            driver.setStreams(erc20, new StreamReceiver[](0), int128(amt), receivers, 0, 0, address(this));

        assertEq(erc20.balanceOf(address(this)), balance - amt, "Invalid balance after top-up");
        assertEq(erc20.balanceOf(address(drips)), amt, "Invalid Drips balance after top-up");
        (,,, uint128 streamsBalance,) = drips.streamsState(thisId, erc20);
        assertEq(streamsBalance, amt, "Invalid streams balance after top-up");
        assertEq(realBalanceDelta, int128(amt), "Invalid streams balance delta after top-up");
        (bytes32 streamsHash,,,,) = drips.streamsState(thisId, erc20);
        assertEq(streamsHash, drips.hashStreams(receivers), "Invalid streams hash after top-up");

        vm.warp(block.timestamp + (3600 * 24 * 60));

        // accountId
        uint32 cycles = drips.receivableStreamsCycles(accountId, erc20);
        uint128 receivableAmt = drips.receiveStreamsResult(accountId, erc20, cycles);
        uint128 receivedAmt = drips.receiveStreams(accountId, erc20, cycles);
        console.logUint(cycles);
        console.logUint(receivableAmt);
        console.logUint(receivedAmt);

        // accountId2
        uint32 cycles2 = drips.receivableStreamsCycles(accountId2, erc20);
        uint128 receivableAmt2 = drips.receiveStreamsResult(accountId2, erc20, cycles2);
        uint128 receivedAmt2 = drips.receiveStreams(accountId2, erc20, cycles2);
        console.logUint(cycles2);
        console.logUint(receivableAmt2);
        console.logUint(receivedAmt2);

        vm.startPrank(user);
        drips.split(accountId, erc20, new SplitsReceiver[](0));
        driver.collect(erc20, user);
        vm.stopPrank();

        vm.startPrank(user2);
        drips.split(accountId2, erc20, new SplitsReceiver[](0));
        driver.collect(erc20, user2);
        vm.stopPrank();

        uint256 balance2 = erc20.balanceOf(user2);
        console.logUint(balance2 / 1000_000_000_000_000_000);
    }

    function testSetStreams2() public {
        uint128 amt = 5;

        // Top-up
        StreamReceiver[] memory receivers = new StreamReceiver[](1);
        receivers[0] = StreamReceiver(accountId, StreamConfigImpl.create(0, drips.minAmtPerSec(), 0, 0));
        uint256 balance = erc20.balanceOf(address(this));

        int128 realBalanceDelta =
            driver.setStreams(erc20, new StreamReceiver[](0), int128(amt), receivers, 0, 0, address(this));

        assertEq(erc20.balanceOf(address(this)), balance - amt, "Invalid balance after top-up");
        assertEq(erc20.balanceOf(address(drips)), amt, "Invalid Drips balance after top-up");
        (,,, uint128 streamsBalance,) = drips.streamsState(thisId, erc20);
        assertEq(streamsBalance, amt, "Invalid streams balance after top-up");
        assertEq(realBalanceDelta, int128(amt), "Invalid streams balance delta after top-up");
        (bytes32 streamsHash,,,,) = drips.streamsState(thisId, erc20);
        assertEq(streamsHash, drips.hashStreams(receivers), "Invalid streams hash after top-up");

        // Withdraw
        balance = erc20.balanceOf(address(user));

        realBalanceDelta = driver.setStreams(erc20, receivers, -int128(amt), receivers, 0, 0, address(user));

        assertEq(erc20.balanceOf(address(user)), balance + amt, "Invalid balance after withdrawal");
        assertEq(erc20.balanceOf(address(drips)), 0, "Invalid Drips balance after withdrawal");
        (,,, streamsBalance,) = drips.streamsState(thisId, erc20);
        assertEq(streamsBalance, 0, "Invalid streams balance after withdrawal");
        assertEq(realBalanceDelta, -int128(amt), "Invalid streams balance delta after withdrawal");
    }

    function testSetStreamsDecreasingBalanceTransfersFundsToTheProvidedAddress() public {
        uint128 amt = 5;
        StreamReceiver[] memory receivers = new StreamReceiver[](0);
        driver.setStreams(erc20, receivers, int128(amt), receivers, 0, 0, address(this));
        address transferTo = address(1234);

        int128 realBalanceDelta = driver.setStreams(erc20, receivers, -int128(amt), receivers, 0, 0, transferTo);

        assertEq(erc20.balanceOf(transferTo), amt, "Invalid balance");
        assertEq(erc20.balanceOf(address(drips)), 0, "Invalid Drips balance");
        (,,, uint128 streamsBalance,) = drips.streamsState(thisId, erc20);
        assertEq(streamsBalance, 0, "Invalid streams balance");
        assertEq(realBalanceDelta, -int128(amt), "Invalid streams balance delta");
    }

    function testSetSplits() public {
        SplitsReceiver[] memory receivers = new SplitsReceiver[](1);
        receivers[0] = SplitsReceiver(accountId, 1);

        driver.setSplits(receivers);

        bytes32 actual = drips.splitsHash(thisId);
        bytes32 expected = drips.hashSplits(receivers);
        assertEq(actual, expected, "Invalid splits hash");
    }

    function testEmitAccountMetadata() public {
        AccountMetadata[] memory accountMetadata = new AccountMetadata[](1);
        accountMetadata[0] = AccountMetadata("key", "value");
        driver.emitAccountMetadata(accountMetadata);
    }

    function testForwarderIsTrusted() public {
        vm.prank(user);
        caller.authorize(address(this));
        assertEq(drips.splittable(accountId, erc20), 0, "Invalid splittable before give");
        uint128 amt = 10;

        bytes memory giveData = abi.encodeCall(driver.give, (accountId, erc20, amt));
        caller.callAs(user, address(driver), giveData);

        assertEq(drips.splittable(accountId, erc20), amt, "Invalid splittable after give");
    }

    modifier canBePausedTest() {
        vm.prank(admin);
        driver.pause();
        vm.expectRevert("Contract paused");
        _;
    }

    function testCollectCanBePaused() public canBePausedTest {
        driver.collect(erc20, user);
    }

    function testGiveCanBePaused() public canBePausedTest {
        driver.give(accountId, erc20, 0);
    }

    function testSetStreamsCanBePaused() public canBePausedTest {
        driver.setStreams(erc20, new StreamReceiver[](0), 0, new StreamReceiver[](0), 0, 0, user);
    }

    function testSetSplitsCanBePaused() public canBePausedTest {
        driver.setSplits(new SplitsReceiver[](0));
    }

    function testEmitAccountMetadataCanBePaused() public canBePausedTest {
        driver.emitAccountMetadata(new AccountMetadata[](0));
    }

    function calculateFlowRate(uint128 tokensToSend_, uint32 streamingDurationInSeconds_) internal returns (uint160) {
        // Calculate Precision Token Unit flow rate per second
        uint160 flowRate = tokensToSend_ * 10 ** 9 / streamingDurationInSeconds_;
        return flowRate;
    }
}
