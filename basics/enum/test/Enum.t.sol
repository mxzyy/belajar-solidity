// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Enum.sol"; // ubah path jika kontrak ada di lokasi lain

contract EnumTest is Test {
    Enum private enumContract;

    function setUp() public {
        enumContract = new Enum();
    }

    /* ---------------------------------------------------------- */
    /*                1.  Basis konstruktor & konstanta           */
    /* ---------------------------------------------------------- */

    function testDefaultStateIsCreated() public view {
        // state awal = Created (0)
        assertEq(uint256(enumContract.getState()), uint256(Enum.someState.Created), "state awal bukan Created");
    }

    function testDefaultStateConstant() public view {
        // defaultState constant harus Created
        assertEq(uint256(enumContract.getDefaultState()), uint256(Enum.someState.Created), "defaultState bukan Created");
    }

    /* ---------------------------------------------------------- */
    /*                2.  Fungsi utilitas min / max               */
    /* ---------------------------------------------------------- */

    function testMinMax() public view {
        assertEq(uint256(enumContract.getMinState()), uint256(Enum.someState.Created), "min salah");
        assertEq(uint256(enumContract.getMaxState()), uint256(Enum.someState.Done), "max salah");
    }

    /* ---------------------------------------------------------- */
    /*                3.  setState (jalan normal)                 */
    /* ---------------------------------------------------------- */

    function testSetStateValid() public {
        // set ke Proceed (index 2)
        enumContract.setState(uint256(Enum.someState.Proceed));
        assertEq(uint256(enumContract.getState()), uint256(Enum.someState.Proceed), "state tidak terset ke Proceed");
    }

    /* ---------------------------------------------------------- */
    /*                4.  setState (harus revert)                 */
    /* ---------------------------------------------------------- */

    function testSetStateOutOfRangeReverts() public {
        uint256 invalidIndex = 5; // di luar 0-3
        vm.expectRevert("index out of range");
        enumContract.setState(invalidIndex);
    }
}
