// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { TheLastDegenStanding } from "../src/TheLastDegenStanding.sol";
import { TheParticipationTrophy } from "../src/TheParticipationTrophy.sol";
import { DegenPlayers } from "../src/APlayer.sol";
import { TLDSMetadata } from "../src/TLDSMetadata.sol";

import { IERC20 } from "../src/IERC20.sol";

contract LDS_Test is PRBTest, StdCheats {
    TheLastDegenStanding internal lds;
    DegenPlayers internal playerNFT;
    TLDSMetadata internal metadata;
    address internal degenWhale = 0x3C12B77aE8B7DD1FEB63D1D6a2A819AcdA0a41d2;
    address internal admin = 0xDe30040413b26d7Aa2B6Fc4761D80eb35Dcf97aD;
    address internal player1 = address(0xB0B);
    address internal player2 = address(0xB00B);
    address internal player3 = address(0xB00B13);
    address internal player4 = address(0xB00B135);
    // player 5 has playerNFT but doesnt have enough $degen
    address internal player5 = address(0xAB00BA);
    // player 6 doesnt have playerNFT but has enough $degen
    address internal player6 = address(0xAB00BA5);
    uint256 internal ticketPrice;
    IERC20 internal degen;

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl('baldchain'), 9145663);
        playerNFT = new DegenPlayers();
        metadata = new TLDSMetadata();
        lds = new TheLastDegenStanding(address(playerNFT), address(metadata));
        vm.prank(admin);
        playerNFT.setGame(address(lds));
        ticketPrice = lds.$TICKET_PRICE();
        degen = lds.$DEGEN();

        vm.startPrank(degenWhale);
        degen.transfer(player1, ticketPrice);
        degen.transfer(player2, ticketPrice);
        degen.transfer(player3, ticketPrice);
        degen.transfer(player4, ticketPrice);
        degen.transfer(player5, ticketPrice - 1);
        degen.transfer(player6, ticketPrice);
        vm.stopPrank();

        address[] memory players = new address[](5);
        players[0] = player1;
        players[1] = player2;
        players[2] = player3;
        players[3] = player4;
        players[4] = player5;
        vm.startPrank(playerNFT.admin());
        playerNFT.airdrop(players);
        vm.stopPrank();
    }

    function test_Join() external {
        joinPlayer(player1);
        assertEq(lds.ownerOf(0), player1);
        assertEq(degen.balanceOf(address(lds)), ticketPrice);
    }

    function testFail_JoinWithLowDegenBalance() external {
        joinPlayer(player5);
    }

    function testFail_JoinWithoutPlayerNFT() external {
        joinPlayer(player6);
    }

    function testFail_JoinAndTransferToNew() external {
        joinPlayer(player1);
        vm.prank(player1);
        lds.transferFrom(player1, player2, 0);
    }

    function testFail_JoinAndTransferToExisting() external {
        startGameWithPlayers();
        lds.transferFrom(player2, player1, 1);
    }

    function testFail_JoinMultipleTimes() external {
        joinPlayer(player1);
        joinPlayer(player1);
    }

    function testFail_JoinAfterStart() external {
        startGameWithPlayers();
        joinPlayer(player4);
    }

    function testFail_DeleteDegenMultipleTimes() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        uint256[] memory players = new uint256[](2);
        players[0] = 1;
        players[1] = 1;
        lds.deleteDegens(players);
    }

    function test_Gm() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 10 minutes);
        uint256 afterTime = block.timestamp;
        vm.prank(player1);
        lds.gm();
        assertEq(lds.getLastSeen(player1), afterTime);
    }

    function test_GmForFren() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 10 minutes);
        uint256 afterTime = block.timestamp;
        vm.prank(player1);
        lds.gm();
        assertEq(lds.getLastSeen(player1), afterTime);
    }

    function test_Delete() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        uint256[] memory players = new uint256[](1);
        players[0] = 1;
        lds.deleteDegens(players);
        assertEq(degen.balanceOf(player1), (ticketPrice * lds.$DELETE_FEE()) / 10_000);
    }

    function test_DeleteMultiple() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        uint256[] memory players = new uint256[](2);
        players[0] = 1;
        players[1] = 2;
        lds.deleteDegens(players);
        assertEq(degen.balanceOf(player1), ((ticketPrice * players.length) * lds.$DELETE_FEE()) / 10_000);
    }

    function test_Seppuku() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        lds.seppuku(0);
        assertEq(degen.balanceOf(player1), (ticketPrice * lds.$SEPPUKU_FEE()) / 10_000);
    }

    function test_Win() external {
        startGameWithPlayers();
        uint256 balanceBefore = degen.balanceOf(address(lds));
        vm.warp(block.timestamp + 48 hours);
        vm.startPrank(player1);
        uint256[] memory players = new uint256[](2);
        players[0] = 1;
        players[1] = 2;
        lds.deleteDegens(players);
        lds.win(0);
        vm.stopPrank();
        assertEq(degen.balanceOf(address(lds)), 0);
        assertEq(degen.balanceOf(player1), balanceBefore);
    }

    function testFail_StealWin() external {
        startGameWithPlayers();
        uint256 balanceBefore = degen.balanceOf(address(lds));
        vm.warp(block.timestamp + 48 hours);
        vm.startPrank(player1);
        uint256[] memory players = new uint256[](2);
        players[0] = 1;
        players[1] = 2;
        lds.deleteDegens(players);
        vm.stopPrank();
        lds.win(1);
    }

    function test_PrintTokenUris() external {
        startGameWithPlayers();
        string memory tokenUri = lds.tokenURI(0);
        emit LogNamedString("before ending game", tokenUri);
        vm.warp(block.timestamp + 48 hours);
        uint256[] memory players = new uint256[](2);
        players[0] = 1;
        players[1] = 2;
        vm.startPrank(player1);
        lds.deleteDegens(players);
        lds.win(0);
        tokenUri = lds.tokenURI(0);
        emit LogNamedString("after ending game", tokenUri);
        tokenUri = lds.$THE_PARTICIPATION_TROPHY().tokenURI(1);
        emit LogNamedString("first part trophy", tokenUri);
        tokenUri = lds.$THE_PARTICIPATION_TROPHY().tokenURI(2);
        emit LogNamedString("second part trophy", tokenUri);
    }

    function testGmFrequency() internal {
        startGameWithPlayers();
        assertEq(lds.getGmFrequency(), 1 days);
        vm.warp(block.timestamp + 1 days);
        assertEq(lds.getGmFrequency(), 1 days - 1 hours);
        vm.warp(block.timestamp + 10 days);
        assertEq(lds.getGmFrequency(), 1 days - 10 hours);
        vm.warp(block.timestamp + 23 days);
        assertEq(lds.getGmFrequency(), 1 days - 23 hours);
        vm.warp(block.timestamp + 24 days);
        assertEq(lds.getGmFrequency(), 1 hours);
        vm.warp(block.timestamp + 50 days);
        assertEq(lds.getGmFrequency(), 1 hours);
    }

    function startGameWithPlayers() internal {
        joinPlayer(player1);
        joinPlayer(player2);
        joinPlayer(player3);
        vm.warp(block.timestamp + lds.$DEGEN_COOLDOWN() + 1 hours);
        lds.startGame();
    }

    function joinPlayer(address player) internal {
        vm.startPrank(player);
        degen.approve(address(lds), ticketPrice);
        lds.join();
        vm.stopPrank();
    }
}
