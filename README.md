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
