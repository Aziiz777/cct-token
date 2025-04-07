pragma solidity ^0.8.0;
interface IBurnMintERC20 {
 function mint(address to, uint256 amount) external;
 function burn(address from, uint256 amount) external;
 function burn(uint256 amount) external;
 function burnFrom(address from, uint256 amount) external;
}
