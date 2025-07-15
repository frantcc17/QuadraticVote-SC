/ SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RewardToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(string memory name_, string memory symbol_, address initialMinter, address initialBurner)
        ERC20(name_, symbol_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, initialMinter);
        _grantRole(BURNER_ROLE, initialBurner); // Concede el rol de quemador al QuadraticVoting
    }

    function mint(address to, uint256 amount_) external onlyRole(MINTER_ROLE) {
        _mint(to, amount_);
    }

    /**
     * @dev Quema tokens de una dirección específica.
     * Solo las direcciones con el BURNER_ROLE pueden llamar a esta función.
     * @param from La dirección de la que se quemarán los tokens.
     * @param amount_ La cantidad de tokens a quemar.
     */
    function burn(address from, uint256 amount_) external onlyRole(BURNER_ROLE) {
        _burn(from, amount_);
    }
}
