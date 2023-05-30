// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./EIP712MetaTransaction.sol";
import "./IUniswapRouter.sol";
import "./IToken.sol";

contract GasSwap is Ownable, EIP712MetaTransaction("GasSwap", "2") {
    using SafeERC20 for IERC20;
    address internal immutable WPLS;

    struct Transformation {
        uint32 _uint32;
        bytes _bytes;
    }

    IUniswapRouter public router;
    address public feeAddress;
    uint256 public feePercent = 100; //1%

    mapping(address => bool) public tokenWhitelist;

    constructor(address _router, address _WPLS) {
        router = IUniswapRouter(_router);
        WPLS = _WPLS;
    }

    receive() external payable {
        require(Address.isContract(msgSender()), "REVERT_EOA_DEPOSIT");
    }

    function whitelistToken(
        address tokenAddress,
        bool whitelisted
    ) external onlyOwner {
        require(Address.isContract(tokenAddress), "NO_CONTRACT_AT_ADDRESS");
        tokenWhitelist[tokenAddress] = whitelisted;
    }

    function changeFeePercent(uint256 newFeePercent) external onlyOwner {
        require(feePercent >= 0 && feePercent < 10000, "INVALID_FEE_PERCENT");
        feePercent = newFeePercent;
    }

    function changeFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    function changeRouter(address newTarget) external onlyOwner {
        require(Address.isContract(newTarget), "NO_CONTRACT_AT_ADDRESS");
        router = IUniswapRouter(newTarget);
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    // Transfer ETH held by this contract to the sender/owner.
    function withdrawETH(uint256 amount) external onlyOwner {
        (bool succ, ) = msg.sender.call{value: amount}("");
        require(succ, "Transfer failed.");
        // payable(msg.sender).transfer(amount);
    }

    // Swaps ERC20->PLS tokens
    function swap(bytes calldata swapCallData) external returns (uint256) {
        (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path,
            ,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
                swapCallData,
                (
                    uint256,
                    uint256,
                    address[],
                    address,
                    uint256,
                    uint8,
                    bytes32,
                    bytes32
                )
            );

        require(path[path.length - 1] == WPLS, "INVALID_OUTPUT_TOKEN");

        require(tokenWhitelist[path[0]] == true, "INVALID_INPUT_TOKEN");

        IToken sellToken = IToken(path[0]);

        sellToken.permit(
            msgSender(),
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );

        sellToken.transferFrom(msgSender(), address(this), amountIn);

        uint256 beforeSwapBalance = address(this).balance;

        sellToken.approve(address(router), amountIn);

        router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint256 tradeBalance = address(this).balance - beforeSwapBalance;
        uint256 amount = ((tradeBalance * 10000) -
            (tradeBalance * feePercent)) / 10000;
        uint256 fee = tradeBalance - amount;

        if (feeAddress != address(0)) {
            (bool s, ) = feeAddress.call{value: fee}("");
            require(s, "Transfer failed.");
            //   payable(feeAddress).transfer(fee);
        }
        (bool succ, ) = msgSender().call{value: amount}("");
        require(succ, "Transfer failed.");
        //payable(msgSender()).transfer(amount);
        return amount;
    }
}
