// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MockReveiver {
    error TargetRevert();

    event Target(address indexed from);

    function target() external {
        emit Target(msg.sender);
    }

    function targetRevert() external pure {
        revert TargetRevert();
    }
}
