// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ITreasury
 * @dev Interface for the Treasury contract that manages platform fees and treasury funds
 */
interface ITreasury {
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event FundsWithdrawn(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    function supportedTokens(address token) external view returns (bool);

    function supportedTokenList(uint256 index) external view returns (address);

    function initialize() external;

    function addSupportedToken(address _token) external;

    function removeSupportedToken(address _token) external;

    function getSupportedTokens() external view returns (address[] memory);

    function withdrawFunds(
        address _token,
        address _recipient,
        uint256 _amount
    ) external;
}
