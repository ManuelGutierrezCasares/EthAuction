// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

//TODO: Revisar lógica de cuando refundo parcialmente no haga pop o delete sobre el array original (quizás con otra propiedad sobre Bidders ej isRefunded?)
//TODO: Cambiar las variables privadas a privadas
//TODO: Revisar la oferta inicial, más que nada el address 0 (creo que está ok)
//TODO: Cambiar hardcodeo de tiempos y demás que se agregaron por pruebas
//TODO: Hacer una prueba general final
//TODO: Documentar todo
contract Auction {

    struct Bidders {
        address bidderAddress;
        uint256 value;
    }

    event NewOffer(address indexed bidder, uint256 amount);
    event AuctionEnded();
    event TimeExtended(uint256 indexed stopTime, uint256 amount);

    Bidders public winner;
    Bidders[] public bidders;
    uint256 public startTime;
    uint256 public stopTime;
    bool public activeContractFlag;
    address public creator;
    bool public contractRefunded;

    constructor(){
        // Initializing timers
        startTime = block.timestamp;
        stopTime = startTime + 1 minutes;
        //stopTime = startTime + 7 days;

        // Initializing winner => Address pointing to null, value being min bid = 100
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
        require(msg.value > (winner.value * 105/100), "Your bid must be at least 105% of the previous bid!");
        
        checkTimeExtension();
        
        winner.bidderAddress = msg.sender;
        winner.value = msg.value;
       
        emit NewOffer(msg.sender, msg.value);

        bidders.push(Bidders(msg.sender, msg.value));
    }

    function checkTimeExtension() private {
        if (block.timestamp > stopTime - 10 minutes) {
            stopTime += 10 minutes;
            emit TimeExtended(stopTime, msg.value);
        }
    }

    function showWiner() view external returns(Bidders memory) {
        return winner;
    }

    function showOffers() view external returns (Bidders[] memory) {
        return bidders;
    }

    function refundAll() checkIsActive requireIsNotActive onlyOwner noPreviousRefund public payable {
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


