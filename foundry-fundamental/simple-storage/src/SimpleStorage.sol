// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title SimpleStorage (Cyfrin Updraft style)
/// @author github.com/@mxzyy
/// @notice Stores and retrieves a single favorite number and keeps a list of people with their favorite numbers.
/// @dev Purely illustrative; no access control and no special gas optimizations.
contract SimpleStorage {
    /* -------------------------------------------------------------------------- */
    /*                               COMMON VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Storage variable holding the current favorite number.
    uint256 private myFavoriteNumber;

    /// @notice Person record with a favorite number and a name.
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    /// @notice Public array of people that have been added.
    Person[] public listOfPeople;

    /// @notice Maps a person's name to their favorite number.
    mapping(string => uint256) public nameToFavoriteNumber;

    /* -------------------------------------------------------------------------- */
    /*                               MAIN FUNCTIONS                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Store a new favorite number.
    /// @dev Overwrites the previous value in storage.
    /// @param _favoriteNumber The number to be stored.
    function store(uint256 _favoriteNumber) public {
        myFavoriteNumber = _favoriteNumber;
    }

    /// @notice Get the currently stored favorite number.
    /// @return current The value of the stored favorite number.
    function retrieve() public view returns (uint256 current) {
        return myFavoriteNumber;
    }

    /// @notice Add a new person and their favorite number.
    /// @dev Pushes to `listOfPeople` and updates `nameToFavoriteNumber`.
    /// @param _name The person's name.
    /// @param _favoriteNumber The person's favorite number.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
