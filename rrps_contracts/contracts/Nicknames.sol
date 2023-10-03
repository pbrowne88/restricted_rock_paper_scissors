// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




contract Nicknames {
    // Associate the nickname 
    // nicknamesToAddresses[nickname] = msg.sender;
    // addressesToNicknames[msg.sender] = nickname;

    //De-register address and nickname
    // nicknamesToAddresses[addressesToNicknames[player]] = address(0);
    // addressesToNicknames[player] = emptyString;

        //De-register address and nickname
        // nicknamesToAddresses[addressesToNicknames[msg.sender]] = address(0);
        // addressesToNicknames[msg.sender] = emptyString;

    // function challengeCommit(string memory challengeeNickname, bytes32 hash) public {
    //     if (nicknamesToAddresses[challengeeNickname] == address(0)) {revert NicknameNotFound();}
    //     challengeCommit(nicknamesToAddresses[challengeeNickname], hash);
    // }


    // function openCommit(string memory challengerNickname, uint cardType) public {
    //     if (nicknamesToAddresses[challengerNickname] == address(0)) {revert NicknameNotFound();}
    //     openCommit(nicknamesToAddresses[challengerNickname], cardType);
    // }


    // function reveal(string memory challengeeNickname, uint cardType, string calldata salt) public {
    //     if (nicknamesToAddresses[challengeeNickname] == address(0)) {revert NicknameNotFound();} 
    //     reveal(nicknamesToAddresses[challengeeNickname], cardType, salt);
    // }


    // function withdrawChallenge(string memory challengeeNickname) public {
    //     withdrawChallenge(nicknamesToAddresses[challengeeNickname]);
    // }


    // function withdrawOpenCommit(string memory challengerNickname) public {
    //     withdrawOpenCommit(nicknamesToAddresses[challengerNickname]);
    // }

        // function balanceOf(string memory nickname) public view returns(uint256, uint256, uint256, uint256){
    //     return(balanceOf(nicknamesToAddresses[nickname]));
    // }


    // function balanceOf(string memory nickname, uint256 id) internal view {
    //     balanceOf(nicknamesToAddresses[nickname], id);
    // }

}