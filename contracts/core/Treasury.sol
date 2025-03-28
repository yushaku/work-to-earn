// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ITreasury.sol";

/**
 * @title TreasuryContract
 * @dev Manages platform fees and treasury funds
 */
contract TreasuryContract is
    ITreasury,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    mapping(address => bool) public supportedTokens;
    address[] public supportedTokenList;

    /**
     * @dev Initializes the contract
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    /**
     * @dev Adds a new supported token
     * @param _token Address of the token to add
     */
    function addSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(!supportedTokens[_token], "Token already supported");

        supportedTokens[_token] = true;
        supportedTokenList.push(_token);

        emit TokenAdded(_token);
    }

    /**
     * @dev Removes a supported token
     * @param _token Address of the token to remove
     */
    function removeSupportedToken(address _token) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");
        supportedTokens[_token] = false;

        // Remove from supportedTokenList
        for (uint i = 0; i < supportedTokenList.length; i++) {
            if (supportedTokenList[i] == _token) {
                supportedTokenList[i] = supportedTokenList[
                    supportedTokenList.length - 1
                ];
                supportedTokenList.pop();
                break;
            }
        }

        emit TokenRemoved(_token);
    }

    /**
     * @dev Gets the list of supported tokens
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokenList;
    }

    /**
     * @dev Gets the balance of all supported tokens in the treasury
     */
    function getTokenBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev Withdraws tokens from the treasury
     * @param _token Address of the token to withdraw
     * @param _recipient Address to receive the tokens
     * @param _amount Amount of tokens to withdraw
     */
    function withdrawFunds(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");

        IERC20(_token).safeTransfer(_recipient, _amount);
        emit FundsWithdrawn(_token, _recipient, _amount);
    }

    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
}
