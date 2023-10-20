// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

interface INounsBidScheduler {
    error InsufficientBalance(uint256 required, uint256 available);
    error InsufficientReason();
    error InsufficientExecutionPath();

    event Given(address indexed sender, uint256 value);
    event Used(
        address indexed sender,
        address indexed onBehalf,
        uint256 value,
        uint256 nounId
    );
    event Taken(
        address indexed sender,
        address indexed onBehalf,
        address asset,
        uint256 value
    );
}
