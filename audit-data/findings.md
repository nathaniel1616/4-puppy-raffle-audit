### [S-#] `PuppyRaffe::enterRaffle` function has unbounded loop  leading to a potential Denial of Service(DoS) attack , increasing the gas costs  for future entrace

**Description:** `PuppyRaffe::enterRaffle` function has  a for loop that is unbounded, an attacker can enter the raffle with a large number of array causing a spike in gas for subsequent calls.

<details> <summary>Code Snippet in `PuppyRaffe::enterRaffle`</summary>

```javascript

 @>>       for (uint256 i = 0; i < players.length - 1; i++) {
            for (uint256 j = i + 1; j < players.length; j++) {
                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
            }
        }
        emit RaffleEnter(newPlayers);
    }

```
</details>


**Impact:** The gast cost for  raffle entrants wil greatly increase as more players enter the raffle .Discourgaging later users from entering, and cuasing a rush at the start of a raffle to be aone of the first enterants in the queue.An attacker can enter the raffle with a large number of players at the start which will cause a spike in gas costs , preventing others users from using garanting a win

**Proof of Concept:**  It is possible to enter the raffle with a large number of players if the attacker is well funded. Moreover legitimate users can overwhelm cause a DDoS when the array to loop become very large

The test code in `PuppyRaffleTest::testAuditPoC_DoS` shows the raise in gas Cost after more large numbers of players have entered the contract
<details>

<summary>Code Snippet in `PuppyRaffleTest::testAuditPoC_DoS` 
</summary>

``` javascript
function testAuditPoC_DoS() public {
        uint256 numberOfNewPlayers = 100;
        address[] memory newPlayers = new address[](numberOfNewPlayers);
        for (uint256 i = 0; i < numberOfNewPlayers; i++) {
            newPlayers[i] = address(i);
        }
        uint256 gasStart = gasleft();

        puppyRaffle.enterRaffle{value: entranceFee * newPlayers.length}(newPlayers);
       uint256 gasEnd = gasleft();

@>>         uint256 gasUsedFirst = gasStart - gasEnd;
        console.log("GasUsed by player 1 after entering raffle is: ", gasUsedFirst);

        // a second player enters the raffle

        address[] memory newPlayers2 = new address[](numberOfNewPlayers);
        for (uint256 i = 0; i < numberOfNewPlayers; i++) {
            newPlayers2[i] = address(i + numberOfNewPlayers);
        }
        uint256 gasStart2 = gasleft();

        puppyRaffle.enterRaffle{value: entranceFee * newPlayers.length}(newPlayers2);
        uint256 gasEnd2 = gasleft();

@>>      uint256 gasUsedSeecond = gasStart2 - gasEnd2;
        console.log("GasUsed by player 2 after entering raffle is: ", gasUsedSeecond);
        assert(gasUsedSeecond > gasUsedFirst);
    }

```
</details>


**Recommended Mitigation:**  Therea are few recommendations.
1. Consider allowing the duplicates.Users can make new wallet addresses anyways, so a check doesnt prevent the same person from entering multiiple times in the raffle.
2. Use a mapping instead of a list 


```solidity
mapping (address Player => bool hasEntered) PlayersEntered;
for (uint256 i = 0; i < players.length - 1; i++) {
    if (PlayersEntered[players[i]]) {revert("PuppyRaffle: Duplicate player");}
}
```


### [S-#] `PuppyRaffle::refund` function sends out ether before updating the  user  balance causing a possible ReEntrancy attack

**Description:** `PuppyRaffle::refund` function sends out ether before updating the  user  balance causing a possible ReEntrancy attack. An attacker can reenter this function multiples times to receive ether till the contract balance is 0.
Also there is no  reentrancy guard in the `PuppyRaffle::refund` function to prevent it.

**Impact:** An attacker can drain all the funds in the raffle . The attacker steals all the funds deposited all users destroy the protocol.

**Proof of Concept:** This can be done with following

1. The attacker creates a contract `AttackerReentrancy`  which has a function called `attack`.This ``attack`` function deposit ether into the `PuppyRaffle` contract  and  then calls for refund at the same time.
2. During refund the attacker calls `PuppyRaffle::refund` function which sends out ether to the attacker contract
3. The attacker has a `AttackerReentrancy::receive` function which recieves ether from the `PuppyRaffle` contract and then calls `PuppyRaffle::refund` function again.
   
<details>   

<summary> This has be showed in the test code in `PuppyRaffleTest::testAuditPoC_Reentrancy` function 
</summary>

``` javascript	
  Balance of the PuppyRaffle before attack:  2000000000000000000
  Balance of the PuppyRaffle after attack:  0
  Balance of the attackContract after attack:  3000000000000000000 
```    

</details>

**Recommended Mitigation:** here are a few recommendations
 1. Consider adding  Openzeppelin Reentancy guard  for the `PuppyRaffle` contract. Then added a nonRentrant modifier to the `PuppyRaffle::refund` function.
 2. Consider updating the internal state (balances) before an  external calls .This follows the Checks,Effects and Interactins(CEI) pattern. This has been shown below
   ```diff
   
    function refund(uint256 playerIndex) public {
   
 
 +       players[playerIndex] = address(0);
        payable(msg.sender).sendValue(entranceFee);

  -      players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }
   ```


### [S-#] `PuppyRaffle::selectWinner` function has a precision loss when calculating the total fees causing  an inabilitiy to collect fees after the winner is selected

**Description:** `PuppyRaffle::selectWinner` function has a precision loss when it  calculates the  fee  by  type casting the total fees from uint256 to uint64 

``` javascript
  uint256 fee = (totalAmountCollected * 20) / 100;
@>  totalFees = totalFees + uint64(fee);
```
In solidity version < 0.8.0 , there is the  code here can cause an overflow leading to a reduction in the actual fees of the contract.


**Impact:**  The actual fees of the `Raffle` contract will be reduced which can cause an inabilitiy to collect fees after the winner is selected.

**Proof of Concept:**  This max uint of uint64 is 2*64 -1 afterward solidity version < 0.8.0 overflow and start count from zero. This can occur when the the fees collected are greater than 2^64 -1 which is approximately 18.4e**18 or   18.4 ethers  . So if the protocol has a fees above 18.4 ethers the fees overflow . 

Consider the code in the test code `PuppyRaffleTest::testAuditPoC_OverFlow` function 
We know fees is supposed to increase when the number of player increases.

1. you can set the number of players to  170, 180 ,184, 185 ,186

``` javascript
function testAuditPoC_OverFlow() public {
    /// code above
    @>        uint256 numberOfNewPlayers = 186;
    /// code below
```

2. Observe the logs of  by running 
```bash
forge test --mt testAuditPoC_OverFlow -vv
```



``` javascript
 Total fees after selecting winner with  170  players is  15553255926290448384

 Total fees after selecting winner with  184  players is  18353255926290448384

 Total fees after selecting winner with  185  players is  106511852580896768
 Total fees after selecting winner with  186  players is  306511852580896768 
```




**Recommended Mitigation:** 
1. use sathMath or solidity version >0.8.0
2. change the uint64  to uint256 in the code below.
```diff
-    uint64 public totalFees = 0;
+    uint256 public totalFees = 0;

- totalFees = totalFees + uint64(fee);
+ totalFees = totalFees + fee;       // fee in already uint256
```
   