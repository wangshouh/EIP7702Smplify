// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct Call {
    address target;
    bytes callData;
}

struct Call3 {
    address target;
    bool allowFailure;
    bytes callData;
}

struct Call3Value {
    address target;
    bool allowFailure;
    uint256 value;
    bytes callData;
}

contract SmplifyAccount {
    error Unauthorized();
    error Multicall3CallFailed(uint256 index);
    error Multicall3SumValueFailed();

    struct Result {
        bool success;
        bytes returnData;
    }

    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, Unauthorized());
        _;
    }

    /// @notice Backwards-compatible call aggregation with Multicall
    /// @param calls An array of Call structs
    /// @return returnData An array of bytes containing the responses
    function aggregate(Call[] calldata calls) external payable onlyOwner returns (bytes[] memory returnData) {
        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call calldata call;
        for (uint256 i = 0; i < length;) {
            bool success;
            call = calls[i];
            (success, returnData[i]) = call.target.call(call.callData);
            require(success, Multicall3CallFailed(i));
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Aggregate calls, ensuring each returns success if required
    /// @param calls An array of Call3 structs
    /// @return returnData An array of Result structs
    function aggregate3(Call3[] calldata calls) external payable onlyOwner returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call3 calldata calli;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            assembly {
                // Revert if the call fails and failure is not allowed
                // `allowFailure := calldataload(add(calli, 0x20))` and `success := mload(result)`
                if iszero(or(calldataload(add(calli, 0x20)), mload(result))) {
                    // set "Multicall3CallFailed(uint256)" signature: bytes32(bytes4(keccak256("Multicall3CallFailed(uint256)")))
                    mstore(0x00, 0x794acc4700000000000000000000000000000000000000000000000000000000)
                    // set data index
                    mstore(0x04, i)
                    revert(0x00, 0x48)
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Aggregate calls with a msg value
    /// @notice Reverts if msg.value is less than the sum of the call values
    /// @param calls An array of Call3Value structs
    /// @return returnData An array of Result structs
    function aggregate3Value(Call3Value[] calldata calls)
        external
        payable
        onlyOwner
        returns (Result[] memory returnData)
    {
        uint256 valAccumulator;
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call3Value calldata calli;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            calli = calls[i];
            uint256 val = calli.value;
            // Humanity will be a Type V Kardashev Civilization before this overflows - andreas
            // ~ 10^25 Wei in existence << ~ 10^76 size uint fits in a uint256
            unchecked {
                valAccumulator += val;
            }
            (result.success, result.returnData) = calli.target.call{value: val}(calli.callData);
            assembly {
                // Revert if the call fails and failure is not allowed
                // `allowFailure := calldataload(add(calli, 0x20))` and `success := mload(result)`
                if iszero(or(calldataload(add(calli, 0x20)), mload(result))) {
                    // set "Multicall3CallFailed(uint256)" signature: bytes32(bytes4(keccak256("Multicall3CallFailed(uint256)")))
                    mstore(0x00, 0x794acc4700000000000000000000000000000000000000000000000000000000)
                    // set data index
                    mstore(0x04, i)
                    revert(0x00, 0x48)
                }
            }
            unchecked {
                ++i;
            }
        }
        // Finally, make sure the msg.value = SUM(call[0...i].value)
        require(msg.value == valAccumulator, Multicall3SumValueFailed());
    }
}
