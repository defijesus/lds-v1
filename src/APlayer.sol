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
*/

pragma solidity ^0.8.19;

import { ERC721 } from "solady/tokens/ERC721.sol";
import { TheParticipationTrophy } from "./TheParticipationTrophy.sol";
import { Helpers } from "./Helpers.sol";
import { IERC20 } from "./IERC20.sol";

contract DegenPlayers is ERC721 {
    
    uint256 public numPlayers = 1;
    address public admin = 0xDe30040413b26d7Aa2B6Fc4761D80eb35Dcf97aD;
    address public currentGame;
    string public imageURI;

    mapping(uint256 => string) public names;
    mapping(address => uint256) public gamesPlayed;

    function airdrop(address[] calldata targets) public {
        require(msg.sender == admin);
        for (uint256 i = 0; i < targets.length;) {
            unchecked {
                super._mint(targets[i], numPlayers++);
                ++i;
            }
        }
    }

    /// Justin Case
    function gibAdmin(address newAdmin) public {
        require(msg.sender == admin);
        admin = newAdmin;
    }

    function setGame(address newGame) public {
        require(msg.sender == admin);
        currentGame = newGame;
    }

    function setImageURI(string memory newImage) public {
        require(msg.sender == admin);
        imageURI = newImage;
    }

    function playedGame(address player) public {
        require(msg.sender == currentGame);
        gamesPlayed[player]++;
    }

    function setName(uint256 playerId, string calldata newName) public {
        require(msg.sender == super.ownerOf(playerId));
        names[playerId] = newName;
    }

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "DEGEN PLAYERS";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "DEGEN";
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
                        getDescription(gamesPlayed[super.ownerOf(tokenId)]),
                        '", "image": "',
                        imageURI,
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }

    function getName(uint256 tokenId) internal view returns (string memory) {
        string memory customName = names[tokenId];
        if (keccak256(bytes(customName)) == keccak256("")) {
            return string(abi.encodePacked(
                'Degen Player #', 
                Helpers.toString(tokenId)
            ));
        }
        return customName;
    }

    function getDescription(uint256 numGames) internal pure returns (string memory) {
        return string(abi.encodePacked(
            'This degen participated in ', 
            Helpers.toString(numGames), 
            (numGames == 1 ? ' game.' : ' games.')
        ));
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        if (from == address(0)) {
            require(super.balanceOf(to) == 0);
        } else {
            require(to == address(0));
        }
    }

}