// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

// import the attackerReentracy contract
import {AttackerReentrancy} from "./attackerReentracy.sol";

contract PuppyRaffleTest is Test {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee = 1e18;
    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);
    }

    //////////////////////
    /// EnterRaffle    ///
    /////////////////////

    function testCanEnterRaffle() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        assertEq(puppyRaffle.players(0), playerOne);
    }

    function testCantEnterWithoutPaying() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle(players);
    }

    function testCanEnterRaffleMany() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
        assertEq(puppyRaffle.players(0), playerOne);
        assertEq(puppyRaffle.players(1), playerTwo);
    }

    function testCantEnterWithoutPayingMultiple() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle{value: entranceFee}(players);
    }

    function testCantEnterWithDuplicatePlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
    }

    function testCantEnterWithDuplicatePlayersMany() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);
    }

    //////////////////////
    /// Refund         ///
    /////////////////////
    modifier playerEntered() {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        _;
    }

    function testCanGetRefund() public playerEntered {
        uint256 balanceBefore = address(playerOne).balance;
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(address(playerOne).balance, balanceBefore + entranceFee);
    }

    function testGettingRefundRemovesThemFromArray() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(puppyRaffle.players(0), address(0));
    }

    function testOnlyPlayerCanRefundThemself() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);
        vm.expectRevert("PuppyRaffle: Only the player can refund");
        vm.prank(playerTwo);
        puppyRaffle.refund(indexOfPlayer);
    }

    //////////////////////
    /// getActivePlayerIndex         ///
    /////////////////////
    function testGetActivePlayerIndexManyPlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);

        assertEq(puppyRaffle.getActivePlayerIndex(playerOne), 0);
        assertEq(puppyRaffle.getActivePlayerIndex(playerTwo), 1);
    }

    //////////////////////
    /// selectWinner         ///
    /////////////////////
    modifier playersEntered() {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
        _;
    }

    function testCantSelectWinnerBeforeRaffleEnds() public playersEntered {
        vm.expectRevert("PuppyRaffle: Raffle not over");
        puppyRaffle.selectWinner();
    }

    function testCantSelectWinnerWithFewerThanFourPlayers() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = address(3);
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        vm.expectRevert("PuppyRaffle: Need at least 4 players");
        puppyRaffle.selectWinner();
    }

    function testSelectWinner() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.previousWinner(), playerFour);
    }

    function testSelectWinnerGetsPaid() public playersEntered {
        uint256 balanceBefore = address(playerFour).balance;

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPayout = ((entranceFee * 4) * 80 / 100);

        puppyRaffle.selectWinner();
        assertEq(address(playerFour).balance, balanceBefore + expectedPayout);
    }

    function testSelectWinnerGetsAPuppy() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.balanceOf(playerFour), 1);
    }

    function testPuppyUriIsRight() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        string memory expectedTokenUri =
            "data:application/json;base64,eyJuYW1lIjoiUHVwcHkgUmFmZmxlIiwgImRlc2NyaXB0aW9uIjoiQW4gYWRvcmFibGUgcHVwcHkhIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogInJhcml0eSIsICJ2YWx1ZSI6IGNvbW1vbn1dLCAiaW1hZ2UiOiJpcGZzOi8vUW1Tc1lSeDNMcERBYjFHWlFtN3paMUF1SFpqZmJQa0Q2SjdzOXI0MXh1MW1mOCJ9";

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.tokenURI(0), expectedTokenUri);
    }

    //////////////////////
    /// withdrawFees         ///
    /////////////////////
    function testCantWithdrawFeesIfPlayersActive() public playersEntered {
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
    }

    function testWithdrawFees() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPrizeAmount = ((entranceFee * 4) * 20) / 100;

        puppyRaffle.selectWinner();
        puppyRaffle.withdrawFees();
        assertEq(address(feeAddress).balance, expectedPrizeAmount);
    }

    ///////////////////////////////////////////////////
    //    Audit Test Prove of Code (POC)           //
    /////////////////////////////////////////////////

    function testAuditPoC_DoS() public {
        uint256 numberOfNewPlayers = 100;
        address[] memory newPlayers = new address[](numberOfNewPlayers);
        for (uint256 i = 0; i < numberOfNewPlayers; i++) {
            newPlayers[i] = address(i);
        }
        // the starting gas remaining before player 1 enters
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * newPlayers.length}(newPlayers);
        // the  gas remaining after player 1 has entered the contract
        uint256 gasEnd = gasleft();
        // the gas used by the player 1 to enter the raffle
        uint256 gasUsedFirst = gasStart - gasEnd;
        console.log("GasUsed by player 1 after entering raffle is: ", gasUsedFirst);

        // a second player enters the raffle
        // creating the list of array for player 2
        address[] memory newPlayers2 = new address[](numberOfNewPlayers);
        for (uint256 i = 0; i < numberOfNewPlayers; i++) {
            newPlayers2[i] = address(i + numberOfNewPlayers);
        }
        //  the starting for player 2 before entering
        uint256 gasStart2 = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * newPlayers.length}(newPlayers2);
        // the gas remaining after player 2 has entered the contract
        uint256 gasEnd2 = gasleft();
        // the gas used by the player 2 to enter the raffle
        uint256 gasUsedSecond = gasStart2 - gasEnd2;
        console.log("GasUsed by player 2 after entering raffle is: ", gasUsedSecond);
        console.log("Diff between GasUsed between player 1 and 2 : ", gasUsedSecond - gasUsedFirst);
        // the gss used by player 2 should be greater than the gas used by player 1
        assert(gasUsedSecond > gasUsedFirst);
    }

    //proof of code for reentrancy attack
    function testAuditPoC_Reentrancy() public {
        // a normal user (victim) enters the raffle
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);
        uint256 puppyRaffleInitialBalance = address(puppyRaffle).balance;
        // checking the balance of the contract
        console.log("Balance of the PuppyRaffle before attack: ", puppyRaffleInitialBalance);

        // attacker contract is deployed
        AttackerReentrancy attackContract = new AttackerReentrancy(puppyRaffle);
        // we fund the attacker with 1 ether , in order to enter the raffle
        attackContract.fund{value: 1 ether}();
        uint256 attackContractInitialBalance = address(attackContract).balance;

        attackContract.attack();
        // final balance of pupply raffle and attackerContract
        uint256 puppyRaffleFinalBalance = address(puppyRaffle).balance;
        uint256 attackContractFinalBalance = address(attackContract).balance;
        console.log("Balance of the PuppyRaffle after attack: ", puppyRaffleFinalBalance);
        console.log("Balance of the attackContract after attack: ", attackContractFinalBalance);

        assertEq(puppyRaffleFinalBalance, 0);
        assertEq(attackContractFinalBalance, puppyRaffleInitialBalance + attackContractInitialBalance);

        // attacker
    }

    function testAuditPoC_OverFlow() public {
        // if (numberOfNewPlayers > 60 && numberOfNewPlayers < 100) {
        //     return;
        // }
        // address[] memory players = new address[](4);
        // players[0] = playerOne;
        // players[1] = playerTwo;
        // players[2] = playerThree;
        // players[3] = playerFour;
        // puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
        // console.log("Balance of the contract after entering: ", address(puppyRaffle).balance);

        //adding more players
        uint256 numberOfNewPlayers = 186;

        address[] memory newPlayers = new address[](numberOfNewPlayers);
        for (uint256 i = 0; i < numberOfNewPlayers; i++) {
            newPlayers[i] = address(i);
        }
        // the starting gas remaining before player 1 enters
        puppyRaffle.enterRaffle{value: entranceFee * newPlayers.length}(newPlayers);
        console.log("Balance of the contract after entering: ", address(puppyRaffle).balance);
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);
        puppyRaffle.selectWinner();
        console.log("Balance of the contract after selecting: ", address(puppyRaffle).balance);
        //get the total fees after selecting winner
        console.log(
            "Total fees after selecting winner with ", newPlayers.length, " players is  ", puppyRaffle.totalFees()
        );

        //
    }

    function test_AuditCannotSelectWinnerAfterSomeRefunds() public playersEntered {
        // four players have already entered the raffle , check the modifier in this function
        //  two  new players enter and two players will be refunded
        address playerFive = makeAddr("5");
        address playerSix = makeAddr("6");
        address[] memory newplayers = new address[](2);
        newplayers[0] = playerFive;
        newplayers[1] = playerSix;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(newplayers);
        console.log("Balance of the contract after entering: ", address(puppyRaffle).balance);

        vm.startPrank(playerSix);
        puppyRaffle.refund(puppyRaffle.getActivePlayerIndex(playerSix));
        console.log("Balance of the contract after refunding:", address(puppyRaffle).balance);
        vm.stopPrank();

        vm.startPrank(playerFive);
        puppyRaffle.refund(puppyRaffle.getActivePlayerIndex(playerFive));
        console.log("Balance of the contract after refunding:", address(puppyRaffle).balance);
        vm.stopPrank();

        uint256 balanceBefore = address(playerFour).balance;
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPayout = ((entranceFee * 4) * 80 / 100);
        vm.expectRevert();
        puppyRaffle.selectWinner();
        // assertEq(address(playerFour).balance, balanceBefore + expectedPayout);
    }

    function test_AuditCannotSelectWinnerAfterExpectedWinnerHasGottenARefund() public playersEntered {
        // four players have already entered the raffle , check the modifier in this function
        //  two  new players enter
        // Due to weak RNG , we always know that the expected winner is player 4 , so will call a refund on player 4,
        // this means that even if the weak RNG has been solved , when a random winner is selected but the winner has gotten
        //  has a refund and does not stand a chance of winning  , the contract will fail to select the winner who are still in the raffle

        address playerFive = makeAddr("5");
        address playerSix = makeAddr("6");
        address[] memory newplayers = new address[](2);
        newplayers[0] = playerFive;
        newplayers[1] = playerSix;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(newplayers);
        console.log("Balance of the contract after entering: ", address(puppyRaffle).balance);

        vm.startPrank(playerFour);
        puppyRaffle.refund(puppyRaffle.getActivePlayerIndex(playerFour));
        console.log("Balance of the contract after refunding:", address(puppyRaffle).balance);
        vm.stopPrank();

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        vm.expectRevert();
        puppyRaffle.selectWinner();
    }
}
