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
        address[] public players;
        uint public entryFee = 1 * (10 ** 6);
        uint lotteryId;
        mapping (uint => Winner) lotterWinners;
        mapping(address => bool) alreadyEntered;

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

            // Assigning random number contract
            randomNumContract = VRFv2Consumer(0x6E2E6007f69014e59324Cf214000CCF4626DdF43);
        }

       
       
       
       
        // Random number function
        function requestRanNum() public {
            // Request random words first
            randomNumContract.requestRandomWords();
            
        }


        function RandomValues() public view returns(bool fulfilled, uint256[] memory randomWords) {
            uint256 requestID = randomNumContract.lastRequestId();
            (fulfilled, randomWords) = randomNumContract.getRequestStatus(requestID);
        }

        function randomNumGenerator() public view returns(uint256){
        //    uint256 requestID = getRequestId();
           uint256 requestID = randomNumContract.lastRequestId();
        // Get random words array
        (, uint256[] memory randomWords) = randomNumContract.getRequestStatus(requestID);

        // return first random word
            return randomWords[0];
        }
    

        

        function enterLottery() public{
            require(msg.sender != address(0), "Use a valid account");
            require(players.length <=1, "No vacancy now");
            require(!alreadyEntered[msg.sender],"Already entered");
            usdc.transferFrom(msg.sender, address(this), entryFee);
            players.push(msg.sender);
            alreadyEntered[msg.sender]=true;

            
        }

        function pickWinner() public onlyOwner{
            require(players.length ==2, "players not yet complete");
            uint withdrawAmount= (usdc.balanceOf(address(this)) *9800)/10000;
            uint ownerShare = (usdc.balanceOf(address(this)) * 200) /10000;
            uint index = randomNumGenerator() % players.length;
            usdc.transfer(players[index], withdrawAmount);
            usdc.transfer(owner, ownerShare);
            lotterWinners[lotteryId] = Winner({
                id: lotteryId,
                winner: players[index]

            });

            for(uint i = 0; i < players.length; i++) {
                alreadyEntered[players[i]] = false;
            }

            lotteryId +=1;
            // Reset the players array.
            players = new address[](0);

        }

        function seePlayers() public view returns(address[] memory) {
            return players;
        }

        function seeWinners() public view returns(Winner[] memory) {
            Winner[] memory arr = new Winner[](lotteryId-1);
            for(uint i = 0; i < lotteryId-1; i++) {
                arr[i] = lotterWinners[i+1];
            }
            return arr;
        } 

        modifier onlyOwner() {
            require(msg.sender == owner, "not owner of contract");
            _;
        }




    }
