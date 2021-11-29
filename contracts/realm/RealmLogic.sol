// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import { RealmStorage } from "./RealmStorage.sol";

/**
 * @title RealmLogic
 * @author enepti
 *
 * Realm the creation of NFTs by issuing ERC20 tokens that
 * can be redeemed for the underlying value of the NFT once sold.
 */
contract RealmLogic is RealmStorage {
    // ============ Events ============

    event Contribution(address contributor, uint256 amount);
    event RealmClosed();
    event Claimed(uint256 amountRaised, uint256 creatorAllocation);
    event Redeemed(address contributor, uint256 amount);
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ============ Modifiers ============

    /**
     * @dev Modifier to check whether the `msg.sender` is the operator.
     * If it is, it will run the function. Otherwise, it will revert.
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Only Operator");
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancy_status != REENTRANCY_ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        reentrancy_status = REENTRANCY_ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        reentrancy_status = REENTRANCY_NOT_ENTERED;
    }

    // ============ Realming Methods ============

    /**
     * @notice Mints tokens for the sender propotional to the
     *  amount of ETH sent in the transaction.
     * @dev Emits the Contribution event.
     */
    function contribute(address payable backer, uint256 amount) external payable nonReentrant {
        require(status == Status.ACTIVE, "Realm: Realm must be open");
        require(amount == msg.value, "Realm: Amount is not value sent");
        // This first case is the happy path, so we will keep it efficient.
        // The balance, which includes the current contribution, is less than or equal to cap.
        if (realmCap == 0 || address(this).balance <= realmCap) {
            // Mint equity for the contributor.
            _mint(backer, valueToTokens(amount));
            emit Contribution(backer, amount);
        } else {
            // Compute the balance of the Realm before the contribution was made.
            uint256 startAmount = address(this).balance - amount;
            // If that amount was already greater than the realm cap, then we should revert immediately.
            require(startAmount < realmCap, "Realm: Realm cap already reached");
            // Otherwise, the contribution helped us reach the realm cap. We should
            // take what we can until the realm cap is reached, and refund the rest.
            uint256 eligibleAmount = realmCap - startAmount;
            // Otherwise, we process the contribution as if it were the minimal amount.
            _mint(backer, valueToTokens(eligibleAmount));
            emit Contribution(backer, eligibleAmount);
            // Refund the sender with their contribution (e.g. 2.5 minus the diff - e.g. 1.5 = 1 ETH)
            sendValue(backer, amount - eligibleAmount);
        }
    }

    /**
     * @notice Burns the sender's tokens and redeems underlying ETH.
     * @dev Emits the Redeemed event.
     */
    function redeem(uint256 tokenAmount) external nonReentrant {
        // Prevent backers from accidently redeeming when balance is 0.
        require(address(this).balance > 0, "Realm: No ETH available to redeem");
        // Check
        require(balanceOf[msg.sender] >= tokenAmount, "Realm: Insufficient balance");
        // Effect
        uint256 redeemable = redeemableFromTokens(tokenAmount);
        _burn(msg.sender, tokenAmount);
        // Safe version of transfer.
        sendValue(payable(msg.sender), redeemable);
        emit Redeemed(msg.sender, redeemable);
    }

    /**
     * @notice Returns the amount of ETH that is redeemable for tokenAmount.
     */
    function redeemableFromTokens(uint256 tokenAmount) public view returns (uint256) {
        return (tokenAmount * address(this).balance) / totalSupply;
    }

    function valueToTokens(uint256 value) public pure returns (uint256 tokens) {
        tokens = value * (TOKEN_SCALE);
    }

    function tokensToValue(uint256 tokenAmount) internal pure returns (uint256 value) {
        value = tokenAmount / TOKEN_SCALE;
    }

    // ============ Operator Methods ============

    /**
     * @notice Transfers all funds to operator, and mints tokens for the operator.
     *  Updates status to INACTIVE.
     * @dev Emits the RealmClosed event.
     */
    function closeRealm() external onlyOperator nonReentrant {
        require(status == Status.ACTIVE, "Realm: Realm must be open");
        // Close realm status, move to tradable.
        status = Status.INACTIVE;
        emit RealmClosed();
    }

    /**
     * @notice Transfers all funds to operator, and mints tokens for the operator.
     *  Updates status to INACTIVE.
     * @dev Emits the RealmClosed event.
     */
    function claim() external onlyOperator nonReentrant {
        require(status == Status.ACTIVE, "Realm: Realm must be open");
        // Mint the operator a percent of the total supply.
        uint256 operatorTokens = (operatorPercent * totalSupply) / (100 - operatorPercent);
        _mint(operator, operatorTokens);
        // Announce the fund claim by the operator
        emit Claimed(address(this).balance, operatorTokens);
        // Transfer rest of funds to the realmRecipient.
        sendValue(realmRecipient, address(this).balance);
    }

    // ============ Utility Methods ============

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    // ============ ERC20 Spec ============

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }
}
