# Foundry smart contract Raffle

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
11. How to debug at line level with Opcodes:
```bash
forge test --debug <test_name>
forge test --debug testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep
```
12. How to use [Chainlink Automation](https://automation.chain.link/) to perform Upkeep on Sepolia:
- Contract address: 0xdbfda4b19ff56230a75a11ef4011eaeb63181867, and typically contract needs to be verified
- Choose custom logic on Chainlink automation and enter the contract address
- Type in the Upkeep name and the amount of LINK to fund the Upkeep and confirm the transaction through wallet
- [Transaction went through](https://sepolia.etherscan.io/tx/0xb7dacc64d9ad0be1663b64b6c2acd96b764b7c6f4f118307800b256d09054e12)
- Can check the Upkeep info through the UI
- After deploying, can use the code below to enter the Raffle:
```bash
cast send $DEPLOYED_CONTRACT_ADDRESS "enterRaffle()" --value 0.03ether --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```
- [Successfully entered raffle transaction](https://sepolia.etherscan.io/tx/0xd0a18d88550519785fbce659979737f4ef97c0f48bb01d0fd823b076153db886)
13. How to verify contract on Etherscan [guide](https://docs.etherscan.io/v/sepolia-etherscan/api-endpoints/contracts):
<details>
<summary>13A. With the UI on Etherscan:</summary>
- Go to the contract address<br>
- Flatten the source code into one file<br>
- Upload the file and fill in necessary info<br>
- Verify<br>
</details>
<details>
<summary>13B. With the command line:</summary>
- Flatten the source code into one file<br>
- See Makefile to modify the detailed command<br>
- Run the command below<br>
<pre>
make verify_on_Sepolia
</pre>
</details>
