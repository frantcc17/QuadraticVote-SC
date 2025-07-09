---

# 🚀 ¡Bienvenido a tu Ecosistema de Staking y Gobernanza Descentralizada! 🚀

Este repositorio contiene los contratos inteligentes que impulsan tu innovador sistema, combinando **staking de ETH** con un mecanismo de **votación cuadrática** basado en tokens de recompensa. ¡Prepárate para una participación comunitaria transparente y equitativa!

---

## 📖 ¿Qué es esto?

Este proyecto consta de **tres contratos inteligentes** interconectados que trabajan en armonía:

1.  **`RewardToken.sol`**: Tu moneda nativa de recompensa.
2.  **`StakingApp.sol`**: Donde los usuarios bloquean ETH para ganar tokens.
3.  **`QuadraticVoting.sol`**: La plataforma de gobernanza que utiliza un innovador sistema de votación. 

---

## 🎯 El Corazón del Sistema: Cómo Funciona

El flujo de valor y participación es simple pero potente:

1.  **Stakea ETH**: Los usuarios depositan Ether en el contrato `StakingApp`.
2.  **Gana Recompensas**: Por cada período de staking completado, el `StakingApp` acuña y distribuye **`RewardToken`s** a los stakers.
3.  **Vota con Recompensas**: Estos `RewardToken`s se utilizan en el contrato `QuadraticVoting` para proponer y votar.
4.  **Gobernanza Cuadrática**: En la votación, el poder de voto aumenta con la raíz cuadrada de los tokens usados, asegurando que las grandes ballenas no dominen la toma de decisiones. Además, la mitad de los tokens de voto son **quemados** para darles un valor real y evitar el spam. 

---

## 📝 Contratos Inteligentes Detallados

### 1. `RewardToken.sol` 🌟

Este es tu **token ERC20** personalizado, diseñado específicamente para recompensar a tu comunidad.

* **Nombre del Contrato**: `RewardToken`
* **Función Clave**: `mint(address to, uint256 amount_)`
    * Permite la creación de nuevos tokens.
    * **¡Seguridad Mejorada!**: Solo el contrato `StakingApp` (con el rol `MINTER_ROLE`) puede acuñar estos tokens, garantizando un suministro controlado y seguro.
* **Función de Quema**: `burn(address from, uint256 amount_)`
    * Permite la destrucción permanente de tokens.
    * **¡Económicamente Robusto!**: El contrato `QuadraticVoting` (con el rol `BURNER_ROLE`) lo utiliza para "gastar" tokens durante el proceso de votación.

### 2. `StakingApp.sol` 💎

La puerta de entrada a tu sistema de recompensas. Aquí es donde los usuarios interactúan directamente con su ETH.

* **Nombre del Contrato**: `StakingApp`
* **Características Principales**:
    * **`stake()`**: Deposita ETH para empezar a ganar recompensas. ¡Ahora permite añadir más ETH a un stake existente!
    * **`withdraw()`**: Retira el ETH stakeado.
    * **`claimReward()`**: Acumula y reclama los `RewardToken`s ganados por tu actividad de staking.
    * **Parámetros Configurables**: El propietario puede ajustar dinámicamente el `stakingPeriod`, `rewardPerPeriod`, y `maxStakePerUser` para optimizar la economía del protocolo.

### 3. `QuadraticVoting.sol` 💡

El motor de gobernanza que da voz a tu comunidad.

* **Nombre del Contrato**: `QuadraticVoting`
* **Características Principales**:
    * **`createProposal(string memory description)`**: Permite a los miembros proponer nuevas iniciativas (con un límite para evitar spam).
    * **`delegateTokens(uint256 proposalId, uint256 amount)`**: Asigna `RewardToken`s a una propuesta específica antes de votar. **Solo los stakers de ETH pueden delegar.**
    * **`vote(uint256 proposalId)`**: Utiliza tus tokens delegados. Tu poder de voto es la raíz cuadrada de los tokens, y **¡la mitad de tus tokens de voto se queman permanentemente!** Esto asegura una participación significativa.
    * **`finalizeVote(uint256 proposalId)`**: Cierra la votación y determina el resultado de la propuesta.
    * **`reclaimTokens(uint256 proposalId)`**: Si delegaste tokens pero no votaste, puedes recuperarlos íntegramente.

---

## 🔒 Seguridad y Conexiones Clave

Hemos puesto un fuerte énfasis en la seguridad y la correcta interconexión:

* **Roles Controlados**: `RewardToken` utiliza roles (`MINTER_ROLE`, `BURNER_ROLE`) para restringir quién puede acuñar o quemar tokens, asegurando que solo los contratos autorizados (`StakingApp` y `QuadraticVoting` respectivamente) puedan hacerlo.
* **Interacción Definida**: `StakingApp` y `QuadraticVoting` se comunican a través de interfaces claras (`IStakingAppForVoting`), garantizando que solo se acceda a las funciones necesarias.
* **Patrones de Seguridad**: Se aplican patrones como "checks-effects-interactions" y `ReentrancyGuard` para prevenir ataques comunes.

---

## 🛠️ Despliegue y Configuración

Para poner en marcha tu sistema, sigue estos pasos secuenciales:

1.  **Despliega `RewardToken`**: Pasa las direcciones de tu futuro `StakingApp` como `initialMinter` y tu futuro `QuadraticVoting` como `initialBurner` en el constructor.
2.  **Despliega `StakingApp`**: Proporciona la dirección de tu `RewardToken` recién desplegado en su constructor.
3.  **Despliega `QuadraticVoting`**: Necesitará las direcciones de tu `RewardToken` y tu `StakingApp` en su constructor.

---

## 📈 ¡Comienza a Construir!

Este es el punto de partida perfecto para tu ecosistema descentralizado. ¡Explora los contratos, contribuye y haz crecer tu comunidad!

---
