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
        0x23b4f73FB31e89B27De17f9c5DE2660cc1FB0CdF;
  address public constant signer =
        0x4B5BaD436CcA8df3bD39A095b84991fAc9A226F1;
  address public constant DAI_HOLDER = 
        0x0405e31AB5C379BCB710D34e500E009bbB79f584;
  EIP173Proxy public breadProxy;
  Bread public bread;

  function setUp() public {
    address breadAddress = address(
      new Bread(
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
        0x794a61358D6845594F94dc1DB02A252b5b4814aD,
        0x929EC64c34a17401F460460D4B9390518E5B473e
      )
    );
    breadProxy = new EIP173Proxy(
      breadAddress,
      address(this),
      bytes("")
    );
    bread = Bread(address(breadProxy));

    dai = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    aDai = IERC20(0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE);

    // get some DAI from some acct
    vm.startPrank(DAI_HOLDER);
    dai.transfer(admin, dai.balanceOf(DAI_HOLDER)/4);
    dai.transfer(signer, dai.balanceOf(DAI_HOLDER)/4);
    vm.stopPrank();

    vm.deal(signer, 10 ether);
    vm.startPrank(signer);
    (bool sent, ) = admin.call{value: 10 ether}("");
    require(sent, "ETH transfer failed");
    vm.stopPrank();
  }
}
