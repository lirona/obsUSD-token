// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";
import {BuilderDollar} from "src/BuilderDollar.sol";
import {EIP173ProxyWithReceive} from "src/vendor/EIP173ProxyWithReceive.sol";

// forge script DeployBuilderDollar --rpc-url https://opt-mainnet.g.alchemy.com/v2/9cUpmp6SkMdbq52bFYkOHAY6E4lm_pjZ --private-key d13f8d0bc353c92c26d97cfcc4282b581a38bc9574b773d03c07a7445c405e17 --broadcast --verify --etherscan-api-key A396MX9PHYZBU27EYJ51UZ43T44M16ESSJ --slow --chain optimism -vvvvv


contract DeployBuilderDollar is Script {
    using stdJson for string;

    function run() external {
        // Load config
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/config/optimism/deploy-config.json");
        string memory json = vm.readFile(path);

        // Parse config
        address bread = json.readAddress(".bread");
        address dai = json.readAddress(".dai");
        address aDai = json.readAddress(".aDai");
        address aavePool = json.readAddress(".aavePool");
        string memory name = json.readString(".name");
        string memory symbol = json.readString(".symbol");

        // Deploy
        vm.broadcast();
        BuilderDollar dollar = new BuilderDollar();
        new EIP173ProxyWithReceive(
            address(dollar),
            address(this),
            abi.encodeWithSelector(dollar.initialize.selector, bread, dai, aDai, aavePool, name, symbol)
        );
    }
}
