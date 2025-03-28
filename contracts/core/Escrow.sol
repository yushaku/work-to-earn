// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IEscrow.sol";
import "./interfaces/ITreasury.sol";

/**
 * @title Escrow
 * @dev Manages milestone-based escrow payments between clients and freelancers
 */
contract Escrow is IEscrow, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    uint256 constant WEI4 = 10 ** 4;
    using SafeERC20 for IERC20;

    uint256 public platformFeePercentage; // Fee percentage (in basis points, e.g., 100 = 1%)
    uint256 public timeoutPeriod; // Timeout period in seconds
    address public treasury; // Treasury contract address
    uint256 public projectCounter;

    mapping(uint256 => Project) public projects; // projectId => Project
    mapping(address => uint256[]) public userProjectIds; // user => projectId[]
    mapping(uint256 => Milestone[]) public milestones; // projectId => Milestone[]

    /**
     * @dev Initializes the contract
     * @param _treasury Address of the treasury contract
     */
    function initialize(address _treasury) public initializer {
        require(_treasury != address(0), "Invalid treasury address");
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
        platformFeePercentage = 500; // Default 5% fee
        timeoutPeriod = 7 days; // Default 7 days timeout period
        treasury = _treasury;
    }

    /**
     * Users function -----------------------------------------------------------------
     */

    function createProject(
        address _freelancer,
        address _token
    ) external returns (uint256) {
        require(_freelancer != address(0), "Invalid freelancer address");
        require(_token != address(0), "Invalid token address");
        require(
            ITreasury(treasury).supportedTokens(_token),
            "Token not supported"
        );

        uint256 projectId = projectCounter++;
        Project storage project = projects[projectId];
        project.client = msg.sender;
        project.freelancer = _freelancer;
        project.token = _token;

        emit ProjectCreated(projectId, msg.sender, _freelancer, _token, 0);

        return projectId;
    }

    function createMilestone(
        uint256 _projectId,
        uint256 _amount,
        uint256 _completionTime
    ) external {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.client,
            "Only client can create milestone"
        );
        require(_amount > 0, "Invalid milestone amount");
        require(_completionTime > block.timestamp, "Invalid completion time");

        uint256 milestoneIndex = milestones[_projectId].length;
        milestones[_projectId].push(
            Milestone({
                amount: _amount,
                completionTime: _completionTime,
                status: Status.Pending
            })
        );

        emit MilestoneCreated(
            _projectId,
            milestoneIndex,
            _amount,
            _completionTime
        );
    }

    function createBatchMilestones(
        uint256 _projectId,
        MilestoneInput[] calldata _milestones
    ) external {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.client,
            "Only client can create milestone"
        );
        require(_milestones.length > 0, "No milestones provided");

        uint256 startIndex = milestones[_projectId].length;

        for (uint256 i = 0; i < _milestones.length; i++) {
            require(_milestones[i].amount > 0, "Invalid milestone amount");
            require(
                _milestones[i].completionTime > block.timestamp,
                "Invalid completion time"
            );

            milestones[_projectId].push(
                Milestone({
                    amount: _milestones[i].amount,
                    completionTime: _milestones[i].completionTime,
                    status: Status.Pending
                })
            );

            emit MilestoneCreated(
                _projectId,
                startIndex + i,
                _milestones[i].amount,
                _milestones[i].completionTime
            );
        }

        if (startIndex == 0) {
            // Only add to userProjectIds if these are the first milestones
            userProjectIds[msg.sender].push(_projectId);
            userProjectIds[project.freelancer].push(_projectId);
        }
    }

    function fundMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex
    ) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(msg.sender == project.client, "Only client can fund");
        require(
            _milestoneIndex < milestones[_projectId].length,
            "Invalid milestone index"
        );
        require(
            milestones[_projectId][_milestoneIndex].status == Status.Pending,
            "Milestone already funded"
        );

        uint256 amount = milestones[_projectId][_milestoneIndex].amount;
        IERC20(project.token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        milestones[_projectId][_milestoneIndex].status = Status.InProgress;
        emit MilestoneFunded(_projectId, _milestoneIndex, amount);
    }

    function batchFundMilestones(
        uint256 _projectId,
        uint256[] calldata _milestoneIndexes
    ) external {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(msg.sender == project.client, "Only client can fund");
        require(_milestoneIndexes.length > 0, "No milestones provided");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _milestoneIndexes.length; i++) {
            uint256 index = _milestoneIndexes[i];
            require(
                index < milestones[_projectId].length,
                "Invalid milestone index"
            );
            require(
                milestones[_projectId][index].status == Status.Pending,
                "Milestone already funded"
            );

            totalAmount += milestones[_projectId][index].amount;
            milestones[_projectId][index].status = Status.InProgress;
            emit MilestoneFunded(
                _projectId,
                index,
                milestones[_projectId][index].amount
            );
        }

        IERC20(project.token).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
    }

    function completeMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex
    ) external {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.freelancer,
            "Only freelancer can complete milestone"
        );

        require(
            _milestoneIndex < milestones[_projectId].length,
            "All milestones completed"
        );
        require(
            milestones[_projectId][_milestoneIndex].status == Status.InProgress,
            "Invalid milestone status"
        );

        milestones[_projectId][_milestoneIndex].status = Status.Completed;
        emit MilestoneCompleted(_projectId, _milestoneIndex);
    }

    function batchCompleteMilestones(
        uint256 _projectId,
        uint256[] calldata _milestoneIndexes
    ) external {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.freelancer,
            "Only freelancer can complete milestone"
        );
        require(_milestoneIndexes.length > 0, "No milestones provided");

        for (uint256 i = 0; i < _milestoneIndexes.length; i++) {
            uint256 index = _milestoneIndexes[i];
            require(
                index < milestones[_projectId].length,
                "Invalid milestone index"
            );
            require(
                milestones[_projectId][index].status == Status.InProgress,
                "Invalid milestone status"
            );

            milestones[_projectId][index].status = Status.Completed;
            emit MilestoneCompleted(_projectId, index);
        }
    }

    function releaseMilestoneFunds(
        uint256 _projectId,
        uint256 _milestoneIndex
    ) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(msg.sender == project.client, "Only client can release funds");

        require(
            _milestoneIndex < milestones[_projectId].length,
            "All milestones completed"
        );
        require(
            milestones[_projectId][_milestoneIndex].status == Status.Completed,
            "Milestone not completed"
        );

        uint256 amount = milestones[_projectId][_milestoneIndex].amount;
        uint256 fee = (amount * platformFeePercentage) / WEI4;
        uint256 payment = amount - fee;

        IERC20(project.token).safeTransfer(project.freelancer, payment);
        IERC20(project.token).safeTransfer(treasury, fee);

        milestones[_projectId][_milestoneIndex].status = Status.Released;
        emit MilestoneFundsReleased(
            _projectId,
            _milestoneIndex,
            project.freelancer,
            payment
        );

        if (_milestoneIndex + 1 < milestones[_projectId].length) {
            milestones[_projectId][_milestoneIndex + 1].status = Status
                .InProgress;
        } else {
            emit ProjectCompleted(_projectId);
        }
    }

    function batchReleaseMilestoneFunds(
        uint256 _projectId,
        uint256[] calldata _milestoneIndexes
    ) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(msg.sender == project.client, "Only client can release funds");
        require(_milestoneIndexes.length > 0, "No milestones provided");

        uint256 totalPayment = 0;
        uint256 totalFee = 0;

        for (uint256 i = 0; i < _milestoneIndexes.length; i++) {
            uint256 index = _milestoneIndexes[i];
            require(
                index < milestones[_projectId].length,
                "Invalid milestone index"
            );
            require(
                milestones[_projectId][index].status == Status.Completed,
                "Milestone not completed"
            );

            uint256 amount = milestones[_projectId][index].amount;
            uint256 fee = (amount * platformFeePercentage) / WEI4;
            uint256 payment = amount - fee;

            totalPayment += payment;
            totalFee += fee;

            milestones[_projectId][index].status = Status.Released;
            emit MilestoneFundsReleased(
                _projectId,
                index,
                project.freelancer,
                payment
            );

            // Set next milestone to InProgress if it exists
            if (index + 1 < milestones[_projectId].length) {
                milestones[_projectId][index + 1].status = Status.InProgress;
            }
        }

        if (totalPayment > 0) {
            IERC20(project.token).safeTransfer(
                project.freelancer,
                totalPayment
            );
        }
        if (totalFee > 0) {
            IERC20(project.token).safeTransfer(treasury, totalFee);
        }

        // Check if this was the last milestone
        if (
            _milestoneIndexes[_milestoneIndexes.length - 1] + 1 >=
            milestones[_projectId].length
        ) {
            emit ProjectCompleted(_projectId);
        }
    }

    function disputeMilestone(
        uint256 _projectId,
        uint256 _milestoneIndex
    ) external {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.client || msg.sender == project.freelancer,
            "Only client or freelancer can dispute"
        );

        require(
            _milestoneIndex < milestones[_projectId].length,
            "All milestones completed"
        );
        require(
            milestones[_projectId][_milestoneIndex].status ==
                Status.InProgress ||
                milestones[_projectId][_milestoneIndex].status ==
                Status.Completed,
            "Invalid milestone status"
        );

        milestones[_projectId][_milestoneIndex].status = Status.Disputed;
        emit MilestoneDisputed(_projectId, _milestoneIndex);
    }

    /**
     * Admin function -----------------------------------------------------------------
     */

    /**
     * @dev Resolves a dispute by transferring funds to the specified recipient
     * @param _projectId ID of the project
     * @param _recipient Address to receive the funds
     * @param _amount Amount to transfer
     */
    function resolveDispute(
        uint256 _projectId,
        address _recipient,
        uint256 _milestoneIndex,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            _milestoneIndex < milestones[_projectId].length,
            "All milestones completed"
        );
        require(
            milestones[_projectId][_milestoneIndex].status == Status.Disputed,
            "Milestone not disputed"
        );
        require(
            _recipient == project.client || _recipient == project.freelancer,
            "Invalid recipient"
        );

        uint256 milestoneAmount = milestones[_projectId][_milestoneIndex]
            .amount;
        require(_amount <= milestoneAmount, "Amount exceeds milestone amount");

        IERC20(project.token).safeTransfer(_recipient, _amount);

        if (_amount < milestoneAmount) {
            uint256 remaining = milestoneAmount - _amount;
            IERC20(project.token).safeTransfer(
                _recipient == project.client
                    ? project.freelancer
                    : project.client,
                remaining
            );
        }

        milestones[_projectId][_milestoneIndex].status = Status.Released;
        if (_milestoneIndex + 1 < milestones[_projectId].length) {
            milestones[_projectId][_milestoneIndex + 1].status = Status
                .InProgress;
        } else {
            emit ProjectCompleted(_projectId);
        }
    }

    function cancelProject(
        uint256 _projectId,
        uint256 _milestoneIndex
    ) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        require(
            msg.sender == project.client || msg.sender == project.freelancer,
            "Only client or freelancer can cancel"
        );

        uint256 remainingAmount = 0;
        for (
            uint256 i = _milestoneIndex;
            i < milestones[_projectId].length;
            i++
        ) {
            if (milestones[_projectId][i].status != Status.Released) {
                remainingAmount += milestones[_projectId][i].amount;
            }
        }

        if (remainingAmount > 0) {
            IERC20(project.token).safeTransfer(project.client, remainingAmount);
        }

        // Mark all remaining milestones as Released to prevent further actions
        for (
            uint256 i = _milestoneIndex;
            i < milestones[_projectId].length;
            i++
        ) {
            if (milestones[_projectId][i].status != Status.Released) {
                milestones[_projectId][i].status = Status.Released;
            }
        }

        emit ProjectCancelled(_projectId);
    }

    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee too high"); // Max 10%
        platformFeePercentage = _newFee;
    }

    function updateTimeoutPeriod(uint256 _newPeriod) external onlyOwner {
        timeoutPeriod = _newPeriod;
        emit TimeoutPeriodUpdated(_newPeriod);
    }

    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid treasury address");
        treasury = _newTreasury;
    }

    /**
     * View functions -----------------------------------------------------------------
     */

    function getTotalAmount(
        uint256 _projectId
    ) external view returns (uint256) {
        require(milestones[_projectId].length > 0, "Project does not exist");

        uint256 total = 0;
        for (uint256 i = 0; i < milestones[_projectId].length; i++) {
            total += milestones[_projectId][i].amount;
        }
        return total;
    }

    function getProject(
        uint256 _projectId
    ) external view returns (Project memory) {
        Project storage project = projects[_projectId];
        require(project.client != address(0), "Project does not exist");
        return project;
    }
}
