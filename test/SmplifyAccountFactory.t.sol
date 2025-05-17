// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SmplifyAccount, Call} from "src/SmplifyAccount.sol";
import {SmplifyAccountFactory} from "src/SmplifyAccountFactory.sol";
import {MockReveiver} from "test/MockReveiver.sol";

contract SmplifyAccountFactoryTest is Test {
    error Unauthorized();
    error Multicall3CallFailed(uint256);

    SmplifyAccountFactory public smplifyAccountFactory;
    SmplifyAccount public smplifyAccount;
    MockReveiver public mock;

    function setUp() public {
        smplifyAccountFactory = new SmplifyAccountFactory();
        address account = smplifyAccountFactory.deployAccount(address(this));
        smplifyAccount = SmplifyAccount(account);
        mock = new MockReveiver();
    }

    function test_notOwner() public {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({target: address(0x1), callData: "0x"});
        vm.startPrank(address(0x1));
        vm.expectRevert(Unauthorized.selector);
        smplifyAccount.aggregate(calls);
        vm.stopPrank();
    }

    function test_aggregate() public {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({target: address(mock), callData: abi.encodeCall(MockReveiver.target, ())});
        smplifyAccount.aggregate(calls);
    }

    function test_aggregate_revert() public {
        Call[] memory calls = new Call[](1);
        vm.expectRevert(abi.encodeWithSelector(Multicall3CallFailed.selector, uint256(0)));
        calls[0] = Call({target: address(mock), callData: abi.encodeCall(MockReveiver.targetRevert, ())});
        smplifyAccount.aggregate(calls);
    }
}
