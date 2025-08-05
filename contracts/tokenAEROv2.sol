// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TokenAEROv2 is ERC20, Ownable, Pausable {
    address public feeReceiver;
    mapping(address => bool) public isFeeExempt;

    event FeeApplied(address indexed from, address indexed to, uint256 feeAmount, uint256 burnedAmount);
    event TokensBurned(uint256 amount);

    constructor(address _feeReceiver) ERC20("Token AERO", "AERO") Ownable(msg.sender) {
        require(_feeReceiver != address(0), unicode"Endereço inválido");
        feeReceiver = _feeReceiver;
        _mint(msg.sender, 1_000_000 * 10 ** decimals());

        isFeeExempt[msg.sender] = true;
        isFeeExempt[_feeReceiver] = true;
    }

    function transferWithFee(address to, uint256 amount) external whenNotPaused {
        require(to != address(0), unicode"Destinatário inválido");
        require(balanceOf(msg.sender) >= amount, unicode"Saldo insuficiente");

        uint256 fee = 0;
        uint256 burnAmount = 0;
        uint256 receiverFee = 0;
        uint256 netAmount = amount;

        if (!isFeeExempt[to]) {
            fee = calculateFee(amount);
            burnAmount = fee / 2;
            receiverFee = fee - burnAmount;
            netAmount = amount - fee;

            super.transfer(feeReceiver, receiverFee);
            _burn(msg.sender, burnAmount);

            emit TokensBurned(burnAmount);
            emit FeeApplied(msg.sender, to, fee, burnAmount);
        }

        super.transfer(to, netAmount);
    }

    function calculateFee(uint256 amount) public pure returns (uint256) {
        if (amount <= 1000 * 10 ** 18) return (amount * 2) / 100;     // 2%
        if (amount <= 10000 * 10 ** 18) return (amount * 3) / 100;    // 3%
        return (amount * 5) / 100;                                    // 5%
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
    }

    function setFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0), unicode"Endereço inválido");
        feeReceiver = newReceiver;
        isFeeExempt[newReceiver] = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}