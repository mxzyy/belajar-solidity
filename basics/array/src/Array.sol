// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Array {
    struct UserEntry {
        string user;
        address addy;
    }

    UserEntry[] public entries;

    function add(string calldata _user, address _address) public {
        entries.push(UserEntry({user: _user, addy: _address}));
    }

    function get(uint256 _index) public view returns (string memory, address) {
        require(_index < entries.length,  "Index out of bounds");
        UserEntry storage data = entries[_index];
        return (data.user, data.addy);
    }

    function getByKey(string calldata _user) public view returns (address) {
        for (uint i = 0; i < entries.length; i++) {
            if (keccak256(bytes(entries[i].user)) == keccak256(bytes(_user))) {
                return entries[i].addy;
            }
        }
        revert("User not found");
    }

    function getUserCount() public view returns (uint) {
        return entries.length;
    }
}
