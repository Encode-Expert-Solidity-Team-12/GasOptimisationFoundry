# GAS OPTIMSATION

- Your task is to edit and optimise the Gas.sol contract.
- You cannot edit the tests &
- All the tests must pass.
- You can change the functionality of the contract as long as the tests pass.
- Try to get the gas usage as low as possible.

## To run tests & gas report with verbatim trace

Run: `forge test --gas-report -vvvv`

## To run tests & gas report

Run: `forge test --gas-report`

## To run a specific test

RUN:`forge test --match-test {TESTNAME} -vvvv`
EG: `forge test --match-test test_onlyOwner -vvvv`

## Checklist for optimisations

### Basics

- [x] Understand the code
- [x] Understand the tests
- [x] Remove code/variables that are not needed
- [x] turn on optimizer (try few different values to find the best count)
- [x] use the latest version of compiler

### Loops

- [ ] break out of loops as soon as possible
- [ ] use fixed size array if length is known
- [ ] don't use storage variables in loops
- [ ] avoid unbounded loops
- [ ] don't use loop if not necessary. Can you predict the values without loop?

### Variables

- [ ] dont initialize variables to default value (not needed)
- [ ] correctly order || and &&, so that low cost is executed first and high cost operation not executed if not
  necessary

### Storage

- [ ] use storage only if necessary
- [ ] dont store intermediary storage, just final result
- [ ] use type with lowest size (example: uint16 instead of uint256). Be aware that uint8 will be padded when put to
  stack, so always measure.
- [ ] pack storage variables tightly - storage slots are warm or cold (never touched). Warm storage access is cheaper.
  Be aware that when you extend, child variable come after parents. Use sol2uml tool.
  If multiple variables are in 1 slot, the access will be cheaper.
- [ ] use storage pointers instead of copying arrays from storage to memory
- [ ] free unneeded storage (set it do default value (SSTORE) with to get gas refund)
- [ ] use bytes32 when possible, it is most optimized storage type
- [ ] use bytes instead of bytes[]
- [ ] choose smallest possible length (bytes1)
- [ ] use bytes32 instead of string
- [ ] use mapping instead of array because operations are cheaper (TEST IT OUT afterwards)
- [ ] if using smaller data types, array could be cheaper (most useful when working with large arrays)

### Memory

- [ ] restrict memory usage, cost goes up quadratically after first 724 bytes (so reuse memory)

### Logic and functions

- [ ] avoid repetitive checks (understand logic and flow of code)
- [ ] avoid public variables if you dont need getters
- [ ] reduce number of parameters - pack parameters to one parameter called data. In code you have to unpack them (
  additional computation)
- [ ] for all public function, input parameters are copied to memory automatically - if a function can be only
  external (not public), make it external - this way parameters are read from calldata directly
- [ ] order of the function affects cost when calling a function - move often called functions at the beginning (not
  order in code, but order of function hash - function selector) -
  tool: https://emn178.github.io/solidity-optimize-name/
- [ ] name return value of a function so that you don't need to create a local variable
- [ ] modifiers are inlined in functions (repeated for each function). Make it a function and call it at the
  beginning.
- [ ] when a public function of a lib is called, that byte code is not part of your contract. Think if it better to have
  bytecode in you contract or it is better to call the lib at runtime.
- [ ] use keccak for hashing

### Errors

- [ ] use custom error instead of require/revert strings (cheaper). If using strings, use as small as possible.
- [ ] us require instead of assert (assert only for special cases)

### Events

- [ ] k + unindexedBytes * a + indexedTopics * b  (k = 375, a = 8, b = 375)

### Advanced

- [ ] store data in events if possible (if you wont ever need it in the contract - timestamping) because it is cheaper
  than
  in storage
- [ ] put data in some kind of data structure like merkle tree
    - Airdrop example:
        * store addresses in a merkle tree off chain
        * have merkle root on chain
        * get the user to provide a merkle proof that their address is in the merkle tree
- [ ] storing data as contract byte code. You can create a contract where byte code is actually data that you want to
  store. When you want to use it, use EXTCODECOPY and use that code as data. This is cheaper than storage. It is read
  only.
