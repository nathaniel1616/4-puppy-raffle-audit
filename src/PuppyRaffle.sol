// SPDX-License-Identifier: MIT
// @audit-q is this the right solidity version? Does it have any security vulnerabilities?
// @audit-q  should be be worried about overflow in solidity version  less than 0.8.0?
// @audit-q  should the get a specific version of solidity?
pragma solidity ^0.7.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Base64} from "lib/base64/base64.sol";

/// @title PuppyRaffle
/// @author PuppyLoveDAO
/// @notice This project is to enter a raffle to win a cute dog NFT. The protocol should do the following:
/// 1. Call the `enterRaffle` function with the following parameters:
///    1. `address[] participants`: A list of addresses that enter. You can use this to enter yourself multiple times, or yourself and a group of your friends.
/// 2. Duplicate addresses are not allowed
/// 3. Users are allowed to get a refund of their ticket & `value` if they call the `refund` function
/// 4. Every X seconds, the raffle will be able to draw a winner and be minted a random puppy
/// 5. The owner of the protocol will set a feeAddress to take a cut of the `value`, and the rest of the funds will be sent to the winner of the puppy.
contract PuppyRaffle is ERC721, Ownable {
    ////////////////////////////////////////////////////////////////////
    //                         LIBRARIES                              //
    ////////////////////////////////////////////////////////////////////

    using Address for address payable;

    ////////////////////////////////////////////////////////////////////
    //                         STATE VARIABLES                        //
    ////////////////////////////////////////////////////////////////////
    uint256 public immutable entranceFee;

    address[] public players; // @audit-q should this array be public? NO a private array would be better for gas
    uint256 public raffleDuration;
    uint256 public raffleStartTime;
    address public previousWinner;

    // We do some storage packing to save gas
    address public feeAddress;
    uint64 public totalFees = 0;

    // mappings to keep track of token traits
    mapping(uint256 => uint256) public tokenIdToRarity;
    mapping(uint256 => string) public rarityToUri;
    mapping(uint256 => string) public rarityToName;

    // Stats for the common puppy (pug)
    string private commonImageUri = "ipfs://QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8";
    uint256 public constant COMMON_RARITY = 70;
    string private constant COMMON = "common";

    // Stats for the rare puppy (st. bernard)
    string private rareImageUri = "ipfs://QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW";
    uint256 public constant RARE_RARITY = 25;
    string private constant RARE = "rare";

    // Stats for the legendary puppy (shiba inu)
    string private legendaryImageUri = "ipfs://QmYx6GsYAKnNzZ9A6NvEKV9nf1VaDzJrqDR23Y8YSkebLU";
    uint256 public constant LEGENDARY_RARITY = 5;
    string private constant LEGENDARY = "legendary";

    ////////////////////////////////////////////////////////////////////
    //                         EVENTS                                 //
    ////////////////////////////////////////////////////////////////////
    // Events
    event RaffleEnter(address[] newPlayers); // @audit-q should whole array be published as an event?
    event RaffleRefunded(address player);
    event FeeAddressChanged(address newFeeAddress);

    ///////////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                          //
    ////////////////////////////////////////////////////////////////////

    /// @param _entranceFee the cost in wei to enter the raffle
    /// @param _feeAddress the address to send the fees to
    /// @param _raffleDuration the duration in seconds of the raffle
    constructor(uint256 _entranceFee, address _feeAddress, uint256 _raffleDuration) ERC721("Puppy Raffle", "PR") {
        entranceFee = _entranceFee;
        feeAddress = _feeAddress;
        raffleDuration = _raffleDuration;
        raffleStartTime = block.timestamp;

        rarityToUri[COMMON_RARITY] = commonImageUri;
        rarityToUri[RARE_RARITY] = rareImageUri;
        rarityToUri[LEGENDARY_RARITY] = legendaryImageUri;

        rarityToName[COMMON_RARITY] = COMMON;
        rarityToName[RARE_RARITY] = RARE;
        rarityToName[LEGENDARY_RARITY] = LEGENDARY;
    }

    ///////////////////////////////////////////////////////////////////
    //                      PUBLIC FUNCTIONS                          //
    ////////////////////////////////////////////////////////////////////

    /// @notice this is how players enter the raffle
    /// @notice they have to pay the entrance fee * the number of players
    /// @notice duplicate entrants are not allowed
    /// @param newPlayers the list of players to enter the raffle
    // @audit-q should this function be public and not external?
    // @audit-q should the parameter be an array of addresses and not a single address?
    function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
        }

        // Check for duplicates
        // @audit-q should this be a separate function to make it more modular?
        // @audit-q can the loop cause an infinite loop? can mapping be a better data structure?

        for (uint256 i = 0; i < players.length - 1; i++) {
            for (uint256 j = i + 1; j < players.length; j++) {
                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
            }
        }
        emit RaffleEnter(newPlayers);
    }

    /// @param playerIndex the index of the player to refund. You can find it externally by calling `getActivePlayerIndex`
    /// @dev This function will allow there to be blank spots in the array
    //@audit-q should this function be public and not external?
    //@audit-q can EOA and Contract account call this function
    // @audit-q can a user get a refund at the same time as the winner is selected? is there a time lock on receiving a refund?
    function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
        // @audit-q should we send the value using the call function?
        // @audit-q should we send the value before deleting the player?
        // @audit-q does this follow the CEI pattern?
        // @audit-finding  Can this be a rentracy attack?
        payable(msg.sender).sendValue(entranceFee);

        players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }

    /////////////////////////////////////////////////
    //                 EXTERNAL FUNCTIONS         //
    /////////////////////////////////////////////////

    /// @notice a way to get the index in the array
    /// @param player the address of a player in the raffle
    /// @return the index of the player in the array, if they are not active, it returns 0
    function getActivePlayerIndex(address player) external view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return i;
            }
        }
        return 0;
    }

    /// @notice this function will select a winner and mint a puppy
    /// @notice there must be at least 4 players, and the duration has occurred
    /// @notice the previous winner is stored in the previousWinner variable
    /// @dev we use a hash of on-chain data to generate the random numbers
    /// @dev we reset the active players array after the winner is selected
    /// @dev we send 80% of the funds to the winner, the other 20% goes to the feeAddress
    //  @audit-q should this function be automatically called after the raffle duration?

    function selectWinner() external {
        require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
        // @audit-q should we use a require statement to check if the players array is empty?

        require(players.length >= 4, "PuppyRaffle: Need at least 4 players");
        // @audit-q Can this be truely random?
        // @audit-q can the winner be manipulated?
        // @audit-q should we use an oracle to get a random number? eg Chainlink VRF
        uint256 winnerIndex =
            uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty))) % players.length;
        address winner = players[winnerIndex];
        // @audit-q would totalAmountCollected be calculated with the entranceFee * players length?
        // @audit-q what if there haave been refunds , would the totalAmountCollected be correct? check the refund logic and natspec
        uint256 totalAmountCollected = players.length * entranceFee;
        uint256 prizePool = (totalAmountCollected * 80) / 100;
        uint256 fee = (totalAmountCollected * 20) / 100;
        // @audit-q should we use SafeMath here?
        // @audit-q can typecasting uint256 to uint64 cause any issues?
        // @audit-q when fee is greater than uint64, what happens?
        // @audit-qdev why was uint64 used here?
        totalFees = totalFees + uint64(fee);

        // @audit-q should we maintain a local balances tokenid supply?
        uint256 tokenId = totalSupply();

        // We use a different RNG calculate from the winnerIndex to determine rarity
        // @audit-q can this random number  be manipulated?
        uint256 rarity = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty))) % 100;
        if (rarity <= COMMON_RARITY) {
            tokenIdToRarity[tokenId] = COMMON_RARITY;
        } else if (rarity <= COMMON_RARITY + RARE_RARITY) {
            tokenIdToRarity[tokenId] = RARE_RARITY;
        } else {
            tokenIdToRarity[tokenId] = LEGENDARY_RARITY;
        }

        delete players;
        raffleStartTime = block.timestamp;
        previousWinner = winner;
        (bool success,) = winner.call{value: prizePool}("");
        require(success, "PuppyRaffle: Failed to send prize pool to winner");
        _safeMint(winner, tokenId);
    }

    /// @notice this function will withdraw the fees to the feeAddress
    // @audit-q can this function be parameterized? eg withdrawFees(uint256 amount)
    function withdrawFees() external {
        // @audit-q  what if the totalFees is not equal to the balance of the contract?
        // @audit-q   can withdrawl fees be locked down when the raffle is active?
        // @audit-q   can anyone call this function? should it be only the owner?
        // @audit-q  should any address to call this contract?
        // @audit-q  can withdrawl be called only after the raffle is over?
        // @audit-q  should  withdrawl be called inside the selectWinner function? Making it internal function
        require(address(this).balance == uint256(totalFees), "PuppyRaffle: There are currently players active!");
        uint256 feesToWithdraw = totalFees;
        totalFees = 0;
        (bool success,) = feeAddress.call{value: feesToWithdraw}("");
        require(success, "PuppyRaffle: Failed to withdraw fees");
    }

    /// @notice only the owner of the contract can change the feeAddress
    /// @param newFeeAddress the new address to send fees to
    function changeFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
        emit FeeAddressChanged(newFeeAddress);
    }

    ///////////////////////////////////////////////////////////////////
    //                      INTERNAL FUNCTIONS                       //
    ///////////////////////////////////////////////////////////////////

    /// @notice this function will return true if the msg.sender is an active player
    // @audit-q should this function be public and not internal?
    // @audit-q should this function be removed as it has not used in the code?
    function _isActivePlayer() internal view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /// @notice this could be a constant variable
    function _baseURI() internal pure returns (string memory) {
        return "data:application/json;base64,";
    }

    /// @notice this function will return the URI for the token
    /// @param tokenId the Id of the NFT
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "PuppyRaffle: URI query for nonexistent token");

        uint256 rarity = tokenIdToRarity[tokenId];
        string memory imageURI = rarityToUri[rarity];
        string memory rareName = rarityToName[rarity];

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "description":"An adorable puppy!", ',
                            '"attributes": [{"trait_type": "rarity", "value": ',
                            rareName,
                            '}], "image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
