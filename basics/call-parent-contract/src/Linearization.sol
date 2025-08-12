// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract A {
    event Log(string who);

    function f() public virtual {
        emit Log("A");
    }
}

contract B is A {
    function f() public virtual override {
        emit Log("B");
        super.f(); // lanjut ke “orang tua berikutnya” di urutan
    }
}

contract C is A {
    function f() public virtual override {
        emit Log("C");
        super.f();
    }
}

contract D is B, C {
    // Urutan linearization: D → B → C → A
    function f() public override(B, C) {
        emit Log("D");
        super.f(); // → B.f() → (super) C.f() → (super) A.f()
    }
}
