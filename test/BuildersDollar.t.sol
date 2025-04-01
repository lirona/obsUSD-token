// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BuilderDollar} from "src/BuilderDollar.sol";
import {Test} from "forge-std/Test.sol";
import {EIP173Proxy} from "src/proxy/EIP173Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Depositable {
    function deposit() external payable;
}

interface IERC20Depositable is Depositable, IERC20 {}

contract BuilderDollarTest is Test {
    address public constant daiAddress = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address public constant aDaiAddress = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;
    address public constant poolAddress = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address public constant rewardsAddress = 0x929EC64c34a17401F460460D4B9390518E5B473e;
    address public constant admin = 0x6A148b997e6651237F2fCfc9E30330a6480519f0;
    address public constant signer = 0x4B5BaD436CcA8df3bD39A095b84991fAc9A226F1;
    address public constant DAI_HOLDER = 0x48A63097E1Ac123b1f5A8bbfFafA4afa8192FaB0;
    IERC20 public dai = IERC20(daiAddress);
    IERC20 public aDai = IERC20(aDaiAddress);
    EIP173Proxy public buildersDollarProxy;
    BuilderDollar public buildersDollar;

    function setUp() public {
        // vm.rollFork(125665270);

        vm.startPrank(admin);
        address buildersDollarAddress = address(new BuilderDollar());

        buildersDollarProxy = new EIP173Proxy(buildersDollarAddress, address(this), bytes(""));

        vm.stopPrank();
        buildersDollar = BuilderDollar(address(buildersDollarProxy));
        vm.startPrank(admin);
        buildersDollar.initialize(
            address(0x69),
            daiAddress,
            aDaiAddress,
            poolAddress,
            "buildersDollarchain Stablecoin",
            "buildersDollar"
        );
        vm.stopPrank();
        address proxyAdmin = buildersDollarProxy.proxyAdmin();
        vm.prank(proxyAdmin);
        buildersDollarProxy.transferProxyAdmin(admin);

        dai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        aDai = IERC20(0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE);

        // get some DAI from some acct
        vm.startPrank(DAI_HOLDER);
        uint256 daiHolderBalance = dai.balanceOf(DAI_HOLDER);
        dai.transfer(admin, daiHolderBalance / 4);
        dai.transfer(signer, daiHolderBalance / 4);
        vm.stopPrank();

        emit log_uint(dai.balanceOf(signer));

        vm.deal(admin, 10 ether);
    }

    function test_mint_burn() public {
        uint256 daiBefore = dai.balanceOf(signer);
        uint256 buildersDollarBefore = buildersDollar.balanceOf(signer);

        uint256 mintAmt = daiBefore / 10;

        vm.prank(signer);
        dai.approve(address(buildersDollar), mintAmt);
        vm.prank(signer);
        buildersDollar.mint(mintAmt, signer);

        uint256 daiAfter = dai.balanceOf(signer);
        uint256 buildersDollarAfter = buildersDollar.balanceOf(signer);

        assertEq(buildersDollarBefore, 0);
        assertGt(daiBefore, daiAfter);
        assertGt(buildersDollarAfter, buildersDollarBefore);
        assertEq(buildersDollarAfter, daiBefore - daiAfter);

        // mint to another
        uint256 daiBeforeAdmin = dai.balanceOf(admin);
        uint256 buildersDollarBeforeAdmin = buildersDollar.balanceOf(admin);

        vm.prank(admin);
        dai.approve(address(buildersDollar), mintAmt);
        vm.prank(admin);
        buildersDollar.mint(mintAmt / 10, signer);

        uint256 daiAfterAdmin = dai.balanceOf(admin);
        uint256 buildersDollarAfterAdmin = buildersDollar.balanceOf(admin);
        uint256 buildersDollarFinal = buildersDollar.balanceOf(signer);

        assertEq(buildersDollarBeforeAdmin, 0);
        assertEq(buildersDollarBeforeAdmin, buildersDollarAfterAdmin);
        assertGt(daiBeforeAdmin, daiAfterAdmin);
        assertGt(buildersDollarFinal, buildersDollarAfter);
        assertEq(buildersDollarFinal, buildersDollarAfter + (daiBeforeAdmin - daiAfterAdmin));
        vm.stopPrank();

        uint256 aaDaiBalance = aDai.balanceOf(address(buildersDollar));
        emit log_uint(aaDaiBalance);
        // burn
        uint256 aDaiBalance = aDai.balanceOf(address(buildersDollar));
        assertGt(aDaiBalance, 0);

        vm.prank(admin);
        vm.expectRevert("BuilderDollar: cannot withdraw collateral");
        buildersDollar.rescueToken(address(aDai), 1);

        uint256 supplyBefore = buildersDollar.totalSupply();
        uint256 burn_daiBefore = dai.balanceOf(admin);
        vm.prank(signer);
        buildersDollar.burn(supplyBefore, admin);
        uint256 supplyAfter = buildersDollar.totalSupply();
        uint256 burn_daiAfter = dai.balanceOf(admin);

        assertGt(supplyBefore, supplyAfter);
        assertEq(supplyAfter, 0);
        assertGt(burn_daiAfter, burn_daiBefore);
        assertEq(burn_daiAfter, burn_daiBefore + supplyBefore);
    }

    function test_protect_owner_functions() public {
        vm.prank(signer);
        vm.expectRevert();
        buildersDollar.rescueToken(address(aDai), 1);
    }

    function test_resecue() public {
        uint256 bb_before = dai.balanceOf(address(buildersDollar));
        uint256 signerDai = dai.balanceOf(signer);
        vm.prank(signer);
        dai.transfer(address(buildersDollar), signerDai);
        uint256 bb_after = dai.balanceOf(address(buildersDollar));
        assertEq(bb_before, 0);
        assertGt(bb_after, bb_before);

        uint256 admin_before = dai.balanceOf(admin);
        vm.prank(admin);
        buildersDollar.rescueToken(address(dai), bb_after);
        uint256 admin_after = dai.balanceOf(admin);
        assertGt(admin_after, admin_before);
        assertEq(admin_after, admin_before + bb_after);
    }

    function test_upgradeablity() public {
        vm.prank(signer);
        vm.expectRevert("NOT_AUTHORIZED");
        buildersDollarProxy.transferProxyAdmin(DAI_HOLDER);

        vm.prank(signer);
        vm.expectRevert("NOT_AUTHORIZED");
        buildersDollarProxy.upgradeTo(DAI_HOLDER);

        vm.prank(admin);
        buildersDollarProxy.upgradeTo(DAI_HOLDER);

        vm.prank(admin);
        buildersDollarProxy.transferProxyAdmin(DAI_HOLDER);

        address proxyAdmin = buildersDollarProxy.proxyAdmin();
        assertEq(proxyAdmin, DAI_HOLDER);
    }

    function test_yield_accuumulation() public {
        uint256 balanceOfDAI_HOLDER = dai.balanceOf(DAI_HOLDER);
        assertGt(balanceOfDAI_HOLDER, 0);
        vm.prank(DAI_HOLDER);
        dai.approve(address(buildersDollar), balanceOfDAI_HOLDER);
        vm.prank(DAI_HOLDER);
        buildersDollar.mint(balanceOfDAI_HOLDER, DAI_HOLDER);
        vm.rollFork(127665270);
        uint256 yieldAccured = buildersDollar.yieldAccrued();
        assertGt(yieldAccured, 0);
    }
}
