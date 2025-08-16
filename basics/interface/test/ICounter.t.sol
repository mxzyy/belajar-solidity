// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ICounter.sol"; // pastikan path sesuai

contract CounterTest is Test {
    Counter private counter;

    // Re-declare event persis seperti di kontrak (tanpa memory/caldadata!)
    event Incremented(address indexed by, uint256 newValue);

    function setUp() public {
        counter = new Counter();
    }

    function test_InitialValue_IsZero() public view {
        assertEq(counter.value(), 0, "initial value should be 0");
    }

    function test_Increment_EmitsEvent_AndUpdatesValue() public {
        // Cek topic1 (by), topic2 (tidak ada), topic3 (tidak ada), data (newValue), dan emitter
        vm.expectEmit(true, false, false, true, address(counter));
        emit Incremented(address(this), 1);

        counter.increment();
        assertEq(counter.value(), 1, "value should be 1 after increment");
    }

    function test_MultipleIncrements() public {
        counter.increment();
        counter.increment();
        counter.increment();
        assertEq(counter.value(), 3, "value should be 3 after 3 increments");
    }

    function test_CallThroughInterface_Works() public {
        ICounter ic = ICounter(address(counter));
        ic.increment();
        assertEq(counter.value(), 1, "value should be 1 via interface call");
        assertEq(ic.value(), 1, "interface value() should return 1");
    }

    function test_LowLevelCall_RespectsABI() public {
        (bool ok,) = address(counter).call(abi.encodeWithSignature("increment()"));
        assertTrue(ok, "low-level call to increment() failed");

        (bool ok1, bytes memory out) = address(counter).call(abi.encodeWithSignature("value()"));
        assertTrue(ok1, "low-level call to value() failed");
        uint256 v = abi.decode(out, (uint256));
        assertEq(v, 1, "value should be 1 after low-level increment");
    }

    function testFuzz_IncrementNTimes(uint8 n) public {
        uint256 times = uint256(n % 40);
        for (uint256 i = 0; i < times; i++) {
            counter.increment();
        }
        assertEq(counter.value(), times, "value should equal the number of increments");
    }
}
