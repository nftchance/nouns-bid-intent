// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import {NounsBidBalances} from "./NounsBidBalances.sol";

/**
 * @title Nouns Bid Scheduler
 * @notice This contract is responsible for scheduling bids on the Nouns Auction
 *         and trustlessly executing scheduled bids as well as handling
 *         the situations of being outbid as well as winning an auction
 *         with the help of an Intent based architecture.
 * @notice This contract is intended to solve the existing issue of the Nouns
 *         Ecosystem constantly being under attack by bots attempting to acquire
 *         the Noun for cheaper than they dump.
 * @author @nftchance <chance@utc24.io>
 */
contract NounsBidScheduler is NounsBidBalances {
    constructor(
        address $auctionHouse,
        address $nouns,
        address $owner
    ) NounsBidBalances($auctionHouse, $nouns, $owner) {}

    /**
     * @dev Give money to the contract to be used for bidding.
     * @param $onBehalf The address of the sender.
     */
    function deposit(address $onBehalf) public payable {
        _give($onBehalf, msg.value);
    }

    /**
     * @dev Use the money provised by the sender to bid on the current auction.
     * @param $onBehalf The address of the sender.
     */
    function use(address $onBehalf, uint256 $value) public {
        _use($onBehalf, $value);
    }

    /**
     * @dev Take an asset from the contract.
     * @param $onBehalf The address of the sender.
     * @param $asset The address of the asset to take.
     * @param $value Numerical representation of the relative asset id or size.
     */
    function take(address $onBehalf, address $asset, uint256 $value) public {
        _take($onBehalf, $asset, $value);
    }

    /**
     * @dev A previous bidder has been outbid and funds have been transferred
     *      to this contract. This function will be called by the auction
     *      Nouns Auction House to notify us of the outbid.
     */
    fallback() external payable {
        _receive();
    }

    /**
     * @dev This function is not intended to be called by anyone, not even
     *      the Nouns Auction House or the owner of this contract.
     */
    receive() external payable {
        _receive();
    }
}
