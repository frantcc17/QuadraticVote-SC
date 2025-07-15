// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "src/Interfaces/IStakingAppForVoting.sol";
import "src/VoteToken.sol"; // Importamos el contrato RewardToken completo

error MaxAmount(uint256 amount);

contract QuadraticVoting is ReentrancyGuard {
    using Math for uint256;

    // Cambiado a RewardToken para acceder a la función burn
    RewardToken public stakingToken; // Ahora es RewardToken, no solo IERC20
    IStakingAppForVoting public stakingApp;
    uint256 public proposalCount;
    uint256 public minVotingPower;
    uint256 public tokenMaxAmount;

    struct Proposal {
        address creator;
        string description;
        uint256 creationTime;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalQuadraticVotes;
        bool accepted;
        bool votingEnded;
        mapping(address => uint256) votes;
        mapping(address => uint256) delegated;
    }

    mapping(uint256 => Proposal) private proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => uint256) public proposalsCreated;

    event ProposalCreated(uint256 indexed proposalId, address indexed creator);
    event TokensDelegated(uint256 indexed proposalId, address indexed voter, uint256 amount);
    event VoteFinalized(uint256 indexed proposalId, bool accepted);
    event Voted(address indexed voter, uint256 proposalId, uint256 power);
    event TokensRefunded(uint256 refund);
    event TokensBurned(address indexed burner, uint256 amount); // Nuevo evento
    event TokensReclaimed(address indexed user, uint256 amount);

    constructor(address _stakingToken, uint256 _tokenMaxAmount, address _stakingApp, uint256 _minVotingPower) {
        // Casteamos a RewardToken para que 'stakingToken' tenga acceso a la función 'burn'
        stakingToken = RewardToken(_stakingToken);
        stakingApp = IStakingAppForVoting(_stakingApp);
        minVotingPower = _minVotingPower;
        tokenMaxAmount = _tokenMaxAmount;
    }

    modifier onlyDuringVoting(uint256 proposalId) {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.voteStartTime && block.timestamp <= p.voteEndTime, "Not in voting period");
        _;
    }

    modifier onlyBeforeVoting(uint256 proposalId) {
        require(block.timestamp < proposals[proposalId].voteStartTime, "Delegation period over");
        _;
    }

    modifier onlyAfterVoting(uint256 proposalId) {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.voteEndTime, "Voting not ended");
        require(!p.votingEnded, "Already finalized");
        _;
    }

    function createProposal(string memory description) external {
        require(proposalsCreated[msg.sender] < 3, "Too many proposals created by this address");

        proposalsCreated[msg.sender]++;

        Proposal storage p = proposals[proposalCount];
        p.creator = msg.sender;
        p.description = description;
        p.creationTime = block.timestamp;
        p.voteStartTime = block.timestamp + 7 days;
        p.voteEndTime = p.voteStartTime + 1 days;

        emit ProposalCreated(proposalCount, msg.sender);
        proposalCount++;
    }

    function delegateTokens(uint256 proposalId, uint256 amount) external nonReentrant onlyBeforeVoting(proposalId) {
        require(stakingApp.userBalance(msg.sender) > 0, "Caller must have active ETH stake in StakingApp");
        require(amount > 0, "Amount must be greater than 0");
        if (amount > tokenMaxAmount) revert MaxAmount(amount);

        Proposal storage p = proposals[proposalId];
        p.delegated[msg.sender] += amount;

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        emit TokensDelegated(proposalId, msg.sender, amount);
    }

    function vote(uint256 proposalId) external nonReentrant onlyDuringVoting(proposalId) {
        Proposal storage p = proposals[proposalId];
        require(p.delegated[msg.sender] > 0, "No tokens delegated for this proposal");
        require(p.delegated[msg.sender] <= tokenMaxAmount, "Delegated amount exceeds max allowed");
        require(!hasVoted[msg.sender][proposalId], "Already voted on this proposal");
        require(tx.origin == msg.sender, "Proxies not allowed");

        uint256 tokensUsedForVote = p.delegated[msg.sender];
        uint256 votePower = tokensUsedForVote.sqrt();

        hasVoted[msg.sender][proposalId] = true;
        p.totalQuadraticVotes += votePower;
        p.votes[msg.sender] = votePower;

        uint256 refund = tokensUsedForVote / 2;
        uint256 tokensToBurn = tokensUsedForVote - refund; // La otra mitad

        p.delegated[msg.sender] = 0; // Se resetea para evitar votos múltiples o reclamos indebidos

        // Reembolsar la mitad de los tokens
        bool sent = stakingToken.transfer(msg.sender, refund);
        require(sent, "Refund failed");
        emit TokensRefunded(refund);

        // Quemar la otra mitad de los tokens
        // El contrato QuadraticVoting debe tener permiso (BURNER_ROLE) para quemar sus propios tokens.
        stakingToken.burn(address(this), tokensToBurn); // Quema desde el balance de este contrato
        emit TokensBurned(address(this), tokensToBurn);

        emit Voted(msg.sender, proposalId, votePower);
    }

    function finalizeVote(uint256 proposalId) external onlyAfterVoting(proposalId) {
        Proposal storage p = proposals[proposalId];
        p.votingEnded = true;

        if (p.totalQuadraticVotes >= minVotingPower) {
            p.accepted = true;
        }

        emit VoteFinalized(proposalId, p.accepted);
    }

    function reclaimTokens(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.voteEndTime, "Voting still active, cannot reclaim");
        require(!hasVoted[msg.sender][proposalId], "Already voted, tokens were handled at that time");

        uint256 amount = p.delegated[msg.sender];
        require(amount > 0, "No tokens to reclaim for this proposal");

        p.delegated[msg.sender] = 0;
         uint256 refund = (amount * 75) / 100; // Solo el 75%
         bool sent = stakingToken.transfer(msg.sender, refund);
         require(sent, "Refund failed");

        emit TokensReclaimed(msg.sender, amount);
    }

    function getDelegatedAmount(uint256 proposalId, address voter) external view returns (uint256) {
        return proposals[proposalId].delegated[voter];
    }

    function getVoteAmount(uint256 proposalId, address voter) external view returns (uint256) {
        return proposals[proposalId].votes[voter];
    }

    function getProposal(uint256 proposalId) external view returns (
        string memory description,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 totalVotes,
        bool accepted
    ) {
        Proposal storage p = proposals[proposalId];
        return (
            p.description,
            p.voteStartTime,
            p.voteEndTime,
            p.totalQuadraticVotes,
            p.accepted
        );
    }
}
