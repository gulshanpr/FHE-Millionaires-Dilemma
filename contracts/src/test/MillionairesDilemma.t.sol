// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {MillionairesDilemma} from "../MillionairesDilemma.sol";
import {IncoTest} from "@inco/lightning/src/test/IncoTest.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import {GWEI} from "@inco/shared/src/TypeUtils.sol";
import {euint256, ebool, e} from "@inco/lightning/src/Lib.sol";
import "forge-std/Vm.sol";

contract TestMillionairesDilemma is IncoTest {
    using e for *;

    MillionairesDilemma compareGame;

    function setUp() public override {
        // deploying mock inco infra
        super.setUp();
        compareGame = new MillionairesDilemma();
    }

    // for the case if participants balances would be
    // A - 100, B - 40, C - 100
    // in this its a tie bcoz max is 100 and two person has it
    function testTwoMaxAndSameThirdMin() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);

        // submit bytes as encrypted balance
        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(4));
        console.log("Bob submitted balance: 2");

        // if findWhoIsRich has not been called yet, then participants can update their e-balances
        // vm.prank(alice);
        // compareGame.submitBalance(fakePrepareEuint256Ciphertext(10));

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Eve submitted balance: 3");

        vm.prank(alice);
        compareGame.findWhoIsRich();
        console.log("Called compareWhoIsRich");

        // inco cheatcodes
        processAllOperations();
        console.log("Processed all operations");

        address winner = compareGame.richest();
        console.log("Richest address is:", winner);

        if (winner == alice) console.log("Winner is: Alice");
        else if (winner == bob) console.log("Winner is: Bob");
        else if (winner == eve) console.log("Winner is: Eve");
        else console.log("TIE!!");

        require(winner == 0x0000000000000000000000000000000000000099, "winner is not equal to 99 address");
    }

    // for the case if participants balances would be
    // A - 100, B - 400, C - 100
    // this case is opposite of above, as it has two same balance but a max exists
    function testTwoMinAndSameThirdMax() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);
        // address gulshan = address(5);

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(9));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Bob submitted balance: 2");

        // if findWhoIsRich has not been called yet, then participants can update their e-balances
        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(12));

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Eve submitted balance: 3");

        vm.prank(alice);
        compareGame.findWhoIsRich();
        console.log("Called compareWhoIsRich");

        processAllOperations();
        console.log("Processed all operations");

        address winner = compareGame.richest();
        console.log("Richest address is:", winner);

        if (winner == alice) console.log("Winner is: Alice");
        else if (winner == bob) console.log("Winner is: Bob");
        else if (winner == eve) console.log("Winner is: Eve");
        else console.log("TIE!!");

        require(winner == alice, "winner is not equal to 99 address");
    }

    // for the case if participants balances would be
    // A - 100, B - 40, C - 500
    // its a normal case where, everyone has different balance
    function testAllDifferent() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(10));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(100 * GWEI));
        console.log("Bob submitted balance: 2");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(1000 * GWEI));

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(15));
        console.log("Eve submitted balance: 3");

        vm.prank(alice);
        compareGame.findWhoIsRich();
        console.log("Called compareWhoIsRich");

        processAllOperations();
        console.log("Processed all operations");

        address winner = compareGame.richest();
        console.log("Richest address is:", winner);

        if (winner == alice) console.log("Winner is: Alice");
        else if (winner == bob) console.log("Winner is: Bob");
        else if (winner == eve) console.log("Winner is: Eve");
        else console.log("TIE!!");

        require(winner == bob, "winner is not equal to 99 address");
    }

    // for the case if participants balances would be
    // A - 100, B - 100, C - 100
    // its a tie case, if all participants has same balances, then a 99 index or address will logged
    function testAllSame() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Bob submitted balance: 2");

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Eve submitted balance: 3");

        vm.prank(alice);
        compareGame.findWhoIsRich();
        console.log("Called compareWhoIsRich");

        processAllOperations();
        console.log("Processed all operations");

        address winner = compareGame.richest();
        console.log("Richest address is:", winner);

        if (winner == alice) console.log("Winner is: Alice");
        else if (winner == bob) console.log("Winner is: Bob");
        else if (winner == eve) console.log("Winner is: Eve");
        else console.log("TIE!!");

        require(winner == 0x0000000000000000000000000000000000000099, "winner is not equal to 99 address");
    }

    // if more than 3 participants try to participate it together
    function test_RevertWhen_Participate_More_Than_Three_People() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);
        address gulshan = address(5);

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(8));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Bob submitted balance: 2");

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Eve submitted balance: 3");

        vm.expectRevert();
        vm.prank(gulshan);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(10));

        vm.prank(alice);
        compareGame.findWhoIsRich();
        console.log("Called compareWhoIsRich");
    }

    // if less then 3 participants has participated and some (who has acsess) call the findWhoIsRich
    function test_RevertWhen_Participate_Less_Than_Three_People() public {
        address alice = address(1);
        address bob = address(2);

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(8));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));
        console.log("Bob submitted balance: 2");

        vm.prank(alice);
        vm.expectRevert();
        compareGame.findWhoIsRich();
        console.log("Called compareWhoIsRich");
    }

    // only the folks who has participated has access to call the findWhoIsRich function
    // for better access control
    function test_RevertWhen_UnAuth_Access_Find_Who_Is_Rich() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);
        address gulshan = address(5);

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(10));
        console.log("Alice submitted balance: 1");

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(100 * GWEI));
        console.log("Bob submitted balance: 2");

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(120));

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(15));
        console.log("Eve submitted balance: 3");

        vm.prank(gulshan);
        vm.expectRevert();
        compareGame.findWhoIsRich();
    }

    // after anyone calls the findWhoIsRich, then the participants, balanceOf and hasSubmitted
    // will be cleaned for next round or user
    function testIfAllValueCleanedAfterFindWhoIsRich() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);

        // submitting balances
        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(6));

        vm.prank(alice);
        compareGame.findWhoIsRich();

        processAllOperations();

        address winner = compareGame.richest();
        console.log("Richest address is:", winner);

        require(winner == address(0x99), "winner is not equal to 0x99 address");

        require(!compareGame.hasSubmitted(alice), "Alice's hasSubmitted should be false");
        require(!compareGame.hasSubmitted(bob), "Bob's hasSubmitted should be false");
        require(!compareGame.hasSubmitted(eve), "Eve's hasSubmitted should be false");

        uint256 aliceDecrypted = getUint256Value(compareGame.balanceOf(alice));
        uint256 bobDecrypted = getUint256Value(compareGame.balanceOf(bob));
        uint256 eveDecrypted = getUint256Value(compareGame.balanceOf(eve));

        assertEq(aliceDecrypted, 0);
        assertEq(bobDecrypted, 0);
        assertEq(eveDecrypted, 0);

        require(compareGame.getParticipantsLength() == 0, "Participants array not cleared");
    }

    // then anyone input there bytes encrypted balance,
    // checking if they can access there own balance
    function testUserCanAccessOwnBalance() public {
        address alice = address(1);
        address bob = address(2);
        address eve = address(3);

        uint256 aliceBalance = 10 * GWEI;
        uint256 aliceBalance2 = 100 * GWEI;
        uint256 bobBalance = 20;
        uint256 eveBalance = 30 * GWEI;

        // Submit balances
        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(aliceBalance));

        vm.prank(bob);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(bobBalance));

        vm.prank(eve);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(eveBalance));

        vm.prank(alice);
        compareGame.submitBalance(fakePrepareEuint256Ciphertext(aliceBalance2));

        processAllOperations();

        // cheatcodes to bypass the access
        uint256 aliceDecrypted = getUint256Value(compareGame.balanceOf(alice));
        uint256 bobDecrypted = getUint256Value(compareGame.balanceOf(bob));
        uint256 eveDecrypted = getUint256Value(compareGame.balanceOf(eve));

        console.log("Decrypted Alice balance:", aliceDecrypted);
        console.log("Decrypted Bob balance:", bobDecrypted);
        console.log("Decrypted Eve balance:", eveDecrypted);

        assertEq(aliceDecrypted, aliceBalance2);
        assertEq(bobDecrypted, bobBalance);
        assertEq(eveDecrypted, eveBalance);
    }
}
