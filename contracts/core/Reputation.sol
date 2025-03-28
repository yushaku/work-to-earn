// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Escrow.sol";

/**
 * @title Reputation
 * @dev Manages reputation scores for clients and freelancers
 */
contract Reputation is Ownable {
    Escrow public escrowContract;

    struct Rating {
        uint8 score; // 1-5 rating
        string feedback; // IPFS hash of detailed feedback
        uint256 timestamp;
    }

    struct UserReputation {
        uint256 totalScore;
        uint256 totalRatings;
        mapping(uint256 => Rating) ratings; // projectId => Rating
        bool exists;
    }

    mapping(address => UserReputation) public userReputations;
    mapping(uint256 => bool) public projectRated;

    // Events
    event RatingSubmitted(
        uint256 indexed projectId,
        address indexed rater,
        address indexed rated,
        uint8 score,
        string feedback
    );

    constructor(address _escrowContract) Ownable(msg.sender) {
        escrowContract = Escrow(_escrowContract);
    }

    /**
     * @dev Submit a rating for a completed project
     * @param _projectId ID of the completed project
     * @param _score Rating score (1-5)
     * @param _feedback IPFS hash of detailed feedback
     */
    function submitRating(
        uint256 _projectId,
        uint8 _score,
        string calldata _feedback
    ) external {
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5");
        require(!projectRated[_projectId], "Project already rated");

        IEscrow.Project memory project = escrowContract.getProject(_projectId);
        address client = project.client;
        address freelancer = project.freelancer;

        require(
            msg.sender == client || msg.sender == freelancer,
            "Only project participants can rate"
        );

        // Determine who is being rated
        address ratedUser = msg.sender == client ? freelancer : client;

        // Initialize user reputation if it doesn't exist
        if (!userReputations[ratedUser].exists) {
            userReputations[ratedUser].exists = true;
        }

        // Store the rating
        UserReputation storage reputation = userReputations[ratedUser];
        reputation.ratings[_projectId] = Rating({
            score: _score,
            feedback: _feedback,
            timestamp: block.timestamp
        });

        reputation.totalScore += _score;
        reputation.totalRatings++;

        projectRated[_projectId] = true;

        emit RatingSubmitted(
            _projectId,
            msg.sender,
            ratedUser,
            _score,
            _feedback
        );
    }

    /**
     * @dev Get a user's average reputation score
     * @param _user Address of the user
     * @return score Average score (0 if no ratings)
     * @return totalRatings Number of ratings received
     */
    function getReputation(
        address _user
    ) external view returns (uint256 score, uint256 totalRatings) {
        UserReputation storage reputation = userReputations[_user];

        if (reputation.totalRatings == 0) {
            return (0, 0);
        }

        return (
            (reputation.totalScore * 100) / reputation.totalRatings, // Multiply by 100 for 2 decimal precision
            reputation.totalRatings
        );
    }

    /**
     * @dev Get rating details for a specific project
     * @param _projectId ID of the project
     * @param _user Address of the rated user
     */
    function getRating(
        uint256 _projectId,
        address _user
    )
        external
        view
        returns (uint8 score, string memory feedback, uint256 timestamp)
    {
        require(userReputations[_user].exists, "User has no reputation");
        Rating storage rating = userReputations[_user].ratings[_projectId];
        require(rating.timestamp > 0, "Rating does not exist");

        return (rating.score, rating.feedback, rating.timestamp);
    }

    /**
     * @dev Get the most recent ratings for a user
     * @param _user Address of the user
     * @param _count Number of recent ratings to return
     */
    function getRecentRatings(
        address _user,
        uint256 _count
    )
        external
        view
        returns (
            uint256[] memory projectIds,
            uint8[] memory scores,
            string[] memory feedbacks,
            uint256[] memory timestamps
        )
    {
        require(userReputations[_user].exists, "User has no reputation");
        UserReputation storage reputation = userReputations[_user];

        uint256 count = _count > reputation.totalRatings
            ? reputation.totalRatings
            : _count;

        projectIds = new uint256[](count);
        scores = new uint8[](count);
        feedbacks = new string[](count);
        timestamps = new uint256[](count);

        uint256 found = 0;
        uint256 projectId = 0;

        // Note: This is a simplified approach. In production, you might want to
        // implement a more efficient way to track and retrieve recent ratings
        while (found < count && projectId < type(uint256).max) {
            if (reputation.ratings[projectId].timestamp > 0) {
                projectIds[found] = projectId;
                scores[found] = reputation.ratings[projectId].score;
                feedbacks[found] = reputation.ratings[projectId].feedback;
                timestamps[found] = reputation.ratings[projectId].timestamp;
                found++;
            }
            projectId++;
        }

        return (projectIds, scores, feedbacks, timestamps);
    }
}
