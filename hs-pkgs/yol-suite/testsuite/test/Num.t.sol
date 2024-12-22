pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";

import { INumTestsProgram, createNumTestsProgram } from "yol-build/Contracts.sol";


function panicError(uint256 errCode) pure returns (bytes memory) {
  return abi.encodeWithSelector(bytes4(0x4e487b71), errCode);
}

contract T is Test {
  INumTestsProgram private prog;

  constructor () {
    prog = createNumTestsProgram();
  }

  // add uintX

  function test_add_uint256(uint256 x, uint256 y) external {
    if (y <= type(uint256).max - x) {
      assertEq(prog.add_uint256(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint256 z = prog.add_uint256(x, y);
      console2.log(z);
    }
  }

  function test_add_uint192(uint192 x, uint192 y) external {
    if (y <= type(uint192).max - x) {
      assertEq(prog.add_uint192(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint192 z = prog.add_uint192(x, y);
      console2.log(z);
    }
  }

  function test_add_uint128(uint128 x, uint128 y) external {
    if (y <= type(uint128).max - x) {
      assertEq(prog.add_uint128(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint128 z = prog.add_uint128(x, y);
      console2.log(z);
    }
  }

  function test_add_uint32(uint32 x, uint32 y) external {
    if (y <= type(uint32).max - x) {
      assertEq(prog.add_uint32(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint32 z = prog.add_uint32(x, y);
      console2.log(z);
    }
  }

  // add intX

  function test_add_int256(int256 x, int256 y) external {
    if ((x > 0 && y <= type(int256).max - x) || (x <= 0 && y >= type(int256).min - x)) {
      assertEq(prog.add_int256(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      int256 z = prog.add_int256(x, y);
      console2.log(z);
    }
  }

  function test_add_int192(int192 x, int192 y) external {
    if ((x > 0 && y <= type(int192).max - x) || (x <= 0 && y >= type(int192).min - x)) {
      assertEq(prog.add_int192(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      int192 z = prog.add_int192(x, y);
      console2.log(z);
    }
  }

  function test_add_int128(int128 x, int128 y) external {
    if ((x > 0 && y <= type(int128).max - x) || (x <= 0 && y >= type(int128).min - x)) {
      assertEq(prog.add_int128(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      int128 z = prog.add_int128(x, y);
      console2.log(z);
    }
  }

  function test_add_int32(int32 x, int32 y) external {
    if ((x > 0 && y <= type(int32).max - x) || (x <= 0 && y >= type(int32).min - x)) {
      assertEq(prog.add_int32(x, y), x + y);
    } else {
      vm.expectRevert(panicError(0x11));
      int32 z = prog.add_int32(x, y);
      console2.log(z);
    }
  }

  // sub uintX

  function test_sub_uint256(uint256 x, uint256 y) external {
    if (x >= y) {
      assertEq(prog.sub_uint256(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint256 z = prog.sub_uint256(x, y);
      console2.log(z);
    }
  }

  function test_sub_uint192(uint192 x, uint192 y) external {
    if (x >= y) {
      assertEq(prog.sub_uint192(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint192 z = prog.sub_uint192(x, y);
      console2.log(z);
    }
  }

  function test_sub_uint128(uint128 x, uint128 y) external {
    if (x >= y) {
      assertEq(prog.sub_uint128(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint128 z = prog.sub_uint128(x, y);
      console2.log(z);
    }
  }

  function test_sub_uint32(uint32 x, uint32 y) external {
    if (x >= y) {
      assertEq(prog.sub_uint32(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      uint32 z = prog.sub_uint32(x, y);
      console2.log(z);
    }
  }

  // sub intX

  function test_sub_int256(int256 x, int256 y) external {
    if ((y > 0 && x >= y + type(int256).min) || (y <= 0 && x <= type(int256).max + y)) {
      assertEq(prog.sub_int256(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      int256 z = prog.sub_int256(x, y);
      console2.log(z);
    }
  }

  function test_sub_int192(int192 x, int192 y) external {
    if ((y > 0 && x >= y + type(int192).min) || (y <= 0 && x <= type(int192).max + y)) {
      assertEq(prog.sub_int192(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      int192 z = prog.sub_int192(x, y);
      console2.log(z);
    }
  }

  function test_sub_int128(int128 x, int128 y) external {
    if ((y > 0 && x >= y + type(int128).min) || (y <= 0 && x <= type(int128).max + y)) {
      assertEq(prog.sub_int128(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      int128 z = prog.sub_int128(x, y);
      console2.log(z);
    }
  }

  function test_sub_int32(int32 x, int32 y) external {
    if ((y > 0 && x >= y + type(int32).min) || (y <= 0 && x <= type(int32).max + y)) {
      assertEq(prog.sub_int32(x, y), x - y);
    } else {
      vm.expectRevert(panicError(0x11));
      int32 z = prog.sub_int32(x, y);
      console2.log(z);
    }
  }

  // test maybe pattern

  function test_add_maybe_int96_with_default(int96 x, int96 y, int96 def) external {
    if ((x > 0 && y <= type(int96).max - x) || (x <= 0 && y >= type(int96).min - x)) {
      assertEq(prog.add_maybe_int96_with_default(x, y, def), x + y);
    } else {
      assertEq(prog.add_maybe_int96_with_default(x, y, def), def);
    }
  }

  function test_add_maybe_int96(bool bx, int96 x, bool by, int96 y) external {
    bool bz;
    int96 z;
    (bz, z) = prog.add_maybe_int96(bx, x, by, y);
    if (bx && by) {
      if ((x > 0 && y <= type(int96).max - x) || (x <= 0 && y >= type(int96).min - x)) {
        // assertTrue(bz, "test_add_maybe_int96 1");
        assertEq(z, x + y, "test_add_maybe_int96 2");
      } else {
        // assertFalse(bz, "test_add_maybe_int96 3");
        assertEq(z, 0, "test_add_maybe_int96 4");
      }
    } else {
      // assertFalse(bz, "test_add_maybe_int96 5");
    }
  }
}
