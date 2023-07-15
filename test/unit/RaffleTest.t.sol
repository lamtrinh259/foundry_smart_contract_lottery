// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /* Events need to be redefined in tests */
    event EnteredRaffle(address indexed player);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        console.log("Raffle address: %s", address(raffle));
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // enterRaffle //
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecrodsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    // test an event in Foundry
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        // https://book.getfoundry.sh/cheatcodes/expect-emit
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // set the block timestamp
        vm.roll(block.number + 1); // set the block number
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    // checkUpkeep //
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == false);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        // Act/Assert
        // We're expecting the selector below to fail with the specified parameters
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    // What if I need to test using the output of an event?
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEnteredAndTimePassed
    {
        // Act, use recordLogs to record all emitted events
        vm.recordLogs();
        raffle.performUpkeep(""); // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // The 2nd entry is the requestId, the 1st entry is the event emitted by requestRandomWords
        // The 0th index of topics is the event itself, so the 1st index is the requestId
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();
        // Assert
        assert(uint256(requestId) > 0); // make sure it was actually generated
        assert(uint256(rState) == 1); // make sure the state was updated
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    // fullfillRandomWords with fuzz testing //
    // this test will only run on Anvil
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed skipFork {
        // Checking all these numbers do not make sense
        // Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId, // Instead of specifying a number in the range 0 - 255
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        // Arrange
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address player = address(uint160(i)); // e.g. address(3)
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        // Act , pretend to be chainlink VRF to get a random number & pick a winner
        uint256 prize = entranceFee * (additionalEntrants + 1);
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        assert(uint256(raffle.getRaffleState()) == 0); // make sure the state was updated
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() > previousTimeStamp);
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_USER_BALANCE + prize - entranceFee
        );
    }
}
