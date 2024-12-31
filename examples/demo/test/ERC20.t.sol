pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";

import { IERC20Program, createERC20Program } from "yol-build/Contracts.sol";


contract ERC20ProgramTest is Test {
  IERC20Program private token;
  address constant ALICE = address(41);
  address constant BOB = address(42);

  constructor () {
    token = createERC20Program();
  }

  function testBalanceOfIsViewFunction() external view {
    assertEq(token.balanceOf(ALICE), 0);
  }

  function testMintAndTransfer(uint128 x1, uint128 x2) external {
    uint256 mintAmount = uint256(x1) + uint256(x2);
    assertEq(token.balanceOf(ALICE), 0, "alice init balance is wrong");
    assertEq(token.balanceOf(BOB), 0, "bob init balance is wrong");

    token.mint(ALICE, mintAmount);
    assertEq(token.balanceOf(ALICE), mintAmount, "alice balance is wrong");

    token.transfer(ALICE, BOB, x1);
    assertEq(token.balanceOf(ALICE), x2, "alice balance is wrong");
    assertEq(token.balanceOf(BOB), x1, "bob balance is wrong");
    vm.expectRevert();
    token.transfer(ALICE, BOB, uint256(x2) + 1);
  }
}
