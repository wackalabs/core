// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SocialToken.sol";

contract RoomBase {
    struct OpenedRoom {
        address roomID; // represents the creator social token contract
        bool isOpened;
        bool isClosed;
        uint256 startTime;
        uint256 endTime;
        uint256 usersCount;
    }

    mapping(address => OpenedRoom) public creatorRoomTracker;
    mapping(address => uint256) public creatorRewardTracker;

    // Creator start the audio room
    function startRoom(address _roomID) public {
        SocialToken socialToken = SocialToken(_roomID);
        require(msg.sender == socialToken.creator(), "Only creator can open the room");

        OpenedRoom memory room = OpenedRoom({
            roomID: _roomID,
            isOpened: true,
            isClosed: false,
            startTime: block.timestamp,
            endTime: block.timestamp,
            usersCount: 0
        });

        creatorRoomTracker[msg.sender] = room;
    }

    // Creator end the audio room
    function endRoom() public {
        OpenedRoom memory room = creatorRoomTracker[msg.sender];

        require(room.isOpened == true, "Room was not opened");
        require(room.isClosed == true, "Room was already closed");

        room.isClosed = true;
        room.endTime = block.timestamp;

        creatorRoomTracker[msg.sender] = room;

        //TODO: add reward points to the creator based on the room stats
        uint256 _reward = CalculateCreatorReward(room);
        creatorRewardTracker[msg.sender] += _reward;
    }

    // Users request to join the audio room
    function joinRoom(address roomID) public returns (bool) {
        SocialToken socialToken = SocialToken(roomID);
        address creator = socialToken.creator();
        OpenedRoom memory room = creatorRoomTracker[creator];

        require(room.isOpened == true, "Room was not opened");

        if (socialToken.balanceOf(msg.sender) > 0) {
            // allow user with more than one creator social token to enter
            creatorRoomTracker[creator].usersCount += 1;
            return true;
        }

        return false;
    }

    // based on the room stats give creator reward point that evloves the NFT
    function calculateCreatorReward(OpenedRoom memory _room) public pure returns (uint256) {
        uint256 reward = (_room.endTime - _room.startTime) * _room.usersCount;
        return reward;
    }
}
