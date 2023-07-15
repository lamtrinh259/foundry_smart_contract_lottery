## Layout of Contract

1. Version
2. Imports
3. Errors
4. Interfaces, Libraries, Contracts
5. Type Declarations
6. State Variables
7. Events
8. Modifiers
9. Functions

## Layout of Functions

1. Constructor
2. Receive function (if exists)
3. Fallback function (if exists)
4. External
5. Public
6. Internal
7. Private
8. View & Pure Functions

## Learned things
1. Custom error is more gas efficient than require statement
2. For Chainlink:
- Each keyHash is associated with a gas lane, and each gas lane has different maximum gas price.
- callbackGasLimit is the maximum amount of gas to use for the callback function
- requestConfirmations is the number of blocks need to go by, higher is more secure, but slower
- numWords is the number of random numbers that we're getting back. Minimum is 1.
3. I can check for function signature hex data on this online database: [openchain.xyz](https://www.openchain.xyz/)
E.g. type in 0xa21a23e4 to get the createSubscription() function
4. To install a library in Foundry (do not forget the --no-commit or else I will have trouble installing):
```bash
forge install <github_person_or_org_name/github_repo_name> --no-commit
forge install transmissions11/solmate --no-commit
```
5. For remapping, it's better to use just remappings.txt file to handle all the remappings. I don't need to use the remappings in foundry.toml file anymore, I can either delete it or comment it out.
6. Programmatically fund my Chainlink vrf subscription with this command:
```bash
forge script script/Interactions.s.sol:FundSubscription --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```
[Transaction link on Sepolia](https://sepolia.etherscan.io/tx/0xca9d8d78a996d07978257da3b7ac9aa1fd684fb47bb447efa9cdd85980826bdc)
7. To just to any particular test, use this command:
```bash
forge test --match-test <test_name>
forge test --match-test testCantEnterWhenRaffleIsCalculatin
```
8. To see how much coverage we have with our tests, we can use this command to generate a report:
```bash
forge coverage --report debug > coverage.txt
```
9. How to use fuzz testing: foundry will perform 256 tests by default. We can specify the seed with the --fuzz-seed flag. The seed is used to generate the random numbers for the fuzz testing. If we want to run the same tests again, we can use the same seed. If we want to run different tests, we can use a different seed.
```solidity
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed {
        // Checking all these numbers do not make sense
        // Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId, // Instead of specifying a number in the range 0 - 255
            address(raffle)
        );
    }
```
Sample output of 256 tests: [PASS] testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256) (runs: 256, μ: 78295, ~: 78295)
10. Levels of testing (in scale from small to large):
- Unit
- Integration
- Forked
- Staging <-- run tests on a mainnet/testnet
11.
