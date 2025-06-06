// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;


//Se deben utilizar modificadores cuando sea conveniente.
//El contrato debe ser seguro y robusto. Manejando adecuadamente los errores y las posibles situaciones excepcionales.
// Se deben utilizar eventos para comunicar los cambios de estado de la subasta a los participantes.
// documentar
contract Auction {

    struct Bidders {
        address bidderAddress;
        uint256 value;
    }

    event NewOffer(address indexed bidder, uint256 amount);
    event AuctionEnded();

    // change some variables to private
    Bidders public winner;
    Bidders[] public bidders;
    uint256 public startTime;
    uint256 public stopTime;
    bool public activeContractFlag;
    address public creator;

    constructor(){
        // Initializing timers
        startTime = block.timestamp;
        stopTime = startTime + 30 seconds;
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

    function bid() external payable checkIsActive requireIsActive {
        if(msg.value > (winner.value*105/100)) {
            winner.bidderAddress = msg.sender;
            winner.value = msg.value;
//            emit NewOffer(msg.sender, msg.value);
        }
        bidders.push(Bidders(msg.sender, msg.value));
        //block.timestamp<stopTime-10 minutes => extender el tiempo (stoptime+=10 minutes;)
    }

    // devolver ganador y la oferta
    function showWiner() view external returns(Bidders memory) {
        return winner;
    }

    // oferentes y montos ofrecidos
    function showOffers() view external returns (Bidders[] memory) {
        return bidders;
    }

    // devolver a todos los biders y descontar 2%
    function refundAll() checkIsActive requireIsNotActive onlyOwner public payable {
        //Loops through all bidders array and send eths to whoever bidded on the auction but the winner
        uint256 len = bidders.length;
        for(uint256 i= 0; i < len; i++) {
            if (bidders[i].bidderAddress != winner.bidderAddress) {
                (bool sent, bytes memory data) = bidders[i].bidderAddress.call{value: msg.value}("");
                require(sent, "Failed to send Ether");
            }
        }
    }

    function discountComission() checkIsActive requireIsNotActive onlyOwner public payable {
        // Get 2% comission of winners bid and send it to the creator
        uint256 comission = winner.value * 2/100;
        (bool sent, bytes memory data) = creator.call{value: comission}("");
        require(sent, "Failed to send Ether to creator");
        winner.value = winner.value - comission;

        emit AuctionEnded();
    }

    //Durante la subasta,=> isActive
    //los participantes pueden retirar el importe por encima de su última oferta válida.
    // function partialRefund() external checkIsActive {
    //     // unicamente puede sacarlo quien le corresponde
    // }

}
