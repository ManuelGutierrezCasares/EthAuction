# Manuel Gutierrez Casares's Ethereum Auction

## Usage:
- Starting bid is set to 100 Wei.
- Bids must be 5% higher than current winner's bid to be valid.
- Any bidder can claim partial refunds before the auction ends. (The only bid that cannot be claimed is the winning one)
- Creator must end the auction with endAuction function to refund everyone and claim his 2% comission once the auction ends.
- Auction time is set to 7 days from the starting time, but it will extend 10 extra minutes if any valid bid is done within the last 10 minutes.

## Variables:
- winner: Stores the address and the bid's value of the current winner of the auction.
- winnerEnded: Stores the address and the bid's value of the winner's bid before taking the comission.
- bidders: An array that keeps track of every bid that has not been claimed yet.
- biddersLog: An array that keeps track of every bid in the auction.
- startTime: Stores the current time when the auction starts.
- stopTime: Stores the time when the auction ends.
- activeContractFlag: Stores the auction state: is still active or not.
- creator: Stores the address of the creator of the auction.
- contractRefunded: Stores the contract status: was already ended or not.

## Functions:
- bid: Ensures that the bidder's user is 5% higher than the winner's one or the starting bid if it's the first bid. Emits NewOffer event.
- checkTimeExtension: Extends time of the auction by 10 minutes if any bid is submitted within 10 minutes to finish the auction. Emits TimeExtended event.
- showWiner: Shows the current winner of the auction (address and value of the bid). If auction has ended it will show full bid's value (without comission).
- showOffer: Shows every valid bid that the auction has got.
- endAuction: Only available when the auction ends and usable by the creator. Refunds every bidder but the winner with the bids that they have not claimed yet. Takes 2% of the winner's bid as comission and transfers it to the creator. Emits AuctionEnded event.
- partialRefund: Only available when the auction is active. Refunds the user with every own bid that is not the current winner of the auction.

## Events:
- NewOffer: Emitted when someone makes a valid bid. Informs the address of the bidder and the amount of the bid.
- AuctionEnded: Emitted when the auction has ended.
- TimeExtended: Emitted when the auction's finish time has been extended. Informs the new ending time of the auction and the value of the new winner's bid.
