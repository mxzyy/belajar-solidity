// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract utama
contract MainContract {
    // Variable private yang hanya bisa diakses di dalam contract ini
    uint private privateData;
    
    // Variable public yang bisa diakses dari mana saja
    uint public publicData;
    
    constructor() {
        privateData = 100;
        publicData = 200;
    }
    
    // Private function - hanya bisa dipanggil di dalam contract ini
    function privateFunction() private view returns(uint) {
        return privateData;
    }
    
    // Public function - bisa dipanggil dari mana saja
    function publicFunction() public view returns(uint) {
        return privateFunction() + publicData;
    }
    
    // Internal function - bisa diakses oleh contract ini dan turunannya
    function internalFunction() internal view returns(uint) {
        return privateData * 2;
    }

    // External function - hanya bisa dipanggil dari luar contract
    function externalFunction() external view returns(uint) {
        return publicData * 3;
    }

    // Function ini akan error karena mencoba memanggil external function dari dalam contract
    // function testExternalCall() public view returns(uint) {
    //     return this.externalFunction(); // Harus menggunakan 'this' jika ingin memanggil external function
    //     return externalFunction(); // Error! Tidak bisa langsung memanggil external function
    // }
}

// Contract turunan
contract ChildContract is MainContract {
    function getInternalCalculation() public view returns(uint) {
        return internalFunction();
    }

    // External function baru di contract turunan
    function childExternalFunction() external pure returns(string memory) {
        return "Called from child contract";
    }
}

// Contract terpisah untuk menunjukkan cara memanggil external function
contract CallerContract {
    MainContract mainContract;
    ChildContract childContract;
    
    constructor(address _mainContract, address _childContract) {
        mainContract = MainContract(_mainContract);
        childContract = ChildContract(_childContract);
    }
    
    // Cara memanggil public function
    function callPublicFunction() public view returns(uint) {
        return mainContract.publicFunction();
    }

    // Cara memanggil external function
    function callExternalFunction() public view returns(uint) {
        return mainContract.externalFunction();
    }

    // Cara memanggil external function dari child contract
    function callChildExternal() public view returns(string memory) {
        return childContract.childExternalFunction();
    }

    // Fungsi untuk mendemonstrasikan multiple calls
    function multipleExternalCalls() public view returns(uint) {
        // Bisa memanggil external function berkali-kali
        uint result1 = mainContract.externalFunction();
        uint result2 = mainContract.externalFunction();
        return result1 + result2;
    }
}