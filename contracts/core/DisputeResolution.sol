// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Escrow.sol";

/**
 * @title DisputeResolution
 * @dev Handles disputes between clients and freelancers
 */
contract DisputeResolution is Ownable {
    IEscrow public escrowContract;
    address public arbitrator;

    struct Dispute {
        uint256 projectId;
        address client;
        address freelancer;
        string clientEvidence;
        string freelancerEvidence;
        bool resolved;
        bool exists;
    }

    mapping(uint256 => Dispute) public disputes;

    // Events
    event DisputeCreated(
        uint256 indexed projectId,
        address client,
        address freelancer
    );
    event EvidenceSubmitted(
        uint256 indexed projectId,
        address submitter,
        string evidence
    );
    event DisputeResolved(uint256 indexed projectId, address winner);

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only arbitrator can call this");
        _;
    }

    constructor(
        address _escrowContract,
        address _arbitrator
    ) Ownable(msg.sender) {
        escrowContract = Escrow(_escrowContract);
        arbitrator = _arbitrator;
    }

    /**
     * @dev Creates a new dispute
     * @param _projectId ID of the project in dispute
     */
    function createDispute(uint256 _projectId) external {
        (address client, address freelancer, ) = escrowContract.getProject(
            _projectId
        );

        require(
            msg.sender == client || msg.sender == freelancer,
            "Only client or freelancer can create dispute"
        );
        require(!disputes[_projectId].exists, "Dispute already exists");

        disputes[_projectId] = Dispute({
            projectId: _projectId,
            client: client,
            freelancer: freelancer,
            clientEvidence: "",
            freelancerEvidence: "",
            resolved: false,
            exists: true
        });

        emit DisputeCreated(_projectId, client, freelancer);
    }

    /**
     * @dev Submit evidence for a dispute
     * @param _projectId ID of the disputed project
     * @param _evidence IPFS hash or other reference to evidence
     */
    function submitEvidence(
        uint256 _projectId,
        string calldata _evidence
    ) external {
        Dispute storage dispute = disputes[_projectId];
        require(dispute.exists, "Dispute does not exist");
        require(!dispute.resolved, "Dispute already resolved");
        require(
            msg.sender == dispute.client || msg.sender == dispute.freelancer,
            "Only client or freelancer can submit evidence"
        );

        if (msg.sender == dispute.client) {
            dispute.clientEvidence = _evidence;
        } else {
            dispute.freelancerEvidence = _evidence;
        }

        emit EvidenceSubmitted(_projectId, msg.sender, _evidence);
    }

    /**
     * @dev Resolve a dispute
     * @param _projectId ID of the disputed project
     * @param _winner Address of the winning party
     */
    function resolveDispute(
        uint256 _projectId,
        address _winner
    ) external onlyArbitrator {
        Dispute storage dispute = disputes[_projectId];
        require(dispute.exists, "Dispute does not exist");
        require(!dispute.resolved, "Dispute already resolved");
        require(
            _winner == dispute.client || _winner == dispute.freelancer,
            "Winner must be client or freelancer"
        );

        dispute.resolved = true;
        escrowContract.resolveDispute(_projectId, _winner);

        emit DisputeResolved(_projectId, _winner);
    }

    /**
     * @dev Change the arbitrator address
     * @param _newArbitrator Address of the new arbitrator
     */
    function setArbitrator(address _newArbitrator) external onlyOwner {
        require(_newArbitrator != address(0), "Invalid arbitrator address");
        arbitrator = _newArbitrator;
    }

    /**
     * @dev Get dispute details
     * @param _projectId ID of the disputed project
     */
    function getDispute(
        uint256 _projectId
    )
        external
        view
        returns (
            address client,
            address freelancer,
            string memory clientEvidence,
            string memory freelancerEvidence,
            bool resolved
        )
    {
        Dispute storage dispute = disputes[_projectId];
        require(dispute.exists, "Dispute does not exist");

        return (
            dispute.client,
            dispute.freelancer,
            dispute.clientEvidence,
            dispute.freelancerEvidence,
            dispute.resolved
        );
    }
}
