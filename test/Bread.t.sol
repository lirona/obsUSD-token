pragma solidity ^0.8.13;

import {Bread} from "../src/Bread.sol";
import {Test} from "forge-std/Test.sol";
import {EIP173Proxy} from "../src/proxy/EIP173Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface Depositable {
    function deposit() external payable;
}
interface IERC20Depositable is Depositable ,IERC20  {}


contract BreadTest is Test {
  IERC20 public dai;
  IERC20 public aDai;
  address public constant admin =
        0x6A148b997e6651237F2fCfc9E30330a6480519f0;
  address public constant signer =
        0x4B5BaD436CcA8df3bD39A095b84991fAc9A226F1;
  address public constant DAI_HOLDER = 
        0x5Fc0c8BeACfD0a0259B656eabcfE5b39fDe834cc;
  EIP173Proxy public breadProxy;
  Bread public bread;

  function setUp() public {
    emit log("Setup...");
    vm.startPrank(admin);
    address breadAddress = address(
      new Bread(
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
        0x794a61358D6845594F94dc1DB02A252b5b4814aD,
        0x929EC64c34a17401F460460D4B9390518E5B473e
      )
    );
    emit log("Contract deploed...");

    breadProxy = new EIP173Proxy(
      breadAddress,
      address(this),
      bytes("")
    );

    emit log("Proxy deploed...");

    vm.stopPrank();
    bread = Bread(address(breadProxy));
    vm.startPrank(admin);
    bread.initialize("Breadchain Stablecoin", "BREAD");
    vm.stopPrank();

    dai = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    aDai = IERC20(0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE);

    emit log("DAI and aDAI addresses set");
    // get some DAI from some acct
    vm.startPrank(DAI_HOLDER);
    uint256 daiHolderBalance = dai.balanceOf(DAI_HOLDER);
    emit log_uint(daiHolderBalance);
    dai.transfer(admin, daiHolderBalance/4);
    dai.transfer(signer, daiHolderBalance/4);
    emit log_uint(dai.balanceOf(admin));
    emit log_uint(dai.balanceOf(signer));
    vm.stopPrank();

    vm.deal(admin, 10 ether);
  }
  function test_mint() public {
    uint256 daiBefore = dai.balanceOf(signer);
    uint256 breadBefore = bread.balanceOf(signer);

    vm.prank(signer);
    dai.approve(address(bread), daiBefore / 10);
    bread.mint(daiBefore / 10, signer);

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
    dai.approve(address(bread), daiBeforeAdmin / 10);
    bread.mint(daiBeforeAdmin / 10, signer);

    uint256 daiAfterAdmin = dai.balanceOf(admin);
    uint256 breadAfterAdmin = bread.balanceOf(admin);
    uint256 breadFinal = bread.balanceOf(signer);

    assertEq(breadBeforeAdmin, 0);
    assertEq(breadBeforeAdmin, breadAfterAdmin);
    assertGt(daiBeforeAdmin, daiAfterAdmin);
    assertGt(breadFinal, breadAfter);
    assertEq(breadFinal, breadAfter + (daiBeforeAdmin - daiAfterAdmin));
  }
}
