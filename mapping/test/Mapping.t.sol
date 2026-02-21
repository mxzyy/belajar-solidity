// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Mapping} from "../src/Mapping.sol";

contract MappingTest is Test {
    Mapping public mapping_contract;

    function setUp() public {
        mapping_contract = new Mapping();
    }

    function test_setUser() public {
        mapping_contract.set("John", 0xEc161820434873131e2a0de2775A0f33833DB6ab);
        assertEq(mapping_contract.get("John"), 0xEc161820434873131e2a0de2775A0f33833DB6ab);
    }

    error UserNotFound(string user);

    function test_delUser() public {
        mapping_contract.set("Dan", 0x557cD5781fceb11fd53b8Ce70F18694cbf9159DA);
        mapping_contract.del("Dan");
    }

}
