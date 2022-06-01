//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissors {

    event AcceptedGame(uint _gameId,  uint _wager, address _from, string _move);

    uint private _gamesLength;
    
    struct  Game {
        address host;
        uint wager;
        bytes32 move;
    }

    struct Expiration {
        uint256 time;
        address claimant;
        uint wager;
    }

    mapping(uint => Game) private _games;
    mapping(uint => Expiration) private _expirations;

    function createGame(uint _wager, bytes32 _move) public payable {
        require(msg.value == _wager);
        _games[_gamesLength++] = Game(msg.sender, _wager, _move);
    }

    function acceptGame(uint _gameId, string memory _move) public payable {
        require(msg.value == _games[_gameId].wager);
        delete _games[_gameId];
        _gamesLength--;
        _expirations[_gameId] = Expiration(block.timestamp + 24 hours, msg.sender, msg.value);
        emit AcceptedGame(_gameId, msg.value, msg.sender, _move);

    }

    function deal(uint _gameId, uint _wager, string memory _move, address _other, string memory _otherMove) public {
        require(block.timestamp < _expirations[_gameId].time);
        bytes32 _encodedMove = keccak256(abi.encodePacked(_move));
        bytes32 _encodedOtherMove = keccak256(abi.encodePacked(_otherMove));
        if(_encodedMove == _encodedOtherMove) {
            payable(msg.sender).transfer(_wager);
           payable(_other).transfer(_wager);
           
        } else {
            bytes32 _rock = keccak256(abi.encodePacked("rock"));
            bytes32 _scissors = keccak256(abi.encodePacked("scissors"));
            bytes32 _paper = keccak256(abi.encodePacked("paper"));
            if(
                (_encodedMove == _rock && _encodedOtherMove == _scissors) ||
                (_encodedMove == _scissors && _encodedOtherMove == _paper) ||
                (_encodedMove == _paper && _encodedOtherMove == _rock)
            ) {
                payable(msg.sender).transfer(2*_wager);
            } else {
                payable(_other).transfer(2*_wager);
            }
        }
    }

    function gameExpired(uint _gameId) public {
        require( msg.sender == _expirations[_gameId].claimant );
        require(block.timestamp >= _expirations[_gameId].time);
        payable(msg.sender).transfer(_expirations[_gameId].wager * 2);
    }



}