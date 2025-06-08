// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Auction {

    struct Bidders {
        address bidderAddress;
        uint256 value;
    }

    event NewOffer(address indexed bidder, uint256 amount);
    event AuctionEnded();
    event TimeExtended(uint256 indexed stopTime, uint256 amount);

    Bidders private winner;
    Bidders private winnerEnded;
    Bidders[] private bidders;
    Bidders[] private biddersLog;
    uint256 private startTime;
    uint256 private stopTime;
    bool private activeContractFlag;
    address private creator;
    bool private contractRefunded;

    constructor(){
        // Initializing timers
        startTime = block.timestamp;
        stopTime = startTime + 7 days;

        // Initializing winner => Address pointing to null, value being starting value = 100
        winner.bidderAddress = address(0);
        winner.value = 100;

        // Initializing boolean
        activeContractFlag = true;

        // Storing creator's address
        creator = msg.sender;
    }

    modifier checkIsActive() {
        if (block.timestamp > stopTime) {
            activeContractFlag = false;
            winnerEnded = winner;
        }
        _;
    }

    modifier requireIsActive() {
        require(activeContractFlag, "This auction is not active anymore.");
        _;
    }

    modifier requireIsNotActive() {
        require(!activeContractFlag, "This auction is still active.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == creator, "This function can only be called by the contract creator.");
        _;
    }

    modifier noPreviousRefund() {
        require(!contractRefunded,"This contract has already been refunded.");
        _;
    }

    function bid() external payable checkIsActive requireIsActive {
        require(msg.value > (winner.value * 105/100), "Your bid must be at least 5% higher than the previous bid!");
        
        checkTimeExtension();
        
        winner.bidderAddress = msg.sender;
        winner.value = msg.value;

        bidders.push(Bidders(msg.sender, msg.value));
        biddersLog.push(Bidders(msg.sender, msg.value));

        emit NewOffer(msg.sender, msg.value);
    }

    function checkTimeExtension() private {
        if (block.timestamp > stopTime - 10 minutes) {
            stopTime += 10 minutes;
            emit TimeExtended(stopTime, winner.value);
        }
    }

    function showWiner() view external returns(Bidders memory) {
        if (!activeContractFlag) {
            return winnerEnded;
        }
        return winner;
    }

    function showOffers() view external returns (Bidders[] memory) {
        return biddersLog;
    }

    function endAuction() checkIsActive requireIsNotActive onlyOwner noPreviousRefund public payable {
        //Loops through all bidders array and send eths to whoever bidded on the auction but the winner
        uint256 len = bidders.length;
        for(uint256 i= 0; i < len; i++) {
            if (bidders[i].bidderAddress != winner.bidderAddress) {
                (bool sent, bytes memory data) = bidders[i].bidderAddress.call{value: bidders[i].value}("");
                require(sent, "Failed to send Ether");
            }
        }

        // Get 2% comission of winners bid and send it to the creator
        uint256 comission = winner.value * 2/100;
        (bool sent, bytes memory data) = creator.call{value: comission}("");
        require(sent, "Failed to send Ether to creator");
        winner.value = winner.value - comission;

        contractRefunded = true;
        emit AuctionEnded();
    }

    function partialRefund() checkIsActive requireIsActive public payable {
        //Loops through all bidders array and refund the user's not winning bids.
        bool isBidder = false;
        uint256 len = bidders.length;
        for(uint256 i= 0; i < len; i++) {
            if (bidders[i].bidderAddress == msg.sender && bidders[i].value != winner.value) {
                (bool sent, bytes memory data) = bidders[i].bidderAddress.call{value: bidders[i].value}("");
                require(sent, "Failed to send Ether");
                delete bidders[i];
                isBidder = true;
            }
        }
        require(isBidder, "You don't have any bids to claim.");
    }

}
