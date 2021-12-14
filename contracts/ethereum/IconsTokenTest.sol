// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IconsTokenTest is ERC20("IconsToken", "ICONS") {
  function transfer(address _to, uint _value)
    override
    public
    returns (bool)
  {
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)
    override
    public
    returns (bool)
  {
    emit Transfer(_from, _to, _value);
    return true;
  }
}