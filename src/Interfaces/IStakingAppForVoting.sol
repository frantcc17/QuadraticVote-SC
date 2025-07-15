/ SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IStakingAppForVoting
 * @dev Interfaz para que el contrato QuadraticVoting interactúe con el contrato StakingApp.
 * Contiene solo las funciones necesarias y existentes en StakingApp.
 */
interface IStakingAppForVoting {
    /**
     * @dev Obtiene el balance de ETH stakeado de un usuario.
     * @param user La dirección del usuario.
     * @return El balance de ETH stakeado del usuario.
     */
    function userBalance(address user) external view returns (uint256);

    /**
     * @dev Obtiene la duración del período de staking.
     * @return La duración del período de staking en segundos.
     */
    function stakingPeriod() external view returns (uint256);

    }
