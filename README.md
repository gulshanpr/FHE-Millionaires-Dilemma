# Millionaires Dilemma

Finds max balance of participant without revealing there actual balance, computation happens on encrypted data.

## Demo

- Smart Contract and Test Overview
  [![Watch the video](https://img.youtube.com/vi/rRi7cJblBQU/hqdefault.jpg)](https://youtu.be/rRi7cJblBQU)

- Frontend Tour and integration

## How i replicated the setup?

I have cloned [lightning-rod](https://github.com/Inco-fhevm/lightning-rod) and [nextjs-template](https://github.com/Inco-fhevm/nextjs-template.git) templates of inco and just added my Contract [here](./contracts/src/MillionairesDilemma.sol) and added my Test file [here](./contracts/src/test/).

For building my contract from `contracts` dir i ran `forge build src/MillionairesDilemma.sol`

And for testing the contract functionality, cases and flow from the `contracts` dir i ran `forge test --match-path src/test/MillionairesDilemma.t.sol`, it logs:

```
Ran 9 tests for src/test/MillionairesDilemma.t.sol:TestMillionairesDilemma
[PASS] testAllDifferent() (gas: 1564248)
[PASS] testAllSame() (gas: 1631053)
[PASS] testIfAllValueCleanedAfterFindWhoIsRich() (gas: 1635329)
[PASS] testTwoMaxAndSameThirdMin() (gas: 1551221)
[PASS] testTwoMinAndSameThirdMax() (gas: 1544057)
[PASS] testUserCanAccessOwnBalance() (gas: 638629)
[PASS] test_RevertWhen_Participate_Less_Than_Three_People() (gas: 346022)
[PASS] test_RevertWhen_Participate_More_Than_Three_People() (gas: 1016225)
[PASS] test_RevertWhen_UnAuth_Access_Find_Who_Is_Rich() (gas: 540017)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 7.86ms (23.50ms CPU time)

Ran 1 test suite in 10.83ms (7.86ms CPU time): 9 tests passed, 0 failed, 0 skipped (9 total tests)
```

and for seeing the result/logs, `forge test --match-path src/test/MillionairesDilemma.t.sol -vvv`

And for frontend i have used inco [nextjs-starter-repo](https://github.com/Inco-fhevm/nextjs-template.git), change the things a little with minor tweaks. I've used the wallet adaptor as it is.

My main components exists in components [folder](./frontend/src/components/) and both the files the core of application
