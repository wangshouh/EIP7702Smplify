// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SmplifyAccount} from "./SmplifyAccount.sol";

contract SmplifyAccountFactory {
    SmplifyAccount public smplifyAccount;

    function deployAccount(address _owner) public returns (address) {
        smplifyAccount = new SmplifyAccount(_owner);
        return address(smplifyAccount);
    }
}
