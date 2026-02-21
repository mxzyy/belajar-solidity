// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* --------------------------------------------- */
/*                  IMPORTS                      */
/* --------------------------------------------- */
import {User, Status, NotAuthorized} from "./Types.sol";
import {IERC20} from "./Interfaces.sol";
import {MathLib} from "./Libraries.sol";
import {Events} from "./Events.sol";
import {isEven} from "./Functions.sol";
import {Ownable} from "./Ownable.sol";

/* --------------------------------------------- */
/*            MAIN CONTRACT (PRODUCTION)         */
/* --------------------------------------------- */
contract ImportExample is Ownable, Events {
    using MathLib for uint256;

    IERC20 public immutable token;
    mapping(address => User) public users;

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    /// @notice Register user with initial balance
    function register(uint256 initialBalance) external {
        if (initialBalance == 0 || !isEven(initialBalance)) {
            revert NotAuthorized(msg.sender); // pakai custom error
        }

        users[msg.sender] = User({account: msg.sender, balance: initialBalance});
        emit UserRegistered(msg.sender, block.timestamp);
    }

    /// @notice Transfer token from this contract to user
    function reward(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid addr");
        require(token.transfer(to, amount), "Transfer failed");

        // INIT-ON-REWARD: jika user belum register, set account di sini
        User storage u = users[to];
        if (u.account == address(0)) {
            u.account = to;
        }

        // Akumulasi balance
        u.balance = u.balance.add(amount);
    }

    /// @notice Get user status based on balance
    function getUserStatus(address account) external view returns (Status) {
        if (users[account].balance == 0) return Status.Pending;
        else if (users[account].balance > 100 ether) return Status.Success;
        else return Status.Failed;
    }
}
