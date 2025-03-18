// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {BuildersDollar} from "../src/BuildersDollar.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {EIP173ProxyWithReceive} from "../src/vendor/EIP173ProxyWithReceive.sol";

contract DeployBuildersDollar is Script {
    using stdJson for string;

    function run() external {
        // Load config
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/config/optimism/deploy-config.json");
        string memory json = vm.readFile(path);

        // Parse config
        address dai = json.readAddress(".dai");
        address aDai = json.readAddress(".aDai");
        address aavePool = json.readAddress(".aavePool");
        address aaveRewards = json.readAddress(".aaveRewards");
        string memory name = json.readString(".name");
        string memory symbol = json.readString(".symbol");

        // Deploy
        vm.broadcast();
        BuildersDollar dollar = new BuildersDollar();
        new EIP173ProxyWithReceive(
            address(dollar),
            address(this),
            abi.encodeWithSelector(dollar.initialize.selector, dai, aDai, aavePool, aaveRewards, name, symbol)
        );

        // Initialize
    }
}
