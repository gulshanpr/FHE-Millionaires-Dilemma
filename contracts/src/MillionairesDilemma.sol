// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {euint256, ebool, e} from "@inco/lightning/src/Lib.sol";

contract MillionairesDilemma {
    using e for euint256;
    using e for ebool;
    using e for uint256;
    using e for bytes;
    using e for address;

    // constants for the case where all participants have same balance
    // we assumed 99 because only their are 3 participants and so their will be 3 indexs, and they will be cleared after callback execution
    uint8 constant TIE_INDEX = 99;
    address constant TIE_ADDRESS = 0x0000000000000000000000000000000000000099;

    // mapping to store encrypted handles of each address
    mapping(address => euint256) public balanceOf;

    // mapping to keep track of, if participants is already submitted,
    // used to keep track of if user want to update their input again
    mapping(address => bool) public hasSubmitted;

    // three participant at a time for comparing encrypted balances
    address[] public participants;

    // richest among all participants
    address public richest;

    // variable to prevent replay attack, by calling callback mulitple times
    bool public isEvaluationInProgress;

    // This event is used to keep track of participant, if they updating their balance or
    // writing for the first time
    event SubmittedBalance(address indexed participant, bool isNew);

    // This event is used to emit the final winner or tie, with all participated participants
    event WhoIsTheMillionaire(address indexed winner, bool isTie, address[3] participants);

    /**
     * @notice Submits an encrypted balance using Inco's `euint256` type.
     * @dev If the sender is new, they are added to the list of participants.
     *      The contract is granted compute permission over the encrypted value.
     * @param encryptedBalance Encrypted balance submitted by smart contracts.
     */

    function submitBalance(euint256 encryptedBalance) external {
        // checks for if the euint that is already formed, caller has access to, prevent malformed e-type and ensures caller has access to the value
        require(msg.sender.isAllowed(encryptedBalance), "MillionairesDilemma: unauthorized value handle access");

        // tracking whether a participant is updating their balance of adding for the first time
        bool isNew = !hasSubmitted[msg.sender];

        // if new, then register
        if (isNew) {
            newParticipant();
        }

        // this ensures that contract has compute permission over e-types
        encryptedBalance.allowThis();

        balanceOf[msg.sender] = encryptedBalance;

        // allowing the sender to see their balance
        encryptedBalance.allow(msg.sender);

        // emitting event with participants address and if they updating or inputing for first time
        emit SubmittedBalance(msg.sender, isNew);
    }

    /**
     * @notice Submits an encrypted balance using Inco's JS SDK, in `bytes` form.
     * @dev If the sender is new, they are added to the list of participants.
     *      The contract is granted compute permission over the encrypted value.
     * @param valueInput Encrypted balance submitted by EOAs or smart wallets, created using @inco/js-sdk.
     */

    function submitBalance(bytes memory valueInput) external {
        // tracking whether a participant is updating their balance of adding for the first time
        bool isNew = !hasSubmitted[msg.sender];

        // used to create euint256 using encrypted input,
        // msg.sender will get the Reencryption write, it should be account that creating encrypted input
        euint256 encryptedBalance = valueInput.newEuint256(msg.sender);

        // if new, then register
        if (isNew) {
            newParticipant();
        }

        // this ensures that contract has compute permission over e-types
        encryptedBalance.allowThis();

        balanceOf[msg.sender] = encryptedBalance;

        // allowing the sender to see their balance
        encryptedBalance.allow(msg.sender);

        // emitting event with participants address and if they updating or inputing for first time
        emit SubmittedBalance(msg.sender, isNew);
    }

    // this will update a participant status, whether they are new or updating their already inputted balance
    function newParticipant() internal {
        // only 3 participant at a time for comparison
        require(participants.length < 3, "Only Alice, Bob, Eve allowed");

        // push the new guy to the participants (or participating state) for comparison
        participants.push(msg.sender);

        // update participant's state to participated
        hasSubmitted[msg.sender] = true;
    }

    /**
     * @notice Finds the participant with the highest encrypted balance.
     * @dev Only callable by one of the registered participants. Triggers a secure comparison and requests a decryption callback.
     */

    function findWhoIsRich() external {
        // to prevent the replay attack
        require(!isEvaluationInProgress, "Already evaluating");

        // this will prevent the race condition, that will call the function mulitple time before completing the async callback function
        isEvaluationInProgress = true;

        // compare and operate on 3 participant
        require(participants.length == 3, "3 Participants at a time");

        // only the participated participants can call this function (to prevent the unauth access)
        require(hasSubmitted[msg.sender], "Only participants can call this");

        // get all participants addresss
        address addressOfA = participants[0];
        address addressOfB = participants[1];
        address addressOfC = participants[2];

        // get their respect encrypted balances from mapping
        euint256 balanceOfA = balanceOf[addressOfA];
        euint256 balanceOfB = balanceOf[addressOfB];
        euint256 balanceOfC = balanceOf[addressOfC];

        // case-0 is to check if all balances are same if yes, assign 99 index
        ebool ab = balanceOfA.eq(balanceOfB);
        ebool bc = balanceOfB.eq(balanceOfC);
        ebool ca = balanceOfC.eq(balanceOfA);

        // chaining bitwise, to get 1 if all balances are same otherwise 0 (usual "and" operator)
        ebool allEqual = ab.and(bc).and(ca);

        // case-1 where two same values are greater then third
        euint256 maxAB = balanceOfA.max(balanceOfB);
        euint256 maxABC = maxAB.max(balanceOfC);

        // who matches the max
        ebool aIsMax = balanceOfA.eq(maxABC);
        ebool bIsMax = balanceOfB.eq(maxABC);
        ebool cIsMax = balanceOfC.eq(maxABC);

        // check if exactly two match max
        ebool aAndB = aIsMax.and(bIsMax).and(cIsMax.not());
        ebool bAndC = bIsMax.and(cIsMax).and(aIsMax.not());
        ebool cAndA = cIsMax.and(aIsMax).and(bIsMax.not());
        ebool exactlyTwoMax = aAndB.or(bAndC).or(cAndA);

        // comparing first and second participants encrypted balances
        ebool aOrB = balanceOfA.gt(balanceOfB);

        // using select for comparing encrypted types, because if/else will not compute over ebool and it will also leak info
        // assign index to first or second participant depanding on above compute
        euint256 aOrBIndex = aOrB.select(uint256(0).asEuint256(), uint256(1).asEuint256());

        // richest balance from first or second
        euint256 aOrBRichestBal = aOrB.select(balanceOfA, balanceOfB);

        // comparing first/second with third participant using greater than
        ebool abOrC = aOrBRichestBal.gt(balanceOfC);

        // assigning final index from first, second and third participant using select multiplexer pattern
        euint256 finalIndex = abOrC.select(aOrBIndex, uint256(2).asEuint256());

        // encoding 99 as euint for all case-0 if all participants balances are same
        euint256 allEqualIndex = uint256(TIE_INDEX).asEuint256();

        // if all balances are equal, decrypt TIE_INDEX (99) otherwise decrypt the winning index
        ebool isTie = allEqual.or(exactlyTwoMax);

        isTie.allow(msg.sender);
        isTie.allowThis();
        euint256 resultIndex = isTie.select(allEqualIndex, finalIndex);

        // grant decryption permission to caller
        resultIndex.allow(msg.sender);

        // grant decryption permission to the contract for decrypting the address for public view
        resultIndex.allowThis();

        // Encode addresses for callback with address and bool to show if its tie
        bytes memory encodedAddresses = abi.encode(addressOfA, addressOfB, addressOfC, isTie);

        // this will do public decryption or values it has right over
        resultIndex.requestDecryption(this.callback.selector, encodedAddresses);
    }

    /**
     * @notice Callback function automatically invoked by Inco Lightning after decryption asynchronously.
     * @dev Only Inco Lightning can call this function. It determines the richest participant
     *      based on the decrypted index and emits the final result.
     *      It also resets internal state to allow a new round of submissions.
     * @param winnerIndex The decrypted index indicating the richest participant
     *        (0, 1, 2) or the tie constant (99).
     * @param data ABI-encoded participant addresses (address a, address b, address c),
     *        passed during the `requestDecryption` call.
     */

    function callback(uint256, uint8 winnerIndex, bytes memory data) external {
        // storing 3 participants for emitting in event
        address[3] memory currentParticipants;

        // decoding the third data field for data and participants addresss
        (address a, address b, address c) = abi.decode(data, (address, address, address));

        // usual if/else block for comparing decoded index based on which richest variable will be assigned
        if (winnerIndex == TIE_INDEX) {
            richest = TIE_ADDRESS;
        } else if (winnerIndex == 0) {
            richest = a;
        } else if (winnerIndex == 1) {
            richest = b;
        } else richest = c;

        // making the hasSubmitted mapping to default as callback has executed and everything cleared
        hasSubmitted[a] = false;
        hasSubmitted[b] = false;
        hasSubmitted[c] = false;

        // assiging the participants to temp array of emitting event
        currentParticipants[0] = a;
        currentParticipants[1] = b;
        currentParticipants[2] = c;

        // reseting the participants array
        delete participants;

        // reseting the balance of address for next use
        balanceOf[a] = uint256(0).asEuint256();
        balanceOf[b] = uint256(0).asEuint256();
        balanceOf[c] = uint256(0).asEuint256();

        // resuming the replay attack variable to normal, for again execution
        isEvaluationInProgress = false;

        bool isTie = (winnerIndex == TIE_INDEX);
        // emitting the final event with Millionaire or tie and all particpated paritcipants
        emit WhoIsTheMillionaire(richest, isTie, currentParticipants);
    }

    // getter function for tests
    function getParticipantsLength() external view returns (uint256) {
        return participants.length;
    }
}
