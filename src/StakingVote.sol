// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/VoteToken.sol"; // Importamos el contrato RewardToken para poder llamar a su función mint

/**
 * @title StakingApp
 * @dev Contrato para el staking de Ether y distribución de tokens de recompensa.
 */
contract StakingApp is Ownable, ReentrancyGuard {
    RewardToken public rewardToken; // Cambiado a RewardToken para acceder a la función mint
    uint256 public stakingPeriod; // Duración del período de staking para reclamar recompensas
    uint256 public rewardPerPeriod; // Recompensa por cada período de staking completado
    uint256 public maxStakePerUser = 5 ether; // Límite máximo de ETH que un usuario puede stake

    mapping(address => uint256) public userBalance; // Balance de ETH stakeado por usuario
    mapping(address => uint256) public depositTimestamp; // Timestamp del primer depósito o último reclamo

    event Staked(address indexed user, uint256 amount, uint256 newTotalStake);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 rewardAmount);
    event EtherReceived(address indexed from, uint256 amount);
    event ParametersChanged(uint256 newStakingPeriod, uint256 newRewardPerPeriod);
    event MaxStakePerUserChanged(uint256 newMaxStakePerUser);
    event WithdrawExcessETH (uint256 amount);

    /**
     * @dev Constructor del contrato de Staking.
     * @param rewardTokenAddress_ La dirección del contrato RewardToken.
     * @param stakingPeriod_ La duración de un período de staking en segundos.
     * @param rewardPerPeriod_ La cantidad de tokens de recompensa por período.
     * @param owner_ La dirección del propietario inicial del contrato.
     */
    constructor(
        address rewardTokenAddress_,
        uint256 stakingPeriod_,
        uint256 rewardPerPeriod_,
        address owner_
    ) Ownable(owner_) {
        // Casteamos a RewardToken para tener acceso a la función mint
        rewardToken = RewardToken(rewardTokenAddress_);
        stakingPeriod = stakingPeriod_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    /**
     * @dev Permite a los usuarios hacer stake de Ether.
     * Permite añadir más ETH a un stake existente hasta el límite.
     */
    function stake() external payable nonReentrant{
        require(msg.value > 0, "Stake must be > 0");
        if(userBalance[msg.sender] > 0){
            claimReward();
        } else {
            depositTimestamp[msg.sender] = block.timestamp;
        }

        uint256 newBalance = userBalance[msg.sender] + msg.value;
        require(newBalance <= maxStakePerUser, "Exceeds max stake per user");

        userBalance[msg.sender] = newBalance;

        emit Staked(msg.sender, msg.value, userBalance[msg.sender]);
    }

    /**
     * @dev Permite a los usuarios retirar su Ether stakeado.
     * Patrón "checks-effects-interactions".
     */
    function withdraw() external nonReentrant{
        uint256 amount = userBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        userBalance[msg.sender] = 0; // Efecto: Actualizar estado antes de la interacción externa
        depositTimestamp[msg.sender] = 0; // Reiniciar timestamp tras el retiro completo

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Withdraw failed"); // Check: Asegurarse de que la transferencia fue exitosa

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Permite a los usuarios reclamar sus recompensas acumuladas.
     * Ahora las recompensas se acumulan por cada período completo y se acuñan.
     */
    function claimReward() public nonReentrant{
        require(userBalance[msg.sender] > 0, "No active stake");

        uint256 elapsed = block.timestamp - depositTimestamp[msg.sender];
        require(elapsed >= stakingPeriod, "Too early to claim (staking period not completed)");

        // Calcular cuántos períodos completos han pasado
        uint256 periodsPassed = elapsed / stakingPeriod;
        require(periodsPassed > 0, "No new periods completed since last claim");

        uint256 totalReward = periodsPassed * rewardPerPeriod;

        // Avanzar el timestamp para el próximo cálculo de recompensas
        depositTimestamp[msg.sender] += periodsPassed * stakingPeriod;

        // Llama a la función mint del RewardToken para acuñar y transferir los tokens
        rewardToken.mint(msg.sender, totalReward);

        emit RewardClaimed(msg.sender, totalReward);
    }

    /**
     * @dev Permite al propietario cambiar los parámetros de staking.
     * @param newPeriod El nuevo período de staking en segundos.
     * @param newReward La nueva recompensa por período.
     */
    function changeParameters(uint256 newPeriod, uint256 newReward) external onlyOwner {
        require(newPeriod > 0, "Staking period must be greater than 0");
        stakingPeriod = newPeriod;
        rewardPerPeriod = newReward;
        emit ParametersChanged(newPeriod, newReward);
    }

    /**
     * @dev Permite al propietario cambiar el máximo de ETH que un usuario puede stake.
     * @param _newMax El nuevo límite máximo de stake por usuario.
     */
    function setMaxStakePerUser(uint256 _newMax) external onlyOwner {
        require(_newMax > 0, "Max stake must be > 0");
        maxStakePerUser = _newMax;
        emit MaxStakePerUserChanged(_newMax);
    }

    function withdrawExcessETH(address payable to, uint256 amount) external onlyOwner {
    require(to != address(0), "Invalid address");
    require(amount <= address(this).balance, "Not enough balance");

    (bool sent, ) = to.call{value: amount}("");
    require(sent, "Transfer failed");

    emit WithdrawExcessETH (amount);
}

    /**
     * @dev Función fallback para recibir Ether.
     */
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }
}
