// // SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface AddressDriver {
    type StreamConfig is uint256;

    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event NewAdminProposed(address indexed currentAdmin, address indexed newAdmin);
    event Paused(address indexed pauser);
    event PauserGranted(address indexed pauser, address indexed admin);
    event PauserRevoked(address indexed pauser, address indexed admin);
    event Unpaused(address indexed pauser);
    event Upgraded(address indexed implementation);

    struct AccountMetadata {
        bytes32 key;
        bytes value;
    }

    struct SplitsReceiver {
        uint256 accountId;
        uint32 weight;
    }

    struct StreamReceiver {
        uint256 accountId;
        StreamConfig config;
    }

    function acceptAdmin() external;
    function admin() external view returns (address);
    function allPausers() external view returns (address[] memory pausersList);
    function calcAccountId(address addr) external view returns (uint256 accountId);
    function collect(address erc20, address transferTo) external returns (uint128 amt);
    function drips() external view returns (address);
    function driverId() external view returns (uint32);
    function emitAccountMetadata(AccountMetadata[] memory accountMetadata) external;
    function give(uint256 receiver, address erc20, uint128 amt) external;
    function grantPauser(address pauser) external;
    function implementation() external view returns (address);
    function isPaused() external view returns (bool);
    function isPauser(address pauser) external view returns (bool isAddrPauser);
    function isTrustedForwarder(address forwarder) external view returns (bool);
    function pause() external;
    function proposeNewAdmin(address newAdmin) external;
    function proposedAdmin() external view returns (address);
    function proxiableUUID() external view returns (bytes32);
    function renounceAdmin() external;
    function revokePauser(address pauser) external;
    function setSplits(SplitsReceiver[] memory receivers) external;
    function setStreams(
        address erc20,
        StreamReceiver[] memory currReceivers,
        int128 balanceDelta,
        StreamReceiver[] memory newReceivers,
        uint32 maxEndHint1,
        uint32 maxEndHint2,
        address transferTo
    ) external returns (int128 realBalanceDelta);
    function unpause() external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}
