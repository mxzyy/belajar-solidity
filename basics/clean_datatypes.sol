// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

contract betterDataTypes {
    struct dataTypes {
        bool boolData;
        uint unsignedData;
        int signedData;
        address addressData;
        bytes bytesData;
    }

    // HEMAT GAS

    dataTypes public data;

    function setData (bool _boolData, uint _unsignedData, int _signedData, address _AddrData, bytes memory _bytesData) public {
        data = dataTypes(_boolData, _unsignedData, _signedData, _AddrData, _bytesData);
    }

    function getData () public view returns(bool _boolData, uint _unsignedData, int _signedData, address _AddrData, bytes memory _bytesData){
        return (data.boolData, data.unsignedData, data.signedData, data.addressData, data.bytesData);
    }
}