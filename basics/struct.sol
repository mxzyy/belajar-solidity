// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract adressesBook {
    struct personModel {
        string name;
        address publickey;
    }

    personModel[] private person;
    

    function addPerson(string memory _name, address _pubkey) public {
        person.push(personModel(_name, _pubkey));
    }

    function getPubKeyPerson(string memory _name) view  public returns (address) {
        for (uint i = 0; i<=person.length; i++) {
            if (keccak256(abi.encodePacked(person[i].name)) == keccak256(abi.encodePacked(_name))) {
                return person[i].publickey;
            } 
        }
        return address(0);
    }


}