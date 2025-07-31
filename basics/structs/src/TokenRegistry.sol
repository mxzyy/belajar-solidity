// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TokenRegistry {
    /* -------------------------------------------------------------------------- */
    /*                                   TYPES                                    */
    /* -------------------------------------------------------------------------- */
    struct Token {
        string ticker;
        address ca;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   STATE                                    */
    /* -------------------------------------------------------------------------- */
    Token[] public tokens; // getter otomatis: tokens(uint) → Token
    address public immutable owner;

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */
    error NotOwner();
    error ZeroAddress();
    error EmptyTicker();

    /* -------------------------------------------------------------------------- */
    /*                                    EVENTS                                  */
    /* -------------------------------------------------------------------------- */
    event TokenAdded(uint256 indexed index, string ticker, address ca);

    /* -------------------------------------------------------------------------- */
    /*                                CONSTRUCTOR                                 */
    /* -------------------------------------------------------------------------- */
    constructor() {
        owner = msg.sender;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MODIFIER                                 */
    /* -------------------------------------------------------------------------- */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                               WRITE FUNCTION                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Menambahkan token baru ke registry
     * @param _ticker  simbol token (contoh "USDC")
     * @param _ca      contract address token
     */
    function addToken(string calldata _ticker, address _ca) external onlyOwner {
        if (bytes(_ticker).length == 0) revert EmptyTicker();
        if (_ca == address(0)) revert ZeroAddress();

        tokens.push(Token({ticker: _ticker, ca: _ca}));
        emit TokenAdded(tokens.length - 1, _ticker, _ca);
    }

    /* -------------------------------------------------------------------------- */
    /*                               READ FUNCTIONS                               */
    /* -------------------------------------------------------------------------- */
    function tokenCount() external view returns (uint256) {
        return tokens.length;
    }
}
