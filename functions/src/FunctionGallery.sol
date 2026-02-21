// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                        Kontrak target untuk delegatecall                   */
/* -------------------------------------------------------------------------- */
contract Target {
    uint256 public data;

    // fungsi sederhana agar bisa diset via delegatecall
    function set(uint256 _v) external {
        data = _v;
    }
}

/* -------------------------------------------------------------------------- */
/*                 Galeri lengkap semua macam fungsi Solidity                 */
/* -------------------------------------------------------------------------- */
contract FunctionGallery {
    /* --------------------------  STORAGE (persisten) ------------------------- */
    address public immutable owner; // immutable => set 1× di constructor
    uint256 public counter; // contoh state variable

    /* -------------------------------  EVENTS  -------------------------------- */
    event Deposit(address indexed from, uint256 value);
    event Increment(uint256 newValue);
    event FallbackCalled(address indexed from, uint256 value, bytes data);

    /* ------------------------------  MODIFIER  ------------------------------- */
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /* ----------------------------- CONSTRUCTOR ------------------------------ */
    constructor(uint256 _start) payable {
        owner = msg.sender; // alamat deployer
        counter = _start; // nilai awal counter
    }

    /* -------------------------------------------------------------------------- */
    /*                      1.  PUBLIC / EXTERNAL / OVERLOAD                      */
    /* -------------------------------------------------------------------------- */
    /// @notice Set nilai counter — callable dari L U A R kontrak saja
    function set(uint256 _val) external {
        counter = _val;
    }

    /// Overload: increment 1
    function inc() public {
        _increment(1);
    }

    /// Overload: increment by custom value
    function inc(uint256 by) public {
        _increment(by);
    }

    /* -------------------------------------------------------------------------- */
    /*                      2.  VIEW  &  PURE  FUNCTIONS                           */
    /* -------------------------------------------------------------------------- */
    /// Hanya membaca state (`view`)
    function current() public view returns (uint256) {
        return counter;
    }

    /// Tidak sentuh state apa pun (`pure`)
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    /* -------------------------------------------------------------------------- */
    /*                           3.  PAYABLE FUNCTION                              */
    /* -------------------------------------------------------------------------- */
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /* -------------------------------------------------------------------------- */
    /*                 4.  INTERNAL & PRIVATE  HELPER FUNCTIONS                    */
    /* -------------------------------------------------------------------------- */
    function _increment(uint256 by) internal {
        counter += by;
        emit Increment(counter);
    }

    function _secret() private pure returns (string memory) {
        return "shhh";
    }

    /* -------------------------------------------------------------------------- */
    /*                 5.  FUNCTION POINTER (FUNCTION TYPE)                        */
    /* -------------------------------------------------------------------------- */
    function callAddViaPtr(uint256 x, uint256 y) external pure returns (uint256) {
        // simpan pointer ke fungsi 'add'
        function(uint256, uint256) pure returns (uint256) ptr = add;
        return ptr(x, y);
    }

    /* -------------------------------------------------------------------------- */
    /*                          6.  DELEGATECALL DEMO                              */
    /* -------------------------------------------------------------------------- */
    function delegateSet(address target, uint256 value) external {
        (bool ok,) = target.delegatecall(abi.encodeWithSignature("set(uint256)", value));
        require(ok, "delegatecall failed");
        // Note: storage slot `data` di Target menjadi `data` di kontrak ini!
    }

    /* -------------------------------------------------------------------------- */
    /*                        7.  FALLBACK  &  RECEIVE                             */
    /* -------------------------------------------------------------------------- */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        // Dipanggil ketika selector tak cocok fungsi mana pun
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }
}
