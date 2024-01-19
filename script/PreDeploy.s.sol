// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { BaseScript } from './Base.s.sol';
import { DegenPlayers } from 'src/APlayer.sol';
import { TLDSMetadata } from 'src/TLDSMetadata.sol';

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract PreDeploy is BaseScript {
    function run() public broadcast {
        DegenPlayers d = new DegenPlayers();
        d.setImageURI('ipfs://bafkreie4gbmn3xmsxxxumjo6eyuof75wmhf5vtvpslez4skzn3qg7wwxiy');
        address[] memory players = new address[](1);
        players[0] = d.admin();
        d.airdrop(players);
        TLDSMetadata metadata = new TLDSMetadata();
    }
}
