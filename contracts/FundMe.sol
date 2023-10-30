// SPDX-License-Identifier: MIT

//Get funds from user
//Witdraw funds
//set a minimum funding value in USD


// 1. Pragma
pragma solidity ^0.8.7;
// 2. Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**@title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    // cant be changed later on "immutable"
    address private immutable i_owner; // (i_variable for immutable variable) 
    // store it directly into the bytecode of the contract instead of storing it into storage slot
    address[] private s_funders; // (s_variable for storage variable)
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        //this saves gas as we are not storing any string to print...
        _;

        /*
        require(msg.sender == i_owner, "Sender not the owner"); 
        it costs extra gas as we use String memory here if it fails.
        "_;" it represents doing the rest of the code after checking require(),
        if it is above require, 
        then will first read rest of the code block it is implemented and then it will check the require()
        */
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
// Withdraw all amount from the account, we want this withdraw function to be called by only owner of the contract,
// so that nobody else can withdraw the fund, thts why we use modifiers for tht.
    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

// Resets the funder array, erases all funders.
        s_funders = new address[](0);
/*
    Withdraw the fund 3 ways
    1. Transfer
    msg.sender = of type address, 
    so to send, we need to typecast it to payable, address(this) -- gets address of this contract
    payable(msg.sender).transfer(address(this).balance);

    2. Send
    bool SendSuccess = payable(msg.sender).send(address(this).balance);
    require(SendSuccess, "Send Failed"); in case it fails then revert


    Transfer vs call vs Send
    payable(msg.sender).transfer(address(this).balance); 
*/
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /** @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
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