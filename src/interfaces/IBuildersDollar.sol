// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "interfaces/IPool.sol";
import {IRewardsController} from "interfaces/IRewardsController.sol";

/**
 * @title BuildersDollar - An ERC20 stablecoin fully collateralized by DAI
 * @notice Earns yield in Aave for the BuildersDollarchain Ecosystem
 */
interface IBuildersDollar {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a token is minted
    event Minted(address receiver, uint256 amount);
    /// @notice Emitted when a token is burned
    event Burned(address receiver, uint256 amount);
    /// @notice Emitted when the yield claimer is set
    event YieldClaimerSet(address yieldClaimer);
    /// @notice Emitted when the yield is claimed
    event ClaimedYield(uint256 amount);
    /// @notice Emitted when the rewards are claimed
    event ClaimedRewards(address[] rewardsList, uint256[] claimedAmounts);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the caller is not the yield claimer
    error OnlyClaimers();
    /// @notice Thrown when the claimed amount is zero
    error ClaimZero();
    /// @notice Thrown when the yield accrued is insufficient
    error YieldInsufficient();
    /// @notice Thrown when the claim rewards fails
    error ClaimRewardsFailedLowLevel();
    /// @notice Thrown when the claim rewards fails
    error ClaimRewardsFailed();
    /// @notice Thrown when the value is zero
    error ZeroValue();

    /*///////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the BuildersDollar contract
     * @param _yieldTribute The address of the 10% yield tribute
     * @param _token The address of the token to be used as collateral
     * @param _aToken The address of the aToken to be used as collateral
     * @param _pool The address of the pool to be used as collateral
     * @param _rewards The address of the rewards to be used as collateral
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     */
    function initialize(
        address _yieldTribute,
        address _token,
        address _aToken,
        address _pool,
        address _rewards,
        string memory _name,
        string memory _symbol
    ) external;

    /**
     * @notice Sets the yield claimer
     * @param _yieldClaimer The address of the yield claimer
     */
    function setYieldClaimer(address _yieldClaimer) external;

    /**
     * @notice Mints a token
     * @param _amount The amount of tokens to mint
     * @param _receiver The address of the receiver
     */
    function mint(uint256 _amount, address _receiver) external;

    /**
     * @notice Burns a token
     * @param _amount The amount of tokens to burn
     * @param _receiver The address of the receiver
     */
    function burn(uint256 _amount, address _receiver) external;

    /**
     * @notice Claims the yield
     * @param _amount The amount of yield to claim
     */
    function claimYield(uint256 _amount) external;

    /**
     * @notice Claims the rewards
     */
    function claimRewards() external;

    /**
     * @notice Rescues a token
     * @param _tok The address of the token to rescue
     * @param _amount The amount of tokens to rescue
     */
    function rescueToken(address _tok, uint256 _amount) external;

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the token
     * @return _token The token
     */
    function TOKEN() external view returns (IERC20 _token);

    /**
     * @notice Returns the aToken
     * @return _aToken The aToken
     */
    function A_TOKEN() external view returns (IERC20 _aToken);

    /**
     * @notice Returns the pool
     * @return _pool The pool
     */
    function POOL() external view returns (IPool _pool);

    /**
     * @notice Returns the rewards controller
     * @return _rewards The rewards controller
     */
    function REWARDS() external view returns (IRewardsController _rewards);

    /**
     * @notice Returns the yield claimer
     * @return _yieldClaimer The yield claimer
     */
    function yieldClaimer() external view returns (address _yieldClaimer);

    /**
     * @notice Returns the yield tribute
     * @return _yieldTribute The yield tribute
     */
    function yieldTribute() external view returns (address _yieldTribute);

    /**
     * @notice Returns the yield accrued
     * @return _yield The yield accrued
     */
    function yieldAccrued() external view returns (uint256 _yield);

    /**
     * @notice Returns the rewards accrued
     * @return _rewardsList The list of rewards
     * @return _unclaimedAmounts The list of unclaimed amounts
     */
    function rewardsAccrued()
        external
        view
        returns (address[] memory _rewardsList, uint256[] memory _unclaimedAmounts);
}
