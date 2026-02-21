// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract A {
    event Response(bool success, bytes data);

    // ✅ harus payable kalau mau forward ETH
    function callFunc(address _addr) external payable {
        // ✅ tidak perlu batasi gas kecuali ada alasan kuat
        (bool success, bytes memory data) =
            payable(_addr).call{value: msg.value}(abi.encodeWithSignature("foo(string,uint256)", "call foo", 123));

        emit Response(success, data);

        // ✅ best practice: cek success
        require(success, _getRevertMsg(data));
    }

    // Helper untuk decode revert reason kalau ada
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return "low-level call failed";
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}

contract B {
    event FooCalled(address indexed from, uint256 value, string note, uint256 x);

    uint256 public myVar;

    // ✅ tambahkan foo agar panggilan A sukses
    function foo(string calldata note, uint256 x) external payable returns (bytes32 tag) {
        myVar = x; // contoh efek samping
        emit FooCalled(msg.sender, msg.value, note, x);
        return keccak256("ok");
    }

    function setVar(uint256 _myVar) external {
        myVar = _myVar;
    }

    // (Opsional) terima ETH tanpa data
    receive() external payable {}
    // (Opsional) fallback untuk panggilan fungsi yang tak ada
    fallback() external payable {}
}
