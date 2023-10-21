// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

/**
 * @title IWindowCaveat
 * @author @nftchance <chance@utc24.io>
 */
interface IWindowCaveat {
    error WindowLackingDuration();
    error WindowLackingDays();
    error WindowLackingRepeatsEvery();
    error WindowLackingSufficientRepeatsEvery();
    error WindowLackingStartTime();
    error WindowLackingN();
    error WindowLackingHorizon();

    error WindowCaveatViolation();

    struct Period {
        uint32 startTime;
        uint32 endTime;
    }

    struct Window {
        Period[] periods;
    }

    /**
     * @notice Check whether or not the current time is within the
     *         the declared window of availability by the schedule.
     * @param $schedule The schedule to check.
     * @return $isWithinWindow Whether or not the current time is within the
     */
    function isWithinWindow(
        uint256 $schedule
    ) external view returns (bool $isWithinWindow);

    /**
     * @dev Determine the next N window openings for a given schedule.
     * @notice If you call this onchain you have sinned and you will not be forgiven.
     *         This is simply a utility function to help you determine and/or
     *         visualize the Openings of your schedule.
     * @param $schedule The schedule to check.
     * @param $n The number of window openings to return.
     * @return $windows The next N window openings.
     */
    function toWindows(
        uint256 $schedule,
        uint32 $n
    ) external view returns (Window[] memory $windows, uint32 cursor);

    /**
     * @dev Determine the active periods for a schedule window given a horizon
     *      to filter to the points at which the `daysOfWeek` condition
     *      is satisfied as a Window may contain multiple periods in which
     *      it can be settled.
     * @param $schedule The schedule to check.
     */
    function toWindow(
        uint256 $schedule
    ) external view returns (Window memory $window);
}
