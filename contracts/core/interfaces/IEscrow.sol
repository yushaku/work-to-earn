// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEscrow {
    enum Status {
        Pending, // Initial state when milestone is created
        InProgress, // When project is funded and work can begin
        Completed, // When freelancer marks work as done
        Disputed, // When either party raises a dispute
        Released // When funds are released to freelancer
    }

    struct Milestone {
        uint256 amount;
        uint256 completionTime;
        Status status;
    }

    struct MilestoneInput {
        uint256 amount;
        uint256 completionTime;
    }

    struct Project {
        address client;
        address freelancer;
        address token;
    }

    // Events
    event ProjectCreated(
        uint256 indexed projectId,
        address client,
        address freelancer,
        address token,
        uint256 milestoneCount
    );
    event ProjectFunded(uint256 indexed projectId);
    event MilestoneCreated(
        uint256 indexed projectId,
        uint256 indexed milestoneIndex,
        uint256 amount,
        uint256 completionTime
    );
    event MilestoneFunded(
        uint256 indexed projectId,
        uint256 indexed milestoneIndex,
        uint256 amount
    );
    event MilestoneCompleted(uint256 indexed projectId, uint256 milestoneIndex);
    event MilestoneDisputed(uint256 indexed projectId, uint256 milestoneIndex);
    event MilestoneFundsReleased(
        uint256 indexed projectId,
        uint256 milestoneIndex,
        address indexed freelancer,
        uint256 amount
    );
    event ProjectCompleted(uint256 indexed projectId);
    event ProjectCancelled(uint256 indexed projectId);
    event TimeoutPeriodUpdated(uint256 newTimeoutPeriod);

    function getProject(
        uint256 _projectId
    ) external view returns (Project memory);

    function createBatchMilestones(
        uint256 projectId,
        MilestoneInput[] calldata milestones
    ) external;

    function batchFundMilestones(
        uint256 projectId,
        uint256[] calldata milestoneIndexes
    ) external;

    function batchCompleteMilestones(
        uint256 projectId,
        uint256[] calldata milestoneIndexes
    ) external;

    function batchReleaseMilestoneFunds(
        uint256 projectId,
        uint256[] calldata milestoneIndexes
    ) external;
}
