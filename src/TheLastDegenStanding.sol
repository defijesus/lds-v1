// VIRAL PUBLIC LICENSE
// Copyleft (ɔ) All Rights Reversed

// This WORK is hereby relinquished of all associated ownership, attribution and copy
// rights, and redistribution or use of any kind, with or without modification, is
// permitted without restriction subject to the following conditions:

// 1.	Redistributions of this WORK, or ANY work that makes use of ANY of the
// 	contents of this WORK by ANY kind of copying, dependency, linkage, or ANY
// 	other possible form of DERIVATION or COMBINATION, must retain the ENTIRETY
// 	of this license.
// 2.	No further restrictions of ANY kind may be applied.

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
          
       presents

  The Last Degen Standing

|-----------------------------------------------------------------------------|
         TD;CR
  (Too Degen; Can't Read)

STEP 1 - JOIN THE GAME
STEP 2 - START THE GAME (or wait for someone to start it for u)
STEP 3 - SAY GM EVERY 24 HOURS OR LESS
STEP 4 - DON'T GET DELETED
STEP 5 - WIN
|-----------------------------------------------------------------------------|

Rules are simple. 1 Player = 1 Degen = 1 Address = 1 Owner of a Soulbound NFT

Each Degen pays for the ticket to join the game. The ticket funds the prize pool minus a fee to the creator.

If a degen invites another degen, the first degen also collects a small fee from the ticket payment.

After no more degens join the game for a while, anyone can start the game.

When the game starts, EACH DEGEN HAS TO CALL THE GM FUNCTION BEFORE THE TIMER ENDS. Else they can, and WILL, be deleted.

The timer starts at 24 hours and decreases by 1 hour every day. After 24 days the timer stays constant at 1 hour.

This means that after 24 hours, you have 1 hour to call the gm function again, if you don't another degen can game over you.

You can say gm for your frens, if they are afk or something.

Deleting a degen pays the hunter a bounty.

If a degen wants to give up he can commit Seppuku and get a partial 10% refund. 

Last degen alive takes all the pooled eth.

good luck & have fun
*/

pragma solidity ^0.8.19;

import { ERC721 } from "solady/tokens/ERC721.sol";
import { TheParticipationTrophy } from "./TheParticipationTrophy.sol";
import { Helpers } from "./Helpers.sol";
import { TLDSMetadata } from "./TLDSMetadata.sol";
import { DegenPlayers } from "./APlayer.sol";
import { IERC20 } from "./IERC20.sol";

/// fees are expressed in bps 1%=100 3%=300 10%=1000 33%=3300
contract TheLastDegenStanding is ERC721 {

    /// constants
    uint256 public constant $TICKET_PRICE = 500_000 ether;
    uint256 public constant $ADMIN_FEE = 200;
    uint256 public constant $SEPPUKU_FEE = 1000;
    uint256 public constant $DELETE_FEE = 1000;
    uint256 public constant $DEGEN_COOLDOWN = 1 days;
    IERC20 public constant $DEGEN = IERC20(0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed);

    /// immutable
    TheParticipationTrophy public immutable $THE_PARTICIPATION_TROPHY;
    DegenPlayers public immutable $PLAYER_NFT;
    
    /// timestamps
    uint256 public $LAST_DEGEN_IN;
    uint256 public $GAME_STARTED;

    uint256 public $DEGENS_ALIVE;
    address public $ADMIN = 0xd32947Eac5b9A5c4b0a4968a0B87cd6d9cadf668;
    address public $WINNER;
    TLDSMetadata public $TLDS_METADATA;

    mapping(address player => uint256 timestamp) public $LAST_SEEN;

    error NOT_PLAYER();
    error ALREADY_PLAYING();
    error CANT_BE_DELETED();
    error CANT_START_GAME();
    error GAME_ENDED();
    error GAME_NOT_STARTED();
    error IS_NOT_OVER();
    error NOT_ADMIN();
    error ONLY_OWNER();
    error TOO_MANY();

    event NewDegen(address indexed degen);
    event GameStarted(uint256 timestamp);
    event GM(address indexed degen, uint256 timestamp);
    event DegensDeleted(address indexed hunter, uint256[] degens);
    event Seppuku(address indexed degen);
    event Winner(address indexed degen);

    modifier gameIsOngoing() {
        if ($GAME_STARTED == 0) {
            revert GAME_NOT_STARTED();
        }
        if ($WINNER != address(0)) {
            revert GAME_ENDED();
        }
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != $ADMIN) {
            revert NOT_ADMIN();
        }
        _;
    }

    constructor(address playerNFT, address metadata) {
        $PLAYER_NFT = DegenPlayers(playerNFT);
        $THE_PARTICIPATION_TROPHY = new TheParticipationTrophy();
        $TLDS_METADATA = TLDSMetadata(metadata);
        $LAST_DEGEN_IN = block.timestamp;
    }

    /// STEP 1 - JOIN THE GAME

    function join() public payable {
        if ($PLAYER_NFT.balanceOf(msg.sender) < 1) {
            revert NOT_PLAYER();
        }

        if (super.balanceOf(msg.sender) != 0 || $GAME_STARTED != 0) {
            revert ALREADY_PLAYING();
        }

        $LAST_DEGEN_IN = block.timestamp;

        super._mint(msg.sender, $DEGENS_ALIVE++);

        $DEGEN.transferFrom(msg.sender, address(this), $TICKET_PRICE);

        emit NewDegen(msg.sender);
    }

    /// STEP 2 - START THE GAME

    function startGame() public {
        if (
            $GAME_STARTED != 0 ||
            ($LAST_DEGEN_IN + $DEGEN_COOLDOWN) > block.timestamp
        ) {
            revert CANT_START_GAME();
        }
        $GAME_STARTED = block.timestamp;
        $DEGEN.transfer($ADMIN, (($TICKET_PRICE * $DEGENS_ALIVE) * $ADMIN_FEE) / 10_000);
        emit GameStarted(block.timestamp);
    }

    /// STEP 3 - SAY GM EVERY DAY

    function gm() public gameIsOngoing {
        $LAST_SEEN[msg.sender] = block.timestamp;
        emit GM(msg.sender, block.timestamp);
    }

    /// STEP 4 - DON'T GET DELETED

    /// to all searchooooors, pls delete all the degens
    function deleteDegens(uint256[] calldata tokenIds) public gameIsOngoing {
        if (tokenIds.length > 20) {
            revert TOO_MANY();
        }
        uint256 i = 0;
        for (; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            address owner = super.ownerOf(tokenId);
            if (getLastSeen(owner) + getGmFrequency() > block.timestamp) {
                revert CANT_BE_DELETED();
            }

            deleteDegen(owner, tokenId);

            unchecked {
                i++;
            }
        }
        
        unchecked {
            require($DEGEN.transfer(msg.sender, (($TICKET_PRICE * tokenIds.length) * $DELETE_FEE) / 10_000));
        }

        emit DegensDeleted(msg.sender, tokenIds);
    }

    function seppuku(uint256 tokenId) public gameIsOngoing {
        address owner = super.ownerOf(tokenId);

        if (owner != msg.sender) {
            revert ONLY_OWNER();
        }

        deleteDegen(owner, tokenId);

        unchecked {
            require($DEGEN.transfer(msg.sender, ($TICKET_PRICE * $SEPPUKU_FEE) / 10_000));
        }

        emit Seppuku(msg.sender);
    }

    /// STEP 5 - WIN

    function win(uint256 tokenId) public gameIsOngoing {
        if ($DEGENS_ALIVE != 1) {
            revert IS_NOT_OVER();
        }

        address winner = super.ownerOf(tokenId);
        $WINNER = winner;

        require($DEGEN.transfer(winner, $DEGEN.balanceOf(address(this))));

        emit Winner(winner);
    }

    /// ONLY ADMIN ///
    function setTldsMetadata(address tldsMetadata) public onlyAdmin {
        $TLDS_METADATA = TLDSMetadata(tldsMetadata);
    }

    /// Justin Case
    function gibAdmin(address newAdmin) public onlyAdmin {
        $ADMIN = newAdmin;
    }

    /// ERC721 & VIEW ///
    function getLastSeen(address player) public view returns (uint256) {
        uint256 lastSeen = $LAST_SEEN[player];
        if (lastSeen == 0) {
            return $GAME_STARTED;
        }
        return lastSeen;
    }


    /// @dev every day that passes, players have less 1 hour to say gm 
    function getGmFrequency() public view returns (uint256) {
        uint256 daysPlayed = (block.timestamp - $GAME_STARTED) / 1 days;
        if (daysPlayed >= 24) {
            return 1 hours;
        } else {
            return 1 days - (daysPlayed * 1 hours);
        }
    }

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "THE LAST DEGEN STANDING";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "TLDS";
    }

    /// image URI might change as number of degens is reduced
    function tokenURI(uint256 tokenId) public view override returns (string memory output) {
        string memory json = Helpers.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        getName(tokenId),
                        '", "description": "',
                        getDescription(),
                        '", "image": "',
                        $TLDS_METADATA.getImageURI(tokenId),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }

    /// INTERNAL ///

    function getName(uint256 tokenId) internal view returns (string memory) {
        if ($WINNER == address(0)) {
            return string(abi.encodePacked("Degen #", Helpers.toString(tokenId)));
        }
        return "THE LAST DEGEN";
    }

    function getDescription() internal view returns (string memory) {
        if ($WINNER == address(0)) {
            return "This degen will never give up.";
        }
        return "This degen never gave up.";
    }

    function deleteDegen(address owner, uint256 tokenId) internal {
        require($DEGENS_ALIVE > 1);
        super._burn(tokenId);
        $THE_PARTICIPATION_TROPHY.mint(owner, tokenId);
        $DEGENS_ALIVE--;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        require((from == address(0) || (to == address(0))));
    }
}
