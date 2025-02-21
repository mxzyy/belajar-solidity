// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

contract simpleStorage {
    uint256 favouriteNumber;

    struct person {
        string name;
        uint256 favouriteNumber;
    }

    person[] public listPersons;

    mapping (string => uint256) public nameToFavNumber;

    function store(uint256 _favouriteNumber) public virtual  {
        favouriteNumber = _favouriteNumber;
    }

    function retriveNumber() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNum) public {
        listPersons.push(person(_name, _favouriteNum));
        nameToFavNumber[_name] = _favouriteNum;
    }

}

contract simpleStorage2 {}
contract simpleStorage3 {}
contract simpleStorage4 {}