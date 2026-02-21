// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/console.sol";

contract Mapping {
    mapping(string => address) public addressMap;

    function set(string calldata _user, address _addressData) public {
        require(addressMap[_user] == address(0), "User already set!");
        addressMap[_user] = _addressData;
        console.log("Set Address ", _addressData, " with user", _user);
    }

    function get(string calldata _user) public view returns (address) {
        address userAddr = addressMap[_user];
        require(userAddr != address(0), "get(): User not found");
        return userAddr;
    }

    error UserNotFound(string user);

    function del(string calldata _user) public {
        address userAddr = addressMap[_user];
        if (userAddr == address(0)) {
            revert UserNotFound(_user);
        }
        delete addressMap[_user];
        console.log("User", _user, "has been deleted");
    }
}
