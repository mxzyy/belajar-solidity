// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IERC20
/// @notice Standar ERC20 sesuai EIP-20
/// @dev Semua implementasi ERC20 wajib meng-emit event Transfer dan Approval
interface IERC20 {
    /// @notice Return total suplai token
    function totalSupply() external view returns (uint256);

    /// @notice Return saldo token milik account
    /// @param account Alamat pemilik
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfer token ke address lain
    /// @param to Penerima
    /// @param amount Jumlah token
    /// @return success True jika transfer sukses
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Return allowance spender terhadap owner
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Approve spender untuk belanja sejumlah token
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfer token menggunakan mekanisme allowance
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Event transfer token
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event approval
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @title IERC165
/// @notice Standard interface detection (ERC165)
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @title IOwnable (optional)
/// @notice Minimal interface untuk kontrak Ownable
interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
