// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

contract basicDataTypes {
    bool boolDataType;
    uint unsignedInt;
    int  signedInt;
    address myPublicKey;

    // BOROS GAS BJIR

    function writeBool ( bool _boolDataType ) public {
        boolDataType = _boolDataType;
    }

    function readBool () public view returns (bool){
        return boolDataType;
    }

    function writeUint ( uint _unsignedInt ) public {
        unsignedInt = _unsignedInt;
    }

    function readUint () public view returns (uint){
        return unsignedInt;
    }

    function writeInt ( int _signedInt ) public {
        signedInt = _signedInt;
    }

    function readInt () public view returns (int){
        return signedInt;
    }

    function writeAddr ( address _Address ) public {
        myPublicKey = _Address;
    }

    function readAddr () public view returns (address){
        return myPublicKey;
    }
}