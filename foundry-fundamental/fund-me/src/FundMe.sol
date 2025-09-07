// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// --- External Imports ---
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// --- Custom Errors ---
error fundMe__NotOwner();

/**
 * @title FundMe Contract forked from @CyfrinUpdraft repository
 *  @author Patrick Collins (@PatrickAlphaC) refactored by @mxzyy
 *  @notice This contract is a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    /// @notice Type Declarations
    /// @dev Adhere the PriceConverter library for uint256 type
    using PriceConverter for uint256;

    /// @notice State Variables
    // --- Variables ---
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address public immutable i_owner;
    address[] public s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface internal s_priceFeed;

    /// @notice Events
    // --- Events ---

    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Modifiers
    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert fundMe__NotOwner();
        _;
    }

    /// @notice Functions
    // --- Functions ---
    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
    }

    /// @notice Fund the contract with ETH/USD conversion
    /// @dev The fund function uses the PriceConverter library to convert the sent ETH amount to USD
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Minimum funding amount is 5 USD");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
        emit Funded(msg.sender, msg.value);
    }

    /// @notice Withdraw the contract's balance to the owner's address
    /// @dev Only the owner can call this function, which resets funders' balances and transfers the contract's balance
    function withdraw() public onlyOwner {
        // Reset the amount funded by each funder
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /// @notice A more gas-efficient withdraw function
    /// @dev This function minimizes gas costs by using memory for the funders array
    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // --- Getter Functions ---
    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
