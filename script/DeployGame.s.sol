// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { BaseScript } from './Base.s.sol';
import { TheLastDegenStanding } from 'src/TheLastDegenStandingNoConstructor.sol';
import { TLDSMetadata } from 'src/TLDSMetadata.sol';
import { TheParticipationTrophy } from 'src/TheParticipationTrophy.sol';
import { DegenPlayers } from 'src/APlayer.sol';

/// remember to after deploying game

contract DeployGame is BaseScript {
    function run() public broadcast {
        DegenPlayers playerNFT = DegenPlayers(0x2DD58BeDC4A91110Bf9aF1d2bc3f13966d1C6643);
        TLDSMetadata metadata = TLDSMetadata(0xdfbE5E621A70873455b4435306a03d9eA1e3f2ad);
        string memory gameURI = "ipfs://bafkreifbf5d6xn6t5wzaebi42dqmi3drnhjpxksj7ssvixwkmscr2wwslm";
        //string memory trophyURI = "";

        TheParticipationTrophy trophy = TheParticipationTrophy(0x0DcDA7E9e5c5Ecd43bf047eA39B9833C3f42BA11);
        
        TheLastDegenStanding tlds = new TheLastDegenStanding();
        
        // do this after successful verification
        // trophy.setMinter(address(tlds));

        // playerNFT.setGame(address(tlds));
        // metadata.setGameImageURI(address(tlds), gameURI);
        //metadata.setTrophyURI(trophy, trophyURI);
    }
}
