// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IPool} from "interfaces/IPool.sol";
import {IRewardsController} from "interfaces/IRewardsController.sol";
import {IBuildersDollar} from "interfaces/IBuildersDollar.sol";

contract BuildersDollar is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IBuildersDollar {
    using SafeERC20 for IERC20;

    /// @inheritdoc IBuildersDollar
    IERC20 public TOKEN;
    /// @inheritdoc IBuildersDollar
    IERC20 public A_TOKEN;
    /// @inheritdoc IBuildersDollar
    IPool public POOL;
    /// @inheritdoc IBuildersDollar
    IRewardsController public REWARDS;

    /// @inheritdoc IBuildersDollar
    address public yieldClaimer;

    /// @notice Modifier to check if the caller is the yield claimer
    modifier onlyYieldClaimer() {
        _checkYieldClaimer();
        _;
    }

    /// @inheritdoc IBuildersDollar
    function initialize(
        address _token,
        address _aToken,
        address _pool,
        address _rewards,
        string memory name,
        string memory symbol
    ) external initializer {
        TOKEN = IERC20(_token);
        A_TOKEN = IERC20(_aToken);
        POOL = IPool(_pool);
        REWARDS = IRewardsController(_rewards);
        __ERC20_init(name, symbol);
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
    }

    /// @inheritdoc IBuildersDollar
    function setYieldClaimer(address _yieldClaimer) external onlyOwner {
        yieldClaimer = _yieldClaimer;
        emit YieldClaimerSet(_yieldClaimer);
    }

    /// @inheritdoc IBuildersDollar
    function mint(uint256 _amount, address _receiver) external nonReentrant {
        if (_amount == 0) revert ZeroValue();
        TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        TOKEN.safeIncreaseAllowance(address(POOL), _amount);
        POOL.supply(address(TOKEN), _amount, address(this), 0);
        _mint(_receiver, _amount);
        emit Minted(_receiver, _amount);
    }

    /// @inheritdoc IBuildersDollar
    function burn(uint256 _amount, address _receiver) external nonReentrant {
        if (_amount == 0) revert ZeroValue();
        _burn(msg.sender, _amount);
        A_TOKEN.safeIncreaseAllowance(address(POOL), _amount);
        POOL.withdraw(address(TOKEN), _amount, _receiver);
        emit Burned(_receiver, _amount);
    }

    /// @inheritdoc IBuildersDollar
    function claimYield(uint256 _amount) external onlyYieldClaimer {
        if (_amount == 0) revert ClaimZero();
        uint256 yield = _yieldAccrued();
        if (yield < _amount) revert YieldInsufficient();
        POOL.withdraw(address(TOKEN), _amount, owner());
        emit ClaimedYield(_amount);

        try this.claimRewards() {}
        catch Error(string memory) {
            revert ClaimRewardsFailed();
        } catch (bytes memory) {
            revert ClaimRewardsFailedLowLevel();
        }
    }

    /// @inheritdoc IBuildersDollar
    function claimRewards() external nonReentrant {
        address[] memory _assets = new address[](1);
        _assets[0] = address(A_TOKEN);
        (address[] memory _rewardsList, uint256[] memory _claimedAmounts) = REWARDS.claimAllRewards(_assets, owner());

        emit ClaimedRewards(_rewardsList, _claimedAmounts);
    }

    /// @inheritdoc IBuildersDollar
    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(A_TOKEN), "BuildersDollar: cannot withdraw collateral");
        IERC20(_token).safeTransfer(owner(), _amount);
    }

    /// @inheritdoc IBuildersDollar
    function yieldAccrued() external view returns (uint256) {
        return _yieldAccrued();
    }

    /// @inheritdoc IBuildersDollar
    function rewardsAccrued() external view returns (address[] memory rewardsList, uint256[] memory unclaimedAmounts) {
        address[] memory assets;
        assets[0] = address(A_TOKEN);
        return REWARDS.getAllUserRewards(assets, address(this));
    }

    // --- Internal Utilities ---

    /**
     * @notice Returns the yield accrued by the contract
     * @return _yield yield accrued by the contract
     */
    function _yieldAccrued() internal view returns (uint256 _yield) {
        _yield = A_TOKEN.balanceOf(address(this)) - totalSupply();
    }

    /**
     * @notice Checks if the caller is the yield claimer
     */
    function _checkYieldClaimer() internal view virtual {
        if (yieldClaimer != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }
}
