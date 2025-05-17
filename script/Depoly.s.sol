// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {SmplifyAccountFactory} from "src/SmplifyAccountFactory.sol";

contract DeployScript is Script {
    function run() public returns (SmplifyAccountFactory factory) {
        vm.createSelectFork("Base");
        vm.startBroadcast(vm.envUint("DEPLOY_PRIVATE"));

        factory = new SmplifyAccountFactory();
        // vm.expectReturn(address(factory));
        vm.stopBroadcast();
    }
}