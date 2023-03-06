// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import "./_RandomNumber.sol";

    interface USDC {
        function balanceOf(address account) external view returns (uint256);
        function allowance(address owner, address spender) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    }

    contract Lottery {
        // instance of the usdc token for the contract
        USDC public usdc;

        // Contract Owner
        address payable internal owner; 

        // Array that stores the players in the lottery
        address[] public players;

        // Lottery entry fee
        uint public entryFee = 1 * (10 ** 6);

        // Variable for storing lottery IDs
        uint lotteryId;

        // Mapping for storing winners of each lottery
        mapping (uint => Winner) lotterWinners;

        // Mapping to store if a user have already entered the lottery
        mapping(address => bool) alreadyEntered;

        // Winner struct that stores the lottery ID and the winner of that particular lottery
        struct Winner{
            uint id;
            address winner;

        }
        // Random number initialization
        VRFv2Consumer public randomNumContract;

      

        constructor(address usdcContractAddress){
            usdc = USDC(usdcContractAddress);
            owner = payable(msg.sender);
            lotteryId = 1;
            // USDC contract: 0x07865c6E87B9F70255377e024ace6630C1Eaa37F

            // Assigning random number contract(replace with the one you deployed)
            randomNumContract = VRFv2Consumer(0x6E2E6007f69014e59324Cf214000CCF4626DdF43);
        }

                      
        // Random number function - requests random words from chainlink
        function requestRanNum() public {
            // Request random words first
            randomNumContract.requestRandomWords();
            
        }


        // RandomValues function to verify whether chainlink has returned random words.

        function RandomValues() public view returns(bool fulfilled, uint256[] memory randomWords) {
            uint256 requestID = randomNumContract.lastRequestId();
            (fulfilled, randomWords) = randomNumContract.getRequestStatus(requestID);
        }


        // This functions returns the random number given to us by chainlink
        function randomNumGenerator() public view returns(uint256){
        //    uint256 requestID = getRequestId();
           uint256 requestID = randomNumContract.lastRequestId();
        // Get random words array
        (, uint256[] memory randomWords) = randomNumContract.getRequestStatus(requestID);

        // return first random word
            return randomWords[0];
        }
    

    // This function allows the user to enter the lottery after meeting the requirements
        function enterLottery() public{
            require(msg.sender != address(0), "Use a valid account");
            require(players.length <=9, "No vacancy now");
            require(!alreadyEntered[msg.sender],"Already entered");
            usdc.transferFrom(msg.sender, address(this), entryFee);
            players.push(msg.sender);
            alreadyEntered[msg.sender]=true;
          
        }

        // This function picks a winner and transfers the reward to the winner
        function pickWinner() public onlyOwner{
            require(players.length ==10, "players not yet complete");
            uint withdrawAmount= (usdc.balanceOf(address(this)) *9800)/10000;
            uint ownerShare = (usdc.balanceOf(address(this)) * 200) /10000;
            uint index = randomNumGenerator() % players.length;
            usdc.transfer(players[index], withdrawAmount);
            usdc.transfer(owner, ownerShare);
            lotterWinners[lotteryId] = Winner({
                id: lotteryId,
                winner: players[index]

            });

            // this resets the players' entry status after a winner has been picked
            for(uint i = 0; i < players.length; i++) {
                alreadyEntered[players[i]] = false;
            }
            // The ID is incremented for the next lottery
            lotteryId +=1;
            // Reset the players array.
            players = new address[](0);

        }

        // This function returns an array of the players in the current lottery
        function seePlayers() public view returns(address[] memory) {
            return players;
        }

        // This funcrion returns an array of winners of different lotteries.
        function seeWinners() public view returns(Winner[] memory) {
            Winner[] memory arr = new Winner[](lotteryId-1);
            for(uint i = 0; i < lotteryId-1; i++) {
                arr[i] = lotterWinners[i+1];
            }
            return arr;
        } 

        // modifier that gives only the owner of the contract certain functionalities
        modifier onlyOwner() {
            require(msg.sender == owner, "not owner of contract");
            _;
        }

    }
