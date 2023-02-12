//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0 ;

contract Bet {
    //Betting  Status 
    uint constant STATUS_WIN = 1;
    uint constant STATUS_LOSE = 2;
    uint constant STATUS_TIE = 3;
    uint constant STATUS_PENDING = 4;

    //game status 
    uint constant STATUS_NOT_STARTED = 1;
    uint constant STATUS_STARTED = 2;
    uint constant STATUS_COMPLETE = 3;

    //general status 
    uint constant STATUS_ERROR = 4;

    struct PeerBet{
      uint guess;
      address payable addr;
      uint status;
    }

    struct Game {
      uint256 betAmount;
      uint outcome;
      uint status;
      PeerBet creator;
      PeerBet joiner;
    }
    

    Game game; 
     
     //fallback function
    fallback() external payable {

    }

    function createRoom(uint _guess) public payable {
      game = Game(msg.value, 0, STATUS_STARTED, PeerBet(_guess, payable(msg.sender), STATUS_PENDING), PeerBet(0, payable(address(0)), STATUS_NOT_STARTED));
      game.creator = PeerBet(_guess, payable(msg.sender), STATUS_PENDING);
    }
    
    //Betting by the joiner of the room 
    function takeBet(uint _guess) public payable {      
      require(msg.value == game.betAmount);
      game.joiner = PeerBet(_guess, payable(msg.sender), STATUS_PENDING);
      generateBetOutcome();
    }

    function payout() public payable {

      checkPermissions(msg.sender);
     
     if (game.creator.status == STATUS_TIE && game.joiner.status == STATUS_TIE) {
       game.creator.addr.transfer(game.betAmount);
       game.joiner.addr.transfer(game.betAmount);
     } else {
        if (game.creator.status == STATUS_WIN) {
          game.creator.addr.transfer(game.betAmount*2);
        } else if (game.joiner.status == STATUS_WIN) {
          game.joiner.addr.transfer(game.betAmount*2);
        } else {
          game.creator.addr.transfer(game.betAmount);
          game.joiner.addr.transfer(game.betAmount);
        }
     }
    }

    function checkPermissions(address sender) view private {
     //only the originator or taker can call this function
     require(sender == game.creator.addr || sender == game.joiner.addr);  
    }

     function getBetAmount() public view returns (uint) {
         checkPermissions(msg.sender);
     
         return game.betAmount;
    }

     function generateBetOutcome() private {
        // not a great way to generate a random number but ok for now
        game.outcome = uint(blockhash(block.number-1))%10 + 1;
        game.status = STATUS_COMPLETE;

        if (game.creator.guess == game.joiner.guess) {
          game.creator.status = STATUS_TIE;
          game.joiner.status = STATUS_TIE;
        } else if (game.creator.guess > game.outcome && game.joiner.guess > game.outcome) {
          game.creator.status = STATUS_TIE;
          game.joiner.status = STATUS_TIE;
        } else {
           if ((game.outcome - game.creator.guess) < (game.outcome - game.joiner.guess)) {
             game.creator.status = STATUS_WIN;
             game.joiner.status = STATUS_LOSE;
           } else if ((game.outcome - game.joiner.guess) < (game.outcome - game.creator.guess)) {
             game.creator.status = STATUS_LOSE;
             game.joiner.status = STATUS_WIN;
           } else {
             game.creator.status = STATUS_ERROR;
             game.joiner.status = STATUS_ERROR;
             game.status = STATUS_ERROR;
           }
        }
    }


    }