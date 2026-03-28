pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // Additional state variables for allowances and dividends
  mapping (address => mapping (address => uint256)) private _allowances;
  address[] private _holders;
  mapping (address => bool) private _isHolder;
  mapping (address => uint256) private _dividends;

  // IERC20

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(to != address(0), "Transfer to zero address");
    require(balanceOf[msg.sender] >= value, "Insufficient balance");
    
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    require(spender != address(0), "Approve to zero address");
    _allowances[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(from != address(0), "Transfer from zero address");
    require(to != address(0), "Transfer to zero address");
    require(balanceOf[from] >= value, "Insufficient balance");
    require(_allowances[from][msg.sender] >= value, "Insufficient allowance");
    
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  // IMintableToken

  function mint() external payable override {
    require(msg.value > 0, "Must send ETH to mint");
    _mint(msg.sender, msg.value);
  }

  function burn(address payable dest) external override {
    uint256 amount = balanceOf[msg.sender];
    require(amount > 0, "No balance to burn");
    _burn(msg.sender, amount);
    (bool ok, ) = dest.call{value: amount}("");
    require(ok, "ETH transfer failed");
  }

  // IDividends

  function getNumTokenHolders() external view override returns (uint256) {
    return _holders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    require(index > 0 && index <= _holders.length, "Index out of bounds");
    return _holders[index - 1];
  }

  function recordDividend() external payable override {
    require(msg.value > 0, "Dividend must be non-zero");
    uint256 supply = totalSupply;
    require(supply > 0, "No token holders");

    uint256 len = _holders.length;
    for (uint256 i = 0; i < len; i++) {
      address holder = _holders[i];
      uint256 bal = balanceOf[holder];
      if (bal > 0) {
        _dividends[holder] = _dividends[holder].add(msg.value.mul(bal).div(supply));
      }
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return _dividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount = _dividends[msg.sender];
    require(amount > 0, "No dividends to withdraw");
    _dividends[msg.sender] = 0;
    (bool ok, ) = dest.call{value: amount}("");
    require(ok, "ETH transfer failed");
  }

  // Internal functions

  function _transfer(address from, address to, uint256 value) internal {
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    
    emit Transfer(from, to, value);
    
    // Update holder tracking
    _updateHolderAfterTransfer(from, to);
  }

  function _mint(address account, uint256 value) internal {
    require(account != address(0), "Mint to zero address");
    totalSupply = totalSupply.add(value);
    balanceOf[account] = balanceOf[account].add(value);
    
    emit Transfer(address(0), account, value);
    
    // Add new holder if balance > 0
    if (balanceOf[account] > 0 && !_isHolder[account]) {
      _isHolder[account] = true;
      _holders.push(account);
    }
  }

  function _burn(address account, uint256 value) internal {
    require(account != address(0), "Burn from zero address");
    require(balanceOf[account] >= value, "Insufficient balance");
    
    balanceOf[account] = balanceOf[account].sub(value);
    totalSupply = totalSupply.sub(value);
    
    emit Transfer(account, address(0), value);
    
    // Remove holder if balance becomes zero
    if (balanceOf[account] == 0 && _isHolder[account]) {
      _isHolder[account] = false;
      _removeFromHoldersArray(account);
    }
  }

  function _updateHolderAfterTransfer(address from, address to) internal {
    // Add recipient if they become a holder
    if (to != address(0) && balanceOf[to] > 0 && !_isHolder[to]) {
      _isHolder[to] = true;
      _holders.push(to);
    }
    
    // Remove sender if they no longer hold tokens
    if (from != address(0) && balanceOf[from] == 0 && _isHolder[from]) {
      _isHolder[from] = false;
      _removeFromHoldersArray(from);
    }
  }

  function _removeFromHoldersArray(address account) private {
    uint256 len = _holders.length;
    for (uint256 i = 0; i < len; i++) {
      if (_holders[i] == account) {
        _holders[i] = _holders[len - 1];
        _holders.pop();
        break;
      }
    }
  }
}