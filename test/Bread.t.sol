// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Bread} from "../src/Bread.sol";
import {Test} from "forge-std/Test.sol";
import {EIP173Proxy} from "../src/proxy/EIP173Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Depositable {
    function deposit() external payable;
}

interface IERC20Depositable is Depositable, IERC20 {}

contract BreadTest is Test {
    IERC20 public dai;
    IERC20 public aDai;
    address public constant admin = 0x6A148b997e6651237F2fCfc9E30330a6480519f0;
    address public constant signer = 0x4B5BaD436CcA8df3bD39A095b84991fAc9A226F1;
    address public constant DAI_HOLDER = 0x48A63097E1Ac123b1f5A8bbfFafA4afa8192FaB0;
    EIP173Proxy public breadProxy;
    Bread public bread;

    function setUp() public {
        vm.startPrank(admin);
        address breadAddress = address(
            new Bread(
                0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
                0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC,
                0x794a61358D6845594F94dc1DB02A252b5b4814aD,
                0x929EC64c34a17401F460460D4B9390518E5B473e
            )
        );

        breadProxy = new EIP173Proxy(breadAddress, address(this), bytes(""));

        vm.stopPrank();
        bread = Bread(address(breadProxy));
        vm.startPrank(admin);
        bread.initialize("Breadchain Stablecoin", "BREAD");
        vm.stopPrank();
        address proxyAdmin = breadProxy.proxyAdmin();
        vm.prank(proxyAdmin);
        breadProxy.transferProxyAdmin(admin);

        dai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        aDai = IERC20(0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC);

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
        uint256 breadBefore = bread.balanceOf(signer);

        uint256 mintAmt = daiBefore / 10;

        vm.prank(signer);
        dai.approve(address(bread), mintAmt);
        vm.prank(signer);
        bread.mint(mintAmt, signer);

        uint256 daiAfter = dai.balanceOf(signer);
        uint256 breadAfter = bread.balanceOf(signer);

        assertEq(breadBefore, 0);
        assertGt(daiBefore, daiAfter);
        assertGt(breadAfter, breadBefore);
        assertEq(breadAfter, daiBefore - daiAfter);

        // mint to another
        uint256 daiBeforeAdmin = dai.balanceOf(admin);
        uint256 breadBeforeAdmin = bread.balanceOf(admin);

        vm.prank(admin);
        dai.approve(address(bread), mintAmt);
        vm.prank(admin);
        bread.mint(mintAmt / 10, signer);

        uint256 daiAfterAdmin = dai.balanceOf(admin);
        uint256 breadAfterAdmin = bread.balanceOf(admin);
        uint256 breadFinal = bread.balanceOf(signer);

        assertEq(breadBeforeAdmin, 0);
        assertEq(breadBeforeAdmin, breadAfterAdmin);
        assertGt(daiBeforeAdmin, daiAfterAdmin);
        assertGt(breadFinal, breadAfter);
        assertEq(breadFinal, breadAfter + (daiBeforeAdmin - daiAfterAdmin));
        vm.stopPrank();

        uint256 aaDaiBalance = aDai.balanceOf(address(bread));
        emit log_uint(aaDaiBalance);
        // burn
        uint256 aDaiBalance = aDai.balanceOf(address(bread));
        assertGt(aDaiBalance, 0);

        vm.prank(admin);
        vm.expectRevert("Bread: cannot withdraw collateral");
        bread.rescueToken(address(aDai), 1);

        uint256 supplyBefore = bread.totalSupply();
        uint256 burn_daiBefore = dai.balanceOf(admin);
        vm.prank(signer);
        bread.burn(supplyBefore, admin);
        uint256 supplyAfter = bread.totalSupply();
        uint256 burn_daiAfter = dai.balanceOf(admin);

        assertGt(supplyBefore, supplyAfter);
        assertEq(supplyAfter, 0);
        assertGt(burn_daiAfter, burn_daiBefore);
        assertEq(burn_daiAfter, burn_daiBefore + supplyBefore);
    }

    function test_protect_owner_functions() public {
        vm.prank(signer);
        vm.expectRevert();
        bread.rescueToken(address(aDai), 1);
    }

    function test_resecue() public {
        uint256 bb_before = dai.balanceOf(address(bread));
        uint256 signerDai = dai.balanceOf(signer);
        vm.prank(signer);
        dai.transfer(address(bread), signerDai);
        uint256 bb_after = dai.balanceOf(address(bread));
        assertEq(bb_before, 0);
        assertGt(bb_after, bb_before);

        uint256 admin_before = dai.balanceOf(admin);
        vm.prank(admin);
        bread.rescueToken(address(dai), bb_after);
        uint256 admin_after = dai.balanceOf(admin);
        assertGt(admin_after, admin_before);
        assertEq(admin_after, admin_before + bb_after);
    }

    function test_upgradeablity() public {
        vm.prank(signer);
        vm.expectRevert("NOT_AUTHORIZED");
        breadProxy.transferProxyAdmin(DAI_HOLDER);

        vm.prank(signer);
        vm.expectRevert("NOT_AUTHORIZED");
        breadProxy.upgradeTo(DAI_HOLDER);

        vm.prank(admin);
        breadProxy.upgradeTo(DAI_HOLDER);

        vm.prank(admin);
        breadProxy.transferProxyAdmin(DAI_HOLDER);

        address proxyAdmin = breadProxy.proxyAdmin();
        assertEq(proxyAdmin, DAI_HOLDER);
    }
}
