// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "hardhat/console.sol";
import "./CryptoTicket.sol";

interface CryptoTicketInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function sold() external view returns (uint256 ammount);
}

error Roulette__OwnerFailure();
error Roulette__TransferFailure();
error Roulette__OwnerRightsFailure();
error Roulette__DetectedFailure();
error Roulette__ZeroingFailure();
error Roulette__OutOfRangeBet();
error Roulette__WrongSplitNumbers();

contract CryptotronRoulette is VRFConsumerBaseV2 {

    enum cryptoRouletteState {
        OPEN,
        CALCULATING
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    cryptoRouletteState private s_cryptoRouletteState;
    bytes32 private immutable i_gasLane;
    uint256 private s_lastTimeStamp;
    uint256 private recentResult;
    uint256[] private playersNum;
    uint256[] private numbers;
    uint[] private line1 = [1, 2, 3];
    uint[] private line2 = [4 , 5, 6];
    uint[] private line3 = [7 , 8, 9];
    uint[] private line4 = [10 , 11, 12];
    uint[] private line5 = [13 , 14, 15];
    uint[] private line6 = [16 , 17, 18];
    uint[] private line7 = [19 , 20, 21];
    uint[] private line8 = [22 , 23, 24];
    uint[] private line9 = [25 , 26, 27];
    uint[] private line10 = [28 , 29, 30];
    uint[] private line11 = [31 , 32, 33];
    uint[] private line12 = [34 , 35, 36];
    uint[] private dLine1 = [1, 2, 3, 4, 5, 6];
    uint[] private dLine2 = [4, 5, 6, 7, 8, 9];
    uint[] private dLine3 = [7, 8, 9, 10, 11, 12];
    uint[] private dLine4 = [10, 11, 12, 13, 14, 15];
    uint[] private dLine5 = [13, 14, 15, 16, 17, 18];
    uint[] private dLine6 = [16, 17, 18, 19, 20, 21];
    uint[] private dLine7 = [19, 20, 21, 22, 23, 24];
    uint[] private dLine8 = [22, 23, 24, 25, 26, 27];
    uint[] private dLine9 = [25, 26, 27, 28, 29, 30];
    uint[] private dLine10 = [28, 29, 30, 31, 32, 33];
    uint[] private dLine11 = [31, 32, 33, 34, 35, 36];
    uint[] private firstFour = [0, 1, 2, 3];
    uint[] private low = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
    uint[] private high = [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
    uint[] private redNums = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36];
    uint[] private blackNums = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35];
    uint[] private evenNums = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36];
    uint[] private oddNums = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35];
    uint[] private firstDozen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    uint[] private secondDozen = [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
    uint[] private thirdDozen = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
    uint[] private column1 = [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34];
    uint[] private column2 = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35];
    uint[] private column3 = [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36];
    uint[] private snake = [1, 5, 9, 12, 14, 16, 19, 23, 27, 30, 32, 34];
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 4;
    address payable public immutable owner;
    address private contractStraight;
    address private contractSplit;
    address private contractStreet;
    address private contractColumns;
    address private contractSnake;
    address private contractCorner;
    address private contractBascet;
    address private contractSixLine;
    address private contractFirstFour;
    address private contractLowOrHigh;
    address private contractRedOrBlack;
    address private contractEvenOrOdd;
    address private contractDozens;
    address payable private winner;
    address payable private player;
    address private immutable nullAddress = address(0x0);
    address private s_recentWinner;
    address[] private s_allWinners;
    address[] private s_funders;
    address[] private deprecatedContracts;
    bool private failure = false;

    event WinnerPicked(address indexed winner);
    event RequestedRouletteWinner(uint256 indexed requestId);
    event EnteredStraight(address indexed player);
    event EnteredSplit(address indexed player);
    event EnteredStreet(address indexed player);
    event EnteredCorner(address indexed player);
    event EnteredBascet(address indexed player);
    event EnteredSixLine(address indexed player);
    event EnteredFirstFour(address indexed player);
    event EnteredLowOrHigh(address indexed player);
    event EnteredRedOrBlack(address indexed player);
    event EnteredEvenOrOdd(address indexed player);
    event EnteredDozens(address indexed player);
    event EnteredColumns(address indexed player);
    event EnteredSnake(address indexed player);

    constructor(
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_cryptoRouletteState = cryptoRouletteState.OPEN;
        s_lastTimeStamp = block.timestamp;
        owner = payable(msg.sender);
        contractStraight = nullAddress;
        contractSplit = nullAddress;
        contractStreet = nullAddress;
        contractCorner = nullAddress;
        contractBascet = nullAddress;
        contractSixLine = nullAddress;
        contractFirstFour = nullAddress;
        contractLowOrHigh = nullAddress;
        contractRedOrBlack = nullAddress;
        contractEvenOrOdd = nullAddress;
        contractDozens = nullAddress;
        contractColumns = nullAddress;
    }

    function enterRouletteStraight(uint256 tokenId, uint64 number) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractStraight);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (number < 0 || number > 36) {
            revert Roulette__OutOfRangeBet();
        } else {
            player = payable(msg.sender);
            playersNum.push(number);
            roulette();
        }
        emit EnteredStraight(msg.sender);
    }

    function enterRouletteSplit(uint256 tokenId, uint64 firstNum, uint64 secondNum) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractSplit);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (firstNum == 0) {
            require(secondNum == 3 || secondNum ==2 || secondNum == 1, "");
        } else if (secondNum == 0) {
            require(firstNum == 3 || firstNum ==2 || firstNum == 1, "");
        } else if (firstNum != secondNum + 3 ||
                   firstNum != secondNum - 3 ||
                   firstNum != secondNum + 1 ||
                   firstNum != secondNum - 1) {
                       revert Roulette__WrongSplitNumbers();
                   } else if (firstNum == 4 ||
                              firstNum == 7 ||
                              firstNum == 10 ||
                              firstNum == 13 ||
                              firstNum == 16 ||
                              firstNum == 19 ||
                              firstNum == 22 ||
                              firstNum == 25 ||
                              firstNum == 28 ||
                              firstNum == 31 ||
                              firstNum == 34) {
                                  require(secondNum == firstNum + 1 ||
                                          secondNum == firstNum + 3 ||
                                          secondNum == firstNum - 3);
                              } else if (secondNum == 4 ||
                                         secondNum == 7 ||
                                         secondNum == 10 ||
                                         secondNum == 13 ||
                                         secondNum == 16 ||
                                         secondNum == 19 ||
                                         secondNum == 22 ||
                                         secondNum == 25 ||
                                         secondNum == 28 ||
                                         secondNum == 31 ||
                                         secondNum == 34) {
                                             require(firstNum == secondNum + 1 ||
                                                     firstNum == secondNum + 3 ||
                                                     firstNum == secondNum - 3);
                                         } else if (firstNum == 6 ||
                                                    firstNum == 9 ||
                                                    firstNum == 12 ||
                                                    firstNum == 15 ||
                                                    firstNum == 18 ||
                                                    firstNum == 21 ||
                                                    firstNum == 24 ||
                                                    firstNum == 27 ||
                                                    firstNum == 30 ||
                                                    firstNum == 33 ||
                                                    firstNum == 36) {
                                                        require(secondNum == firstNum - 1 ||
                                                                secondNum == firstNum + 3 ||
                                                                secondNum == firstNum - 3);
                                                    } else if  (secondNum == 6 ||
                                                                secondNum == 9 ||
                                                                secondNum == 12 ||
                                                                secondNum == 15 ||
                                                                secondNum == 18 ||
                                                                secondNum == 21 ||
                                                                secondNum == 24 ||
                                                                secondNum == 27 ||
                                                                secondNum == 30 ||
                                                                secondNum == 33 ||
                                                                secondNum == 36) {
                                                                    require(firstNum == secondNum - 1 ||
                                                                            firstNum == secondNum + 3 ||
                                                                            firstNum == secondNum - 3);
                                                                } else if (firstNum == 1 ||
                                                                           firstNum == 2 ||
                                                                           firstNum == 3) {
                                                                               require(secondNum == 0 ||
                                                                                       secondNum == firstNum + 3 ||
                                                                                       secondNum == firstNum + 1 ||
                                                                                       secondNum == firstNum -1);
                                                                           } else if (secondNum == 1 ||
                                                                                      secondNum == 2 ||
                                                                                      secondNum == 3) {
                                                                                          require(firstNum == 0 ||
                                                                                                  firstNum == secondNum + 3 ||
                                                                                                  firstNum == secondNum + 1 ||
                                                                                                  firstNum == secondNum -1);
                                                                                      } else if (firstNum == 34 ||
                                                                                                 firstNum == 35 ||
                                                                                                 firstNum == 36) {
                                                                                                     require(secondNum == firstNum - 3 ||
                                                                                                             secondNum == firstNum + 1 ||
                                                                                                             secondNum == firstNum - 1);
                                                                                                 }
                                                                                                 player = payable(msg.sender);
                                                                                                 playersNum.push(firstNum);
                                                                                                 playersNum.push(secondNum);
                                                                                                 roulette();
                                                                                                 emit EnteredSplit(msg.sender);
    }

    function enterRouletteStreet(uint256 tokenId, uint64 line) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractStreet);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (line == 1) {
            playersNum = line1;
        } else if (line == 2) {
            playersNum = line2;
        } else if (line == 3) {
            playersNum = line3;
        } else if (line == 4) {
            playersNum = line4;
        } else if (line == 5) {
            playersNum = line5;
        } else if (line == 6) {
            playersNum = line6;
        } else if (line == 7) {
            playersNum = line7;
        } else if (line == 8) {
            playersNum = line8;
        } else if (line == 9) {
            playersNum = line9;
        } else if (line == 10) {
            playersNum = line10;
        } else if (line == 11) {
            playersNum = line11;
        } else if (line == 12) {
            playersNum = line12;
        }
        roulette();
        emit EnteredStreet(msg.sender);
    }

    function enterRouletteCorner(uint256 tokenId, uint32 numberOfCorner) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractCorner);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        }
        require(numberOfCorner == 0 ||
                numberOfCorner == 1 ||
                numberOfCorner == 2 ||
                numberOfCorner == 4 ||
                numberOfCorner == 5 ||
                numberOfCorner == 7 ||
                numberOfCorner == 8 ||
                numberOfCorner == 10 ||
                numberOfCorner == 11 ||
                numberOfCorner == 13 ||
                numberOfCorner == 14 ||
                numberOfCorner == 16 ||
                numberOfCorner == 17 ||
                numberOfCorner == 19 ||
                numberOfCorner == 20 ||
                numberOfCorner == 22 ||
                numberOfCorner == 23 ||
                numberOfCorner == 25 ||
                numberOfCorner == 26 ||
                numberOfCorner == 28 ||
                numberOfCorner == 29 ||
                numberOfCorner == 31 ||
                numberOfCorner == 32);
        uint64 n = numberOfCorner;
        uint64 firstNum = n;
        uint64 secondNum = n + 1;
        uint64 thirdNum = n + 3;
        uint64 fourthNum = n + 4;
        playersNum.push(firstNum);
        playersNum.push(secondNum);
        playersNum.push(thirdNum);
        playersNum.push(fourthNum);
        roulette();
        emit EnteredCorner(msg.sender);
    }

    function enterRouletteBascet(uint256 tokenId, uint8 firstNum, uint8 secondNum) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractBascet);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (firstNum == 1) {
            require(secondNum != 3);
        } else if (firstNum == 3) {
            require(secondNum != 1);
        } else if (secondNum == 1) {
            require(firstNum != 3);
        } else if (secondNum == 3) {
            require(firstNum != 1);
        } else if (firstNum == 2) {
            require(secondNum == 1 ||
                    secondNum ==3);
        } else if (secondNum == 2) {
            require(firstNum == 1 ||
                    firstNum == 3);
        }
        uint8 thirdNum = 0;
        playersNum.push(firstNum);
        playersNum.push(secondNum);
        playersNum.push(thirdNum);
        roulette();
        emit EnteredBascet(msg.sender);
    }

    function entreRouletteSixLine(uint256 tokenId, uint64 numberOfSixLine) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractSixLine);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (numberOfSixLine == 1) {
            playersNum = dLine1;
        } else if (numberOfSixLine == 2) {
            playersNum = dLine2;
        } else if (numberOfSixLine == 3) {
            playersNum = dLine3;
        } else if (numberOfSixLine == 4) {
            playersNum = dLine4;
        } else if (numberOfSixLine == 5) {
            playersNum = dLine5;
        } else if (numberOfSixLine == 6) {
            playersNum = dLine6;
        } else if (numberOfSixLine == 7) {
            playersNum = dLine7;
        } else if (numberOfSixLine == 8) {
            playersNum = dLine8;
        } else if (numberOfSixLine == 9) {
            playersNum = dLine9;
        } else if (numberOfSixLine == 10) {
            playersNum = dLine10;
        } else if (numberOfSixLine == 11) {
            playersNum = dLine11;
        }
        roulette();
        emit EnteredSixLine(msg.sender);
    }

    function enterRouletteFirstFour(uint256 tokenId) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractFirstFour);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        }
        playersNum = firstFour;
        roulette();
        emit EnteredFirstFour(msg.sender);
    }

    function enterRouletteLowOrHIgh(uint256 tokenId, uint256 lowOrHigh) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractLowOrHigh);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (lowOrHigh >= 0) {
            require(lowOrHigh <= 18, "");
            playersNum = low;
        } else if (lowOrHigh >= 19) {
            require(lowOrHigh <= 36);
            playersNum = high;
        }
        roulette();
        emit EnteredLowOrHigh(msg.sender);
    }

    function enterRouletteRedOrBlack(uint256 tokenId, uint8 redOrBlack) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractRedOrBlack);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (redOrBlack == 0) {
            playersNum = redNums;
        } else if (redOrBlack == 1) {
            playersNum = blackNums;
        }
        roulette();
        emit EnteredRedOrBlack(msg.sender);
    }

    function enterRouletteEvenOrOdd(uint256 tokenId, uint8 evenOrOdd) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractEvenOrOdd);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (evenOrOdd % 2 == 0) {
            playersNum = evenNums;
        } else if (evenOrOdd % 2 != 0) {
            playersNum = oddNums;
        }
        roulette();
        emit EnteredEvenOrOdd(msg.sender);
    }

    function enterRouletteDozens(uint256 tokenId, uint8 dozen) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractDozens);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (dozen == 1) {
            playersNum = firstDozen;
        } else if (dozen == 2) {
            playersNum = secondDozen;
        } else if (dozen == 3) {
            playersNum = thirdDozen;
        }
        roulette();
        emit EnteredDozens(msg.sender);
    }

    function enterRouletteColumns(uint256 tokenId, uint8 column) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractColumns);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        } else if (column == 1) {
            playersNum = column1;
        } else if (column == 2) {
            playersNum = column2;
        } else if (column == 3) {
            playersNum = column3;
        }
        roulette();
        emit EnteredColumns(msg.sender);
    }

    function enterRouletteSnake(uint256 tokenId) public {
        CryptoTicketInterface cti = CryptoTicketInterface(contractSnake);
        if (cti.ownerOf(tokenId) != msg.sender) {
            revert Roulette__OwnerRightsFailure();
        }
        playersNum = snake;
        roulette();
        emit EnteredSnake(msg.sender);
    }

    function roulette() internal {
        s_cryptoRouletteState = cryptoRouletteState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRouletteWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, 
        uint256[] memory randomWords
    ) internal override {
        uint256 rouletteNumber = randomWords[0] % 37;
        recentResult = rouletteNumber;
        for (uint i = 0; i < playersNum.length; i++) {
            if (rouletteNumber == playersNum[i]) {
                winner = player;
            }
        }
        s_recentWinner = winner;
        s_allWinners.push(winner);
        (bool success, ) = winner.call{value: 35}("");
        if (!success) {
            failure = true;
            revert Roulette__TransferFailure();
        }
        playersNum = new uint256[](0);
        s_lastTimeStamp = block.timestamp;
        s_cryptoRouletteState = cryptoRouletteState.OPEN;
        emit WinnerPicked(winner);
    }
    
    function getCryptoFlipBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getCryptoRouletteState() public view returns (cryptoRouletteState) {
        return s_cryptoRouletteState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLastTimestamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getWinners() public view returns (address[] memory) {
        return s_allWinners;
    }

    function isFailed() public view returns (bool) {
        return failure;
    }


}