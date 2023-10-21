// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import {INounsAuctionHouse} from "./interfaces/INounsAuctionHouse.sol";
import {INounsBidScheduler} from "./interfaces/INounsBidScheduler.sol";
import {INounsToken} from "./interfaces/INounsToken.sol";

import {Ownable} from "solady/src/auth/Ownable.sol";

/**
 * @title Nouns Bid Balances
 * @notice This contract is responsible for tracking the balances of users
 *         who have deposited money to be used for bidding on Nouns.
 * @author @nftchance <chance@utc24.io>
 */
abstract contract NounsBidBalances is INounsBidScheduler, Ownable {
    /// @dev Accessible interface to the active Nouns Auction House.
    INounsAuctionHouse public immutable auctionHouse;
    INounsToken public immutable nouns;

    /// @dev The hippest way to reference ETH with a token address.
    address private constant DOLPHIN_ETH =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev On bid execution, 0.0002% of the bid is sent to the protocol.
    /// @notice In effect, that means it costs < $5 to prevent thousands
    ///         in lost economic value and/or collection appraisal (RFV).
    uint256 private constant protocolFee = 2;

    /// @dev Details of which Noun is active.
    uint256 currentNoun;

    /// @dev Account for the last bid made on each Noun.
    mapping(uint256 => address) public bids;

    /// @dev Account for the money deposited by each user.
    mapping(address => uint256) public balances;

    constructor(address $auctionHouse, address $nouns, address $owner) {
        /// @dev Initialize the Auction House and Nouns interfaces.
        auctionHouse = INounsAuctionHouse($auctionHouse);
        nouns = INounsToken($nouns);

        /// @dev Initialize the owner.
        _initializeOwner($owner);
    }

    /**
     * @dev Handle when money is received on behalf of a user.
     * @param $onBehalf The address of the sender.
     * @param $value The amount of money received.
     */
    function _give(address $onBehalf, uint256 $value) internal {
        /// @dev Account for the money deposited by the sender.
        balances[$onBehalf] += $value;

        emit Given($onBehalf, $value);
    }

    /**
     * @dev Handle when money is received back from the Auction House.
     */
    function _receive() internal {
        /// @dev Prevent receiving funds from anyone other than the Auction House.
        if (msg.sender != address(auctionHouse))
            revert InsufficientExecutionPath();

        /// @dev Determine who the last bidder was.
        address winner = bids[currentNoun];

        /// @dev The winner in our hearts is not the winner on the field.
        delete bids[currentNoun];

        /// @dev Return the money to the hopeful winner.
        _give(winner, msg.value);
    }

    /**
     * @dev Use the money provided by the sender to bid on the current auction.
     * @param $onBehalf The address of the sender.
     * @param $value The amount of money to use.
     */
    function _use(address $onBehalf, uint256 $value) internal {
        /// @dev Make sure the sender has sufficient balance to cover the call.
        if (balances[msg.sender] < $value)
            revert InsufficientBalance({
                required: $value,
                available: balances[msg.sender]
            });

        /// @dev Get the current state of the auction.
        (
            uint256 $nounId,
            ,
            ,
            uint256 $endTime,
            address $bidder,
            bool $settled
        ) = auctionHouse.auction();

        /// @dev Prevent the user from bidding on an auction that they
        ///      have already won / are winning.
        if ($bidder == $onBehalf || $bidder == msg.sender)
            revert InsufficientReason();

        /// @dev If the auction has concluded and a new auction has not
        ///      been scheduled, then settle the active auction and create one.
        if ($endTime <= block.timestamp && $settled == false)
            auctionHouse.settleCurrentAndCreateNewAuction();

        /// @notice If the auction has not concluded, then bid on it.

        /// @dev Deduct the value from the sender's in-contract balance.
        balances[msg.sender] -= $value;

        /// @dev Calculate the protocol fee.
        uint256 protocolFeeValue = _valueToProtocolFee($value);

        /// @dev Transfer the protocol fee to the owner of the contract.
        balances[owner()] += protocolFeeValue;

        /// @dev Calculate the value to be used for bidding.
        uint256 nounValue = $value - protocolFeeValue;

        /// @dev If a Noun was won, but has not yet been transferred to
        ///      to the winner, then transfer it to the winner.
        if ($nounId > currentNoun && bids[currentNoun] != address(0))
            _take(bids[currentNoun], address(nouns), currentNoun);

        /// @dev Bid on the auction.
        auctionHouse.createBid{value: nounValue}($nounId);

        /// @dev Track the current noun.
        currentNoun = $nounId;

        /// @dev Set the bidder as the current winner of the auction.
        bids[$nounId] = $onBehalf;

        emit Used(msg.sender, $onBehalf, $value, $nounId);
    }

    /**
     * @dev Withdraw the money that the sender has deposited.
     * @param $onBehalf The address of the sender.
     * @param $value The amount of money to withdraw.
     */
    function _take(address $onBehalf, address $asset, uint256 $value) internal {
        /// @dev If the asset is ETH, then transfer the ETH to the sender.
        if ($asset == DOLPHIN_ETH) {
            /// @dev Make sure the sender has sufficient balance to cover the call.
            if (balances[msg.sender] < $value)
                revert InsufficientBalance({
                    required: $value,
                    available: balances[msg.sender]
                });

            balances[msg.sender] -= $value;

            (bool success, ) = $onBehalf.call{value: $value}("");

            if (!success) revert InsufficientExecutionPath();
        }
        /// @dev If the asset is Nouns, then transfer the Nouns to the sender.
        else if ($asset == address(nouns)) {
            /// @dev Confirm that the auction has been settled to this contract.
            if (nouns.ownerOf(currentNoun) != address(this))
                revert InsufficientBalance({
                    required: 1,
                    available: nouns.balanceOf(address(this))
                });

            /// @dev Make sure the sender or the onBehalf target was the winning bidder.
            if (bids[$value] == msg.sender || bids[$value] == $onBehalf)
                revert InsufficientBalance({required: 1, available: 0});

            /// @dev Remove the winning bid from circulation.
            delete bids[$value];

            nouns.transferFrom(address(this), $onBehalf, $value);
        }
        /// @dev If the asset is not ETH or Nouns, then revert.
        else revert InsufficientExecutionPath();

        emit Taken(msg.sender, $onBehalf, $asset, $value);
    }

    /**
     * @dev Calculate the amount to provide when calling the Bid Scheduler
     *      by accounting for the cost consumption of the:
     *          - Protocol fee.
     *          - Transaction execution fee.
     * @notice ie: If you want to bid $100, then you need to provide $100.20
     *         to the Bid Scheduler.
     */
    function _bidToValue(
        uint256 $bidValue
    ) internal pure returns (uint256 $executionValue) {
        $executionValue = ($bidValue * 10000) / (10000 - protocolFee);
    }

    function _valueToProtocolFee(
        uint256 $value
    ) internal pure returns (uint256) {
        return ($value * protocolFee) / 10000;
    }

    /**
     * @dev Transfer the protocol fee to the new owner.
     * @param $newOwner The address of the new owner.
     */
    function transferOwnership(
        address $newOwner
    ) public payable virtual override onlyOwner {
        /// @dev Transfer the protocol fee to the new owner.
        balances[$newOwner] += balances[owner()];

        /// @dev Wipe the protocol fee from the old owner.
        delete balances[owner()];

        super.transferOwnership($newOwner);
    }
}
