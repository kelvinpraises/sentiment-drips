// // SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// External Libraries

// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// Interfaces

// Interfaces

// Internal Libraries

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Metadata
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Metadata is used to define the metadata for the protocol that is used throughout the system.
struct Metadata {
    /// @notice Protocol ID corresponding to a specific protocol (currently using IPFS = 1)
    uint256 protocol;
    /// @notice Pointer (hash) to fetch metadata for the specified protocol
    string pointer;
}

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title IRegistry Interface
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Interface for the Registry contract and exposes all functions needed to use the Registry
///         within the Allo protocol.
/// @dev The Registry Interface is used to interact with the Allo protocol and create profiles
///      that can be used to interact with the Allo protocol. The Registry is the main contract
///      that all other contracts interact with to get the 'Profile' information needed to
///      interact with the Allo protocol. The Registry is also used to create new profiles
///      and update existing profiles. The Registry is also used to add and remove members
///      from a profile. The Registry will not always be used in a strategy and will depend on
///      the strategy being used.
interface IRegistry {
    /// ======================
    /// ======= Structs ======
    /// ======================

    /// @dev The Profile struct that all profiles are based from
    struct Profile {
        bytes32 id;
        uint256 nonce;
        string name;
        Metadata metadata;
        address owner;
        address anchor;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @dev Emitted when a profile is created. This will return your anchor address.
    event ProfileCreated(
        bytes32 indexed profileId, uint256 nonce, string name, Metadata metadata, address owner, address anchor
    );

    /// @dev Emitted when a profile name is updated. This will update the anchor when the name is updated and return it.
    event ProfileNameUpdated(bytes32 indexed profileId, string name, address anchor);

    /// @dev Emitted when a profile's metadata is updated.
    event ProfileMetadataUpdated(bytes32 indexed profileId, Metadata metadata);

    /// @dev Emitted when a profile owner is updated.
    event ProfileOwnerUpdated(bytes32 indexed profileId, address owner);

    /// @dev Emitted when a profile pending owner is updated.
    event ProfilePendingOwnerUpdated(bytes32 indexed profileId, address pendingOwner);

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @dev Returns the 'Profile' for a '_profileId' passed
    /// @param _profileId The 'profileId' to return the 'Profile' for
    /// @return profile The 'Profile' for the '_profileId' passed
    function getProfileById(bytes32 _profileId) external view returns (Profile memory profile);

    /// @dev Returns the 'Profile' for an '_anchor' passed
    /// @param _anchor The 'anchor' to return the 'Profile' for
    /// @return profile The 'Profile' for the '_anchor' passed
    function getProfileByAnchor(address _anchor) external view returns (Profile memory profile);

    /// @dev Returns a boolean if the '_account' is a member or owner of the '_profileId' passed in
    /// @param _profileId The 'profileId' to check if the '_account' is a member or owner of
    /// @param _account The 'account' to check if they are a member or owner of the '_profileId' passed in
    /// @return isOwnerOrMemberOfProfile A boolean if the '_account' is a member or owner of the '_profileId' passed in
    function isOwnerOrMemberOfProfile(bytes32 _profileId, address _account)
        external
        view
        returns (bool isOwnerOrMemberOfProfile);

    /// @dev Returns a boolean if the '_account' is an owner of the '_profileId' passed in
    /// @param _profileId The 'profileId' to check if the '_account' is an owner of
    /// @param _owner The 'owner' to check if they are an owner of the '_profileId' passed in
    /// @return isOwnerOfProfile A boolean if the '_account' is an owner of the '_profileId' passed in
    function isOwnerOfProfile(bytes32 _profileId, address _owner) external view returns (bool isOwnerOfProfile);

    /// @dev Returns a boolean if the '_account' is a member of the '_profileId' passed in
    /// @param _profileId The 'profileId' to check if the '_account' is a member of
    /// @param _member The 'member' to check if they are a member of the '_profileId' passed in
    /// @return isMemberOfProfile A boolean if the '_account' is a member of the '_profileId' passed in
    function isMemberOfProfile(bytes32 _profileId, address _member) external view returns (bool isMemberOfProfile);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @dev Creates a new 'Profile' and returns the 'profileId' of the new profile
    ///
    /// Note: The 'name' and 'nonce' are used to generate the 'anchor' address
    ///
    /// Requirements: None, anyone can create a new profile
    ///
    /// @param _nonce The nonce to use to generate the 'anchor' address
    /// @param _name The name to use to generate the 'anchor' address
    /// @param _metadata The 'Metadata' to use to generate the 'anchor' address
    /// @param _owner The 'owner' to use to generate the 'anchor' address
    /// @param _members The 'members' to use to generate the 'anchor' address
    /// @return profileId The 'profileId' of the new profile
    function createProfile(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _owner,
        address[] memory _members
    ) external returns (bytes32 profileId);

    /// @dev Updates the 'name' of the '_profileId' passed in and returns the new 'anchor' address
    ///
    /// Requirements: Only the 'Profile' owner can update the name
    ///
    /// Note: The 'name' and 'nonce' are used to generate the 'anchor' address and this will update the 'anchor'
    ///       so please use caution. You can always recreate your 'anchor' address by updating the name back
    ///       to the original name used to create the profile.
    ///
    /// @param _profileId The 'profileId' to update the name for
    /// @param _name The new 'name' value
    /// @return anchor The new 'anchor' address
    function updateProfileName(bytes32 _profileId, string memory _name) external returns (address anchor);

    /// @dev Updates the 'Metadata' of the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can update the metadata
    ///
    /// @param _profileId The 'profileId' to update the metadata for
    /// @param _metadata The new 'Metadata' value
    function updateProfileMetadata(bytes32 _profileId, Metadata memory _metadata) external;

    /// @dev Updates the pending 'owner' of the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can update the pending owner
    ///
    /// @param _profileId The 'profileId' to update the pending owner for
    /// @param _pendingOwner The new pending 'owner' value
    function updateProfilePendingOwner(bytes32 _profileId, address _pendingOwner) external;

    /// @dev Accepts the pending 'owner' of the '_profileId' passed in
    ///
    /// Requirements: Only the pending owner can accept the ownership
    ///
    /// @param _profileId The 'profileId' to accept the ownership for
    function acceptProfileOwnership(bytes32 _profileId) external;

    /// @dev Adds members to the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can add members
    ///
    /// @param _profileId The 'profileId' to add members to
    /// @param _members The members to add to the '_profileId' passed in
    function addMembers(bytes32 _profileId, address[] memory _members) external;

    /// @dev Removes members from the '_profileId' passed in
    ///
    /// Requirements: Only the 'Profile' owner can remove members
    ///
    /// @param _profileId The 'profileId' to remove members from
    /// @param _members The members to remove from the '_profileId' passed in
    function removeMembers(bytes32 _profileId, address[] memory _members) external;

    /// @dev Recovers funds from the contract
    ///
    /// Requirements: Must be the Allo owner
    ///
    /// @param _token The token you want to use to recover funds
    /// @param _recipient The recipient of the recovered funds
    function recoverFunds(address _token, address _recipient) external;
}

// Interfaces

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title IStrategy Interface
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co> @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice BaseStrategy is the base contract that all strategies should inherit from and uses this interface.

interface IStrategy {
    /// ======================
    /// ======= Storage ======
    /// ======================

    /// @notice The Status enum that all recipients are based from
    enum Status {
        None,
        Pending,
        Accepted,
        Rejected,
        Appealed,
        InReview,
        Canceled
    }

    /// @notice Payout summary struct to hold the payout data
    struct PayoutSummary {
        address recipientAddress;
        uint256 amount;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Emitted when strategy is initialized.
    /// @param poolId The ID of the pool
    /// @param data The data passed to the 'initialize' function
    event Initialized(uint256 poolId, bytes data);

    /// @notice Emitted when a recipient is registered.
    /// @param recipientId The ID of the recipient
    /// @param data The data passed to the 'registerRecipient' function
    /// @param sender The sender
    event Registered(address indexed recipientId, bytes data, address sender);

    /// @notice Emitted when a recipient is allocated to.
    /// @param recipientId The ID of the recipient
    /// @param amount The amount allocated
    /// @param token The token allocated
    event Allocated(address indexed recipientId, uint256 amount, address token, address sender);

    /// @notice Emitted when tokens are distributed.
    /// @param recipientId The ID of the recipient
    /// @param recipientAddress The recipient
    /// @param amount The amount distributed
    /// @param sender The sender
    event Distributed(address indexed recipientId, address recipientAddress, uint256 amount, address sender);

    /// @notice Emitted when pool is set to active status.
    /// @param active The status of the pool
    event PoolActive(bool active);

    /// ======================
    /// ======= Views ========
    /// ======================

    /// @notice Getter for the address of the Allo contract.
    /// @return The 'Allo' contract
    function getAllo() external view returns (IAllo);

    /// @notice Getter for the 'poolId' for this strategy.
    /// @return The ID of the pool
    function getPoolId() external view returns (uint256);

    /// @notice Getter for the 'id' of the strategy.
    /// @return The ID of the strategy
    function getStrategyId() external view returns (bytes32);

    /// @notice Checks whether a allocator is valid or not, will usually be true for all strategies
    ///      and will depend on the strategy implementation.
    /// @param _allocator The allocator to check
    /// @return Whether the allocator is valid or not
    function isValidAllocator(address _allocator) external view returns (bool);

    /// @notice whether pool is active.
    /// @return Whether the pool is active or not
    function isPoolActive() external returns (bool);

    /// @notice Checks the amount of tokens in the pool.
    /// @return The balance of the pool
    function getPoolAmount() external view returns (uint256);

    /// @notice Increases the balance of the pool.
    /// @param _amount The amount to increase the pool by
    function increasePoolAmount(uint256 _amount) external;

    /// @notice Checks the status of a recipient probably tracked in a mapping, but will depend on the implementation
    ///      for example, the OpenSelfRegistration only maps users to bool, and then assumes Accepted for those
    ///      since there is no need for Pending or Rejected.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function getRecipientStatus(address _recipientId) external view returns (Status);

    /// @notice Checks the amount allocated to a recipient for distribution.
    /// @dev Input the values you would send to distribute(), get the amounts each recipient in the array would receive.
    ///      The encoded '_data' will be determined by the strategy, and will be used to determine the payout.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The encoded data
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        returns (PayoutSummary[] memory);

    /// ======================
    /// ===== Functions ======
    /// ======================

    /// @notice
    /// @dev The default BaseStrategy version will not use the data  if a strategy wants to use it, they will overwrite it,
    ///      use it, and then call super.initialize().
    /// @param _poolId The ID of the pool
    /// @param _data The encoded data
    function initialize(uint256 _poolId, bytes memory _data) external;

    /// @notice This will register a recipient, set their status (and any other strategy specific values), and
    ///         return the ID of the recipient.
    /// @dev Able to change status all the way up to 'Accepted', or to 'Pending' and if there are more steps, additional
    ///      functions should be added to allow the owner to check this. The owner could also check attestations directly
    ///      and then accept for instance. The '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return The ID of the recipient
    function registerRecipient(bytes memory _data, address _sender) external payable returns (address);

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(bytes memory _data, address _sender) external payable;

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender) external;
}

// Internal Libraries

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Allo Interface
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Interface for the Allo contract. It exposes all functions needed to use the Allo protocol.
interface IAllo {
    /// ======================
    /// ======= Structs ======
    /// ======================

    /// @notice the Pool struct that all strategy pools are based from
    struct Pool {
        bytes32 profileId;
        IStrategy strategy;
        address token;
        Metadata metadata;
        bytes32 managerRole;
        bytes32 adminRole;
    }

    /// ======================
    /// ======= Events =======
    /// ======================

    /// @notice Event emitted when a new pool is created
    /// @param poolId ID of the pool created
    /// @param profileId ID of the profile the pool is associated with
    /// @param strategy Address of the strategy contract
    /// @param token Address of the token pool was funded with when created
    /// @param amount Amount pool was funded with when created
    /// @param metadata Pool metadata
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    /// @notice Emitted when a pools metadata is updated
    /// @param poolId ID of the pool updated
    /// @param metadata Pool metadata that was updated
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);

    /// @notice Emitted when a pool is funded
    /// @param poolId ID of the pool funded
    /// @param amount Amount funded to the pool
    /// @param fee Amount of the fee paid to the treasury
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);

    /// @notice Emitted when the base fee is paid
    /// @param poolId ID of the pool the base fee was paid for
    /// @param amount Amount of the base fee paid
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);

    /// @notice Emitted when the treasury address is updated
    /// @param treasury Address of the new treasury
    event TreasuryUpdated(address treasury);

    /// @notice Emitted when the percent fee is updated
    /// @param percentFee New percentage for the fee
    event PercentFeeUpdated(uint256 percentFee);

    /// @notice Emitted when the base fee is updated
    /// @param baseFee New base fee amount
    event BaseFeeUpdated(uint256 baseFee);

    /// @notice Emitted when the registry address is updated
    /// @param registry Address of the new registry
    event RegistryUpdated(address registry);

    /// @notice Emitted when a strategy is approved and added to the cloneable strategies
    /// @param strategy Address of the strategy approved
    event StrategyApproved(address strategy);

    /// @notice Emitted when a strategy is removed from the cloneable strategies
    /// @param strategy Address of the strategy removed
    event StrategyRemoved(address strategy);

    /// ====================================
    /// ==== External/Public Functions =====
    /// ====================================

    /// @notice Initialize the Allo contract
    /// @param _registry Address of the registry contract
    /// @param _treasury Address of the treasury
    /// @param _percentFee Percentage for the fee
    /// @param _baseFee Base fee amount
    function initialize(address _registry, address payable _treasury, uint256 _percentFee, uint256 _baseFee) external;

    /// @notice Updates a pools metadata.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _poolId The ID of the pool to update
    /// @param _metadata The new metadata to set
    function updatePoolMetadata(uint256 _poolId, Metadata memory _metadata) external;

    /// @notice Update the registry address.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _registry The new registry address
    function updateRegistry(address _registry) external;

    /// @notice Updates the treasury address.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _treasury The new treasury address
    function updateTreasury(address payable _treasury) external;

    /// @notice Updates the percentage for the fee.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _percentFee The new percentage for the fee
    function updatePercentFee(uint256 _percentFee) external;

    /// @notice Updates the base fee.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _baseFee The new base fee
    function updateBaseFee(uint256 _baseFee) external;

    /// @notice Adds a strategy to the cloneable strategies.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _strategy The address of the strategy to add
    function addToCloneableStrategies(address _strategy) external;

    /// @notice Removes a strategy from the cloneable strategies.
    /// @dev 'msg.sender' must be the Allo contract owner.
    /// @param _strategy The address of the strategy to remove
    function removeFromCloneableStrategies(address _strategy) external;

    /// @notice Adds a pool manager to the pool.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _poolId The ID of the pool to add the manager to
    /// @param _manager The address of the manager to add
    function addPoolManager(uint256 _poolId, address _manager) external;

    /// @notice Removes a pool manager from the pool.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _poolId The ID of the pool to remove the manager from
    /// @param _manager The address of the manager to remove
    function removePoolManager(uint256 _poolId, address _manager) external;

    /// @notice Recovers funds from a pool.
    /// @dev 'msg.sender' must be a pool admin.
    /// @param _token The token to recover
    /// @param _recipient The address to send the recovered funds to
    function recoverFunds(address _token, address _recipient) external;

    /// @notice Registers a recipient and emits {Registered} event if successful and may be handled differently by each strategy.
    /// @param _poolId The ID of the pool to register the recipient for
    function registerRecipient(uint256 _poolId, bytes memory _data) external payable returns (address);

    /// @notice Registers a batch of recipients.
    /// @param _poolIds The pool ID's to register the recipients for
    /// @param _data The data to pass to the strategy and may be handled differently by each strategy
    function batchRegisterRecipient(uint256[] memory _poolIds, bytes[] memory _data)
        external
        returns (address[] memory);

    /// @notice Funds a pool.
    /// @dev 'msg.value' must be greater than 0 if the token is the native token
    ///       or '_amount' must be greater than 0 if the token is not the native token.
    /// @param _poolId The ID of the pool to fund
    /// @param _amount The amount to fund the pool with
    function fundPool(uint256 _poolId, uint256 _amount) external payable;

    /// @notice Allocates funds to a recipient.
    /// @dev Each strategy will handle the allocation of funds differently.
    /// @param _poolId The ID of the pool to allocate funds from
    /// @param _data The data to pass to the strategy and may be handled differently by each strategy.
    function allocate(uint256 _poolId, bytes memory _data) external payable;

    /// @notice Allocates funds to multiple recipients.
    /// @dev Each strategy will handle the allocation of funds differently
    function batchAllocate(uint256[] calldata _poolIds, bytes[] memory _datas) external;

    /// @notice Distributes funds to recipients and emits {Distributed} event if successful
    /// @dev Each strategy will handle the distribution of funds differently
    /// @param _poolId The ID of the pool to distribute from
    /// @param _recipientIds The recipient ids to distribute to
    /// @param _data The data to pass to the strategy and may be handled differently by each strategy
    function distribute(uint256 _poolId, address[] memory _recipientIds, bytes memory _data) external;

    /// =========================
    /// ==== View Functions =====
    /// =========================

    /// @notice Checks if an address is a pool admin.
    /// @param _poolId The ID of the pool to check
    /// @param _address The address to check
    /// @return 'true' if the '_address' is a pool admin, otherwise 'false'
    function isPoolAdmin(uint256 _poolId, address _address) external view returns (bool);

    /// @notice Checks if an address is a pool manager.
    /// @param _poolId The ID of the pool to check
    /// @param _address The address to check
    /// @return 'true' if the '_address' is a pool manager, otherwise 'false'
    function isPoolManager(uint256 _poolId, address _address) external view returns (bool);

    /// @notice Checks if a strategy is cloneable (is in the cloneableStrategies mapping).
    /// @param _strategy The address of the strategy to check
    /// @return 'true' if the '_strategy' is cloneable, otherwise 'false'
    function isCloneableStrategy(address _strategy) external view returns (bool);

    /// @notice Returns the address of the strategy for a given 'poolId'
    /// @param _poolId The ID of the pool to check
    /// @return strategy The address of the strategy for the ID of the pool passed in
    function getStrategy(uint256 _poolId) external view returns (address);

    /// @notice Returns the current percent fee
    /// @return percentFee The current percentage for the fee
    function getPercentFee() external view returns (uint256);

    /// @notice Returns the current base fee
    /// @return baseFee The current base fee
    function getBaseFee() external view returns (uint256);

    /// @notice Returns the current treasury address
    /// @return treasury The current treasury address
    function getTreasury() external view returns (address payable);

    /// @notice Returns the current registry address
    /// @return registry The current registry address
    function getRegistry() external view returns (IRegistry);

    /// @notice Returns the 'Pool' struct for a given 'poolId'
    /// @param _poolId The ID of the pool to check
    /// @return pool The 'Pool' struct for the ID of the pool passed in
    function getPool(uint256 _poolId) external view returns (Pool memory);

    /// @notice Returns the current fee denominator
    /// @dev 1e18 represents 100%
    /// @return feeDenominator The current fee denominator
    function getFeeDenominator() external view returns (uint256);
}

// Core Contracts

// Interfaces

// Libraries

// External Libraries

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for gas griefing protection.
/// - For ERC20s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    ///
    /// Note: This implementation does NOT protect against gas griefing.
    /// Please use `forceSafeTransferETH` for gas griefing protection.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0x00, 0x00, 0x00, 0x00)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0x00, 0x00, 0x00, 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0x00, 0x00) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overridden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, 0x00, 0x00, 0x00, 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0x00, 0x00) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0x00, 0x00, 0x00, 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` is already at 0x60. Load it for the function's return value.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` is already at 0x34. Load it for the function's return value.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // Store the function selector.
                // We can ignore the result of this call. Just need to check the next call.
                pop(call(gas(), token, 0, 0x10, 0x44, 0x00, 0x00))
                mstore(0x34, amount) // Store back the original `amount`.

                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())),
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    // Store the function selector of `ApproveFailed()`.
                    mstore(0x00, 0x3e3f8f73)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// Internal Libraries

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Native token information
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice This is used to define the address of the native token for the protocol
contract Native {
    /// @notice Address of the native token
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Transfer contract
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice A helper contract to transfer tokens within Allo protocol
/// @dev Handles the transfer of tokens to an address
contract Transfer is Native {
    /// @notice Thrown when the amount of tokens sent does not match the amount of tokens expected
    error AMOUNT_MISMATCH();

    /// @notice This holds the details for a transfer
    struct TransferData {
        address from;
        address to;
        uint256 amount;
    }

    /// @notice Transfer an amount of a token to an array of addresses
    /// @param _token The address of the token
    /// @param _transferData TransferData[]
    /// @return Whether the transfer was successful or not
    function _transferAmountsFrom(address _token, TransferData[] memory _transferData) internal returns (bool) {
        uint256 msgValue = msg.value;

        for (uint256 i; i < _transferData.length;) {
            TransferData memory transferData = _transferData[i];

            if (_token == NATIVE) {
                msgValue -= transferData.amount;
                SafeTransferLib.safeTransferETH(transferData.to, transferData.amount);
            } else {
                SafeTransferLib.safeTransferFrom(_token, transferData.from, transferData.to, transferData.amount);
            }

            unchecked {
                i++;
            }
        }

        if (msgValue != 0) revert AMOUNT_MISMATCH();

        return true;
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The address of the token
    /// @param _transferData Individual TransferData
    /// @return Whether the transfer was successful or not
    function _transferAmountFrom(address _token, TransferData memory _transferData) internal returns (bool) {
        uint256 amount = _transferData.amount;
        if (_token == NATIVE) {
            // Native Token
            if (msg.value < amount) revert AMOUNT_MISMATCH();

            SafeTransferLib.safeTransferETH(_transferData.to, amount);
        } else {
            SafeTransferLib.safeTransferFrom(_token, _transferData.from, _transferData.to, amount);
        }
        return true;
    }

    /// @notice Transfer an amount of a token to an address
    /// @param _token The token to transfer
    /// @param _to The address to transfer to
    /// @param _amount The amount to transfer
    function _transferAmount(address _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE) {
            SafeTransferLib.safeTransferETH(_to, _amount);
        } else {
            SafeTransferLib.safeTransfer(_token, _to, _amount);
        }
    }
}

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Errors
/// @author @thelostone-mc <aditya@gitcoin.co>, @KurtMerbeth <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>
/// @notice Library containing all custom errors the protocol may revert with.
contract Errors {
    /// ======================
    /// ====== Generic =======
    /// ======================

    /// @notice Thrown as a general error when input / data is invalid
    error INVALID();

    /// @notice Thrown when mismatch in decoding data
    error MISMATCH();

    /// @notice Thrown when not enough funds are available
    error NOT_ENOUGH_FUNDS();

    /// @notice Thrown when user is not authorized
    error UNAUTHORIZED();

    /// @notice Thrown when address is the zero address
    error ZERO_ADDRESS();

    /// ======================
    /// ====== Registry ======
    /// ======================

    /// @dev Thrown when the nonce passed has been used or not available
    error NONCE_NOT_AVAILABLE();

    /// @dev Thrown when the 'msg.sender' is not the pending owner on ownership transfer
    error NOT_PENDING_OWNER();

    /// @dev Thrown if the anchor creation fails
    error ANCHOR_ERROR();

    /// ======================
    /// ======== Allo ========
    /// ======================

    /// @notice Thrown when the strategy is not approved
    error NOT_APPROVED_STRATEGY();

    /// @notice Thrown when the strategy is approved and should be cloned
    error IS_APPROVED_STRATEGY();

    /// @notice Thrown when the fee is below 1e18 which is the fee percentage denominator
    error INVALID_FEE();

    /// ======================
    /// ===== IStrategy ======
    /// ======================

    /// @notice Thrown when data is already intialized
    error ALREADY_INITIALIZED();

    /// @notice Thrown when data is yet to be initialized
    error NOT_INITIALIZED();

    /// @notice Thrown when an invalid address is used
    error INVALID_ADDRESS();

    /// @notice Thrown when a pool is inactive
    error POOL_INACTIVE();

    /// @notice Thrown when a pool is already active
    error POOL_ACTIVE();

    /// @notice Thrown when two arrays length are not equal
    error ARRAY_MISMATCH();

    /// @notice Thrown when the registration is invalid.
    error INVALID_REGISTRATION();

    /// @notice Thrown when the metadata is invalid.
    error INVALID_METADATA();

    /// @notice Thrown when the recipient is not accepted.
    error RECIPIENT_NOT_ACCEPTED();

    /// @notice Thrown when recipient is already accepted.
    error RECIPIENT_ALREADY_ACCEPTED();

    /// @notice Thrown when registration is not active.
    error REGISTRATION_NOT_ACTIVE();

    /// @notice Thrown when there is an error in recipient.
    error RECIPIENT_ERROR(address recipientId);

    /// @notice Thrown when the allocation is not active.
    error ALLOCATION_NOT_ACTIVE();

    /// @notice Thrown when the allocation is not ended.
    error ALLOCATION_NOT_ENDED();

    /// @notice Thrown when the allocation is active.
    error ALLOCATION_ACTIVE();
}

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡟⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠸⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣴⣴⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠃⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣰⣿⣿⣿⡿⠋⠁⠀⠀⠈⠘⠹⣿⣿⣿⣿⣆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡀⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⠀⡀⢀⠀⡀⢀⠀⡀⢈⢿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⢿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠿⠻⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣧⠀⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⡀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠙⠋⠛⠙⠋⠛⠙⠋⠛⠙⠋⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠟⠿⠟⠿⠆⠀⠸⠿⠿⠟⠯⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠈⠉⠻⠻⡿⣿⢿⡿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title BaseStrategy Contract
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice This contract is the base contract for all strategies
/// @dev This contract is implemented by all strategies.
abstract contract BaseStrategy is IStrategy, Transfer, Errors {
    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    IAllo internal immutable allo;
    bytes32 internal immutable strategyId;
    bool internal poolActive;
    uint256 internal poolId;
    uint256 internal poolAmount;

    /// ====================================
    /// ========== Constructor =============
    /// ====================================

    /// @notice Constructor to set the Allo contract and "strategyId'.
    /// @param _allo Address of the Allo contract.
    /// @param _name Name of the strategy
    constructor(address _allo, string memory _name) {
        allo = IAllo(_allo);
        strategyId = keccak256(abi.encode(_name));
    }

    /// ====================================
    /// =========== Modifiers ==============
    /// ====================================

    /// @notice Modifier to check if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    modifier onlyAllo() {
        _checkOnlyAllo();
        _;
    }

    /// @notice Modifier to check if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    modifier onlyPoolManager(address _sender) {
        _checkOnlyPoolManager(_sender);
        _;
    }

    /// @notice Modifier to check if the pool is active.
    /// @dev Reverts if the pool is not active.
    modifier onlyActivePool() {
        _checkOnlyActivePool();
        _;
    }

    /// @notice Modifier to check if the pool is inactive.
    /// @dev Reverts if the pool is active.
    modifier onlyInactivePool() {
        _checkInactivePool();
        _;
    }

    /// @notice Modifier to check if the pool is initialized.
    /// @dev Reverts if the pool is not initialized.
    modifier onlyInitialized() {
        _checkOnlyInitialized();
        _;
    }

    /// ================================
    /// =========== Views ==============
    /// ================================

    /// @notice Getter for the 'Allo' contract.
    /// @return The Allo contract
    function getAllo() external view override returns (IAllo) {
        return allo;
    }

    /// @notice Getter for the 'poolId'.
    /// @return The ID of the pool
    function getPoolId() external view override returns (uint256) {
        return poolId;
    }

    /// @notice Getter for the 'strategyId'.
    /// @return The ID of the strategy
    function getStrategyId() external view override returns (bytes32) {
        return strategyId;
    }

    /// @notice Getter for the 'poolAmount'.
    /// @return The balance of the pool
    function getPoolAmount() external view virtual override returns (uint256) {
        return poolAmount;
    }

    /// @notice Getter for whether or not the pool is active.
    /// @return 'true' if the pool is active, otherwise 'false'
    function isPoolActive() external view override returns (bool) {
        return _isPoolActive();
    }

    /// @notice Getter for the status of a recipient.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function getRecipientStatus(address _recipientId) external view virtual returns (Status) {
        return _getRecipientStatus(_recipientId);
    }

    /// ====================================
    /// =========== Functions ==============
    /// ====================================

    /// @notice Initializes the 'Basetrategy'.
    /// @dev Will revert if the poolId is invalid or already initialized
    /// @param _poolId ID of the pool
    function __BaseStrategy_init(uint256 _poolId) internal virtual onlyAllo {
        // check if pool ID is not initialized already, if it is, revert
        if (poolId != 0) revert ALREADY_INITIALIZED();

        // check if pool ID is valid and not zero (0), if it is, revert
        if (_poolId == 0) revert INVALID();
        poolId = _poolId;
    }

    /// @notice Increases the pool amount.
    /// @dev Increases the 'poolAmount' by '_amount'. Only 'Allo' contract can call this.
    /// @param _amount The amount to increase the pool by
    function increasePoolAmount(uint256 _amount) external override onlyAllo {
        _beforeIncreasePoolAmount(_amount);
        poolAmount += _amount;
        _afterIncreasePoolAmount(_amount);
    }

    /// @notice Registers a recipient.
    /// @dev Registers a recipient and returns the ID of the recipient. The encoded '_data' will be determined by the
    ///      strategy implementation. Only 'Allo' contract can call this when it is initialized.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return recipientId The recipientId
    function registerRecipient(bytes memory _data, address _sender)
        external
        payable
        onlyAllo
        onlyInitialized
        returns (address recipientId)
    {
        _beforeRegisterRecipient(_data, _sender);
        recipientId = _registerRecipient(_data, _sender);
        _afterRegisterRecipient(_data, _sender);
    }

    /// @notice Allocates to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function allocate(bytes memory _data, address _sender) external payable onlyAllo onlyInitialized {
        _beforeAllocate(_data, _sender);
        _allocate(_data, _sender);
        _afterAllocate(_data, _sender);
    }

    /// @notice Distributes funds (tokens) to recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation. Only 'Allo' contract can
    ///      call this when it is initialized.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function distribute(address[] memory _recipientIds, bytes memory _data, address _sender)
        external
        onlyAllo
        onlyInitialized
    {
        _beforeDistribute(_recipientIds, _data, _sender);
        _distribute(_recipientIds, _data, _sender);
        _afterDistribute(_recipientIds, _data, _sender);
    }

    /// @notice Gets the payout summary for recipients.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to get the payout summary for the recipients
    /// @return The payout summary for the recipients
    function getPayouts(address[] memory _recipientIds, bytes[] memory _data)
        external
        view
        virtual
        override
        returns (PayoutSummary[] memory)
    {
        uint256 recipientLength = _recipientIds.length;
        // check if the length of the recipient IDs and data arrays are equal, if they are not, revert
        if (recipientLength != _data.length) revert ARRAY_MISMATCH();

        PayoutSummary[] memory payouts = new PayoutSummary[](recipientLength);
        for (uint256 i; i < recipientLength;) {
            payouts[i] = _getPayout(_recipientIds[i], _data[i]);
            unchecked {
                i++;
            }
        }
        return payouts;
    }

    /// @notice Checks if the '_allocator' is a valid allocator.
    /// @dev How the allocator is determined is up to the strategy implementation.
    /// @param _allocator The address to check if it is a valid allocator for the strategy.
    /// @return 'true' if the address is a valid allocator, 'false' otherwise
    function isValidAllocator(address _allocator) external view virtual override returns (bool) {
        return _isValidAllocator(_allocator);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the 'msg.sender' is the Allo contract.
    /// @dev Reverts if the 'msg.sender' is not the Allo contract.
    function _checkOnlyAllo() internal view {
        if (msg.sender != address(allo)) revert UNAUTHORIZED();
    }

    /// @notice Checks if the '_sender' is a pool manager.
    /// @dev Reverts if the '_sender' is not a pool manager.
    /// @param _sender The address to check if they are a pool manager
    function _checkOnlyPoolManager(address _sender) internal view {
        if (!allo.isPoolManager(poolId, _sender)) revert UNAUTHORIZED();
    }

    /// @notice Checks if the pool is active.
    /// @dev Reverts if the pool is not active.
    function _checkOnlyActivePool() internal view {
        if (!poolActive) revert POOL_INACTIVE();
    }

    /// @notice Checks if the pool is inactive.
    /// @dev Reverts if the pool is active.
    function _checkInactivePool() internal view {
        if (poolActive) revert POOL_ACTIVE();
    }

    /// @notice Checks if the pool is initialized.
    /// @dev Reverts if the pool is not initialized.
    function _checkOnlyInitialized() internal view {
        if (poolId == 0) revert NOT_INITIALIZED();
    }

    /// @notice Set the pool to active or inactive status.
    /// @dev This will emit a 'PoolActive()' event. Used by the strategy implementation.
    /// @param _active The status to set, 'true' means active, 'false' means inactive
    function _setPoolActive(bool _active) internal {
        poolActive = _active;
        emit PoolActive(_active);
    }

    /// @notice Checks if the pool is active.
    /// @dev Used by the strategy implementation.
    /// @return 'true' if the pool is active, otherwise 'false'
    function _isPoolActive() internal view virtual returns (bool) {
        return poolActive;
    }

    /// @notice Checks if the allocator is valid
    /// @param _allocator The allocator address
    /// @return 'true' if the allocator is valid, otherwise 'false'
    function _isValidAllocator(address _allocator) internal view virtual returns (bool);

    /// @notice This will register a recipient, set their status (and any other strategy specific values), and
    ///         return the ID of the recipient.
    /// @dev Able to change status all the way up to Accepted, or to Pending and if there are more steps, additional
    ///      functions should be added to allow the owner to check this. The owner could also check attestations directly
    ///      and then Accept for instance.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    /// @return The ID of the recipient
    function _registerRecipient(bytes memory _data, address _sender) internal virtual returns (address);

    /// @notice This will allocate to a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _allocate(bytes memory _data, address _sender) internal virtual;

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientIds The ids of the recipients to distribute to
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual;

    /// @notice This will get the payout summary for a recipient.
    /// @dev The encoded '_data' will be determined by the strategy implementation.
    /// @param _recipientId The ID of the recipient
    /// @param _data The data to use to get the payout summary for the recipient
    /// @return The payout summary for the recipient
    function _getPayout(address _recipientId, bytes memory _data)
        internal
        view
        virtual
        returns (PayoutSummary memory);

    /// @notice This will get the status of a recipient.
    /// @param _recipientId The ID of the recipient
    /// @return The status of the recipient
    function _getRecipientStatus(address _recipientId) internal view virtual returns (Status);

    /// ===================================
    /// ============== Hooks ==============
    /// ===================================

    /// @notice Hook called before increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _beforeIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called after increasing the pool amount.
    /// @param _amount The amount to increase the pool by
    function _afterIncreasePoolAmount(uint256 _amount) internal virtual {}

    /// @notice Hook called before registering a recipient.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _beforeRegisterRecipient(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after registering a recipient.
    /// @param _data The data to use to register the recipient
    /// @param _sender The address of the sender
    function _afterRegisterRecipient(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called before allocating to a recipient.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _beforeAllocate(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after allocating to a recipient.
    /// @param _data The data to use to allocate to the recipient
    /// @param _sender The address of the sender
    function _afterAllocate(bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called before distributing funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function _beforeDistribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual {}

    /// @notice Hook called after distributing funds (tokens) to recipients.
    /// @param _recipientIds The IDs of the recipients
    /// @param _data The data to use to distribute to the recipients
    /// @param _sender The address of the sender
    function _afterDistribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual {}
}

// Internal Libraries

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⣀⡀⡀⠀⠀⠀⢀⡀⣀⡀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣮⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⢿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡏⠘⣿⣿⣿⣷⡀          ⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⣿⣿⣿⣿⣾⠻⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡿⠀⠀⠹⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣶⣶⣶⣦⣦⣀⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⡿⠁⠀⠙⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠁⠀⠀⠀⢻⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡄⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⣴⣿⣿⣿⡿⠋⠁⠀⠀⠀⠉⠻⣿⣿⣿⣿⡆⠀⠀⠀
// ⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢰⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⠄⠀⠀
// ⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣟⢀⢀⢀⢀⢀⢀⢀⢀⠈⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⢸⣿⣿⣿⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀
// ⠀⠀⣠⣿⣿⣿⣿⣿⣿⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣧⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⡿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣿⣷⡀⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠸⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠂⠀⠀
// ⠀⠀⠙⠛⠟⠿⠻⠛⠉⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⡿⠁⠀          ⠀⠀⢿⣿⣿⣿⣧⠀ ⠀⢸⣿⣿⣿⡯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⢻⣿⣿⣿⣷⣀⢀⠀⠀⠀⣀⣰⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣯⠀⠀⠀⢸⣿⣿⣿⡯⠀⠀⠀⠀⠹⢿⣿⣿⣿⣿⣾⣾⣷⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠋⠋⠋⠋⠋⠛⠙⠋⠛⠙⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠠⠿⠻⠟⠿⠃            ⠀     ⠟⠿⠟⠿⠆⠀⠸⠿⠿⠻⠗⠀⠀⠀⠸⠿⠿⠿⠏⠀⠀⠀⠀⠀⠀⠙⠛⠿⢿⢿⡿⡿⡿⠟⠏⠃⠀⠀⠀⠀⠀
//                    allo.gitcoin.co

/// @title Donation Voting Merkle Distribution Strategy
/// @author @thelostone-mc <aditya@gitcoin.co>, @0xKurt <kurt@gitcoin.co>, @codenamejason <jason@gitcoin.co>, @0xZakk <zakk@gitcoin.co>, @nfrgosselin <nate@gitcoin.co>
/// @notice Strategy for donation voting allocation with a merkle distribution
abstract contract DonationVotingMerkleDistributionBaseStrategy is Native, BaseStrategy, Multicall {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Struct to hold details of the application status
    /// @dev Application status is stored in a bitmap. Each 4 bits represents the status of a recipient,
    /// defined as 'index' here. The first 4 bits of the 256 bits represent the status of the first recipient,
    /// the second 4 bits represent the status of the second recipient, and so on.
    ///
    /// The 'rowIndex' is the index of the row in the bitmap, and the 'statusRow' is the value of the row.
    /// The 'statusRow' is updated when the status of a recipient changes.
    ///
    /// Note: Since we need 4 bits to store a status, one row of the bitmap can hold the status information of 256/4 recipients.
    ///
    /// For example, if we have 5 recipients, the bitmap will look like this:
    /// | recipient1 | recipient2 | recipient3 | recipient4 | recipient5 | 'rowIndex'
    /// |     0000   |    0001    |    0010    |    0011    |    0100    | 'statusRow'
    /// |     none   |   pending  |  accepted  |  rejected  |  appealed  | converted status (0, 1, 2, 3, 4)
    ///
    struct ApplicationStatus {
        uint256 index;
        uint256 statusRow;
    }

    /// @notice Stores the details of the recipients.
    struct Recipient {
        // If false, the recipientAddress is the anchor of the profile
        bool useRegistryAnchor;
        address recipientAddress;
        Metadata metadata;
    }

    /// @notice Stores the details of the distribution.
    struct Distribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// @notice Stores the initialize data for the strategy
    struct InitializeData {
        bool useRegistryAnchor;
        bool metadataRequired;
        bool stream;
        uint64 registrationStartTime;
        uint64 registrationEndTime;
        uint64 allocationStartTime;
        uint64 allocationEndTime;
        address drips;
        address dripsCaller;
        address dripsAddressDriver;
        address[] allowedTokens;
    }

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a recipient updates their registration
    /// @param recipientId Id of the recipient
    /// @param data The encoded data - (address recipientId, address recipientAddress, Metadata metadata)
    /// @param sender The sender of the transaction
    /// @param status The updated status of the recipient
    event UpdatedRegistration(address indexed recipientId, bytes data, address sender, uint8 status);

    /// @notice Emitted when a recipient is registered and the status is updated
    /// @param rowIndex The index of the row in the bitmap
    /// @param fullRow The value of the row
    /// @param sender The sender of the transaction
    event RecipientStatusUpdated(uint256 indexed rowIndex, uint256 fullRow, address sender);

    /// @notice Emitted when the timestamps are updated
    /// @param registrationStartTime The start time for the registration
    /// @param registrationEndTime The end time for the registration
    /// @param allocationStartTime The start time for the allocation
    /// @param allocationEndTime The end time for the allocation
    /// @param sender The sender of the transaction
    event TimestampsUpdated(
        uint64 registrationStartTime,
        uint64 registrationEndTime,
        uint64 allocationStartTime,
        uint64 allocationEndTime,
        address sender
    );

    /// @notice Emitted when the distribution has been updated with a new merkle root or metadata
    /// @param merkleRoot The merkle root of the distribution
    /// @param metadata The metadata of the distribution
    event DistributionUpdated(bytes32 merkleRoot, Metadata metadata);

    /// @notice Emitted when funds are distributed to a recipient
    /// @param amount The amount of tokens distributed
    /// @param grantee The address of the recipient
    /// @param token The address of the token
    /// @param recipientId The id of the recipient
    event FundsDistributed(uint256 amount, address grantee, address indexed token, address indexed recipientId);

    /// @notice Emitted when a batch payout is successful
    /// @param sender The sender of the transaction
    event BatchPayoutSuccessful(address indexed sender);

    /// ================================
    /// ========== Storage =============
    /// ================================

    /// @notice Metadata containing the distribution data.
    Metadata public distributionMetadata;

    /// @notice Flag to indicate whether to use the registry anchor or not.
    bool public useRegistryAnchor;

    /// @notice Flag to indicate whether metadata is required or not.
    bool public metadataRequired;

    /// @notice Flag to indicate whether the distribution has started or not.
    bool public distributionStarted;

    /// @notice The timestamps in milliseconds for the start and end times.
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint64 public allocationStartTime;
    uint64 public allocationEndTime;

    /// @notice The total amount of tokens allocated to the payout.
    uint256 public totalPayoutAmount;

    /// @notice The total number of recipients.
    uint256 public recipientsCounter;

    /// @notice The registry contract interface.
    IRegistry private _registry;

    /// @notice The merkle root of the distribution will be set by the pool manager.
    bytes32 public merkleRoot;

    /// @notice This is a packed array of booleans, 'statuses[0]' is the first row of the bitmap and allows to
    /// store 256 bits to describe the status of 256 projects. 'statuses[1]' is the second row, and so on
    /// Instead of using 1 bit for each recipient status, we will use 4 bits for each status
    /// to allow 5 statuses:
    /// 0: none
    /// 1: pending
    /// 2: accepted
    /// 3: rejected
    /// 4: appealed
    /// Since it's a mapping the storage it's pre-allocated with zero values, so if we check the
    /// status of an existing recipient, the value is by default 0 (none).
    /// If we want to check the status of an recipient, we take its index from the `recipients` array
    /// and convert it to the 2-bits position in the bitmap.
    mapping(uint256 => uint256) public statusesBitMap;

    /// @notice 'recipientId' => 'statusIndex'
    /// @dev 'statusIndex' is the index of the recipient in the 'statusesBitMap' bitmap.
    mapping(address => uint256) public recipientToStatusIndexes;

    /// @notice This is a packed array of booleans to keep track of claims distributed.
    /// @dev _distributedBitMap[0] is the first row of the bitmap and allows to store 256 bits to describe
    /// the status of 256 claims
    mapping(uint256 => uint256) private _distributedBitMap;

    /// @notice 'token' address => boolean (allowed = true).
    /// @dev This can be updated by the pool manager.
    mapping(address => bool) public allowedTokens;

    /// @notice 'recipientId' => 'Recipient' struct.
    mapping(address => Recipient) internal _recipients;

    /// ================================
    /// ========== Modifier ============
    /// ================================

    /// @notice Modifier to check if the registration is active
    /// @dev This will revert if the registration has not started or if the registration has ended.
    modifier onlyActiveRegistration() {
        _checkOnlyActiveRegistration();
        _;
    }

    /// @notice Modifier to check if the allocation is active
    /// @dev This will revert if the allocation has not started or if the allocation has ended.
    modifier onlyActiveAllocation() {
        _checkOnlyActiveAllocation();
        _;
    }

    /// @notice Modifier to check if the allocation has ended
    /// @dev This will revert if the allocation has not ended.
    modifier onlyAfterAllocation() {
        _checkOnlyAfterAllocation();
        _;
    }

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Initializes the strategy
    /// @dev This will revert if the strategy is already initialized and 'msg.sender' is not the 'Allo' contract.
    /// @param _poolId The 'poolId' to initialize
    /// @param _data The data to be decoded to initialize the strategy
    /// @custom:data InitializeData(bool _useRegistryAnchor, bool _metadataRequired, uint64 _registrationStartTime,
    ///               uint64 _registrationEndTime, uint64 _allocationStartTime, uint64 _allocationEndTime,
    ///               address _drips, address _dripsCaller, address _dripsAddressDriver, address[] memory _allowedTokens)
    function initialize(uint256 _poolId, bytes memory _data) external virtual override onlyAllo {
        (InitializeData memory initializeData) = abi.decode(_data, (InitializeData));
        _beforeInitialize(_poolId, initializeData);
        __donationVotingStrategyInit(_poolId, initializeData);
        _afterInitialize(_poolId, initializeData);
        emit Initialized(_poolId, _data);
    }

    /// @notice Initializes this strategy as well as the BaseStrategy.
    /// @dev This will revert if the strategy is already initialized. Emits a 'TimestampsUpdated()' event.
    /// @param _poolId The 'poolId' to initialize
    /// @param _initializeData The data to be decoded to initialize the strategy
    function __donationVotingStrategyInit(uint256 _poolId, InitializeData memory _initializeData) internal {
        // Initialize the BaseStrategy with the '_poolId'
        __BaseStrategy_init(_poolId);

        // Initialize required values
        useRegistryAnchor = _initializeData.useRegistryAnchor;
        metadataRequired = _initializeData.metadataRequired;
        _registry = allo.getRegistry();

        // Set the updated timestamps
        registrationStartTime = _initializeData.registrationStartTime;
        registrationEndTime = _initializeData.registrationEndTime;
        allocationStartTime = _initializeData.allocationStartTime;
        allocationEndTime = _initializeData.allocationEndTime;

        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime);

        // Emit that the timestamps have been updated with the updated values
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );

        uint256 allowedTokensLength = _initializeData.allowedTokens.length;

        // If the length of the allowed tokens is zero, we will allow all tokens
        if (allowedTokensLength == 0) {
            // all tokens
            allowedTokens[address(0)] = true;
        }

        // Loop through the allowed tokens and set them to true
        for (uint256 i; i < allowedTokensLength;) {
            allowedTokens[_initializeData.allowedTokens[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    /// ===============================
    /// ============ Views ============
    /// ===============================

    /// @notice Get a recipient with a '_recipientId'
    /// @param _recipientId ID of the recipient
    /// @return recipient The recipient details
    function getRecipient(address _recipientId) external view returns (Recipient memory recipient) {
        return _getRecipient(_recipientId);
    }

    /// @notice Get recipient status
    /// @dev This will return the 'Status' of the recipient, the 'Status' is used at the strategy
    ///      level and is different from the 'Status' which is used at the protocol level
    /// @param _recipientId ID of the recipient
    /// @return Status of the recipient
    function _getRecipientStatus(address _recipientId) internal view override returns (Status) {
        return Status(_getUintRecipientStatus(_recipientId));
    }

    /// ===============================
    /// ======= External/Custom =======
    /// ===============================

    /// @notice Sets recipient statuses.
    /// @dev The statuses are stored in a bitmap of 4 bits for each recipient. The first 4 bits of the 256 bits represent
    ///      the status of the first recipient, the second 4 bits represent the status of the second recipient, and so on.
    ///      'msg.sender' must be a pool manager and the registration must be active.
    /// Statuses:
    /// - 0: none
    /// - 1: pending
    /// - 2: accepted
    /// - 3: rejected
    /// - 4: appealed
    /// Emits the RecipientStatusUpdated() event.
    /// @param statuses new statuses
    function reviewRecipients(ApplicationStatus[] memory statuses)
        external
        onlyActiveRegistration
        onlyPoolManager(msg.sender)
    {
        // Loop through the statuses and set the status
        for (uint256 i; i < statuses.length;) {
            uint256 rowIndex = statuses[i].index;
            uint256 fullRow = statuses[i].statusRow;

            statusesBitMap[rowIndex] = fullRow;

            // Emit that the recipient status has been updated with the values
            emit RecipientStatusUpdated(rowIndex, fullRow, msg.sender);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Sets the start and end dates.
    /// @dev The timestamps are in milliseconds for the start and end times. The 'msg.sender' must be a pool manager.
    ///      Emits a 'TimestampsUpdated()' event.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function updatePoolTimestamps(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) external onlyPoolManager(msg.sender) {
        // If the timestamps are invalid this will revert - See details in '_isPoolTimestampValid'
        _isPoolTimestampValid(_registrationStartTime, _registrationEndTime, _allocationStartTime, _allocationEndTime);

        // Set the updated timestamps
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        allocationStartTime = _allocationStartTime;
        allocationEndTime = _allocationEndTime;

        // Emit that the timestamps have been updated with the updated values
        emit TimestampsUpdated(
            registrationStartTime, registrationEndTime, allocationStartTime, allocationEndTime, msg.sender
        );
    }

    /// @notice Withdraw funds from pool
    /// @dev This can only be called after the allocation has ended and 30 days have passed. If the
    ///      '_amount' is greater than the pool amount or if 'msg.sender' is not a pool manager.
    /// @param _amount The amount to be withdrawn
    function withdraw(uint256 _amount) external onlyPoolManager(msg.sender) {
        if (block.timestamp <= allocationEndTime + 30 days) {
            revert INVALID();
        }

        IAllo.Pool memory pool = allo.getPool(poolId);

        if (_amount > poolAmount) {
            revert INVALID();
        }

        poolAmount -= _amount;

        // Transfer the tokens to the 'msg.sender' (pool manager calling function)
        _transferAmount(pool.token, msg.sender, _amount);
    }

    /// ==================================
    /// ============ Merkle ==============
    /// ==================================

    /// @notice Invoked by round operator to update the merkle root and distribution Metadata.
    /// @dev This can only be called after the allocation has ended and 'msg.sender' must be a pool manager and allocation must have ended.
    ///      Emits a 'DistributionUpdated()' event.
    /// @param _merkleRoot The merkle root of the distribution
    /// @param _distributionMetadata The metadata of the distribution
    function updateDistribution(bytes32 _merkleRoot, Metadata memory _distributionMetadata)
        external
        onlyAfterAllocation
        onlyPoolManager(msg.sender)
    {
        // If the distribution has already started this will revert, you can only
        // update the distribution before it has started
        if (distributionStarted) {
            revert INVALID();
        }

        merkleRoot = _merkleRoot;
        distributionMetadata = _distributionMetadata;

        // Emit that the distribution has been updated
        emit DistributionUpdated(merkleRoot, distributionMetadata);
    }

    /// @notice Checks if distribution is set.
    /// @return 'true' if distribution is set, otherwise 'false'
    function isDistributionSet() external view returns (bool) {
        return merkleRoot != "";
    }

    /// @notice Utility function to check if distribution is done.
    /// @param _index index of the distribution
    /// @return 'true' if distribution is completed, otherwise 'false'
    function hasBeenDistributed(uint256 _index) external view returns (bool) {
        return _hasBeenDistributed(_index);
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Checks if the registration is active and reverts if not.
    /// @dev This will revert if the registration has not started or if the registration has ended.
    function _checkOnlyActiveRegistration() internal view {
        if (registrationStartTime > block.timestamp || block.timestamp > registrationEndTime) {
            revert REGISTRATION_NOT_ACTIVE();
        }
    }

    /// @notice Checks if the allocation is active and reverts if not.
    /// @dev This will revert if the allocation has not started or if the allocation has ended.
    function _checkOnlyActiveAllocation() internal view {
        if (allocationStartTime > block.timestamp || block.timestamp > allocationEndTime) {
            revert ALLOCATION_NOT_ACTIVE();
        }
    }

    /// @notice Checks if the allocation has ended and reverts if not.
    /// @dev This will revert if the allocation has not ended.
    function _checkOnlyAfterAllocation() internal view {
        if (block.timestamp < allocationEndTime) {
            revert ALLOCATION_NOT_ENDED();
        }
    }

    /// @notice Checks if address is eligible allocator.
    /// @return Always returns true for this strategy
    function _isValidAllocator(address) internal pure override returns (bool) {
        return true;
    }

    /// @notice Checks if the timestamps are valid.
    /// @dev This will revert if any of the timestamps are invalid. This is determined by the strategy
    /// and may vary from strategy to strategy. Checks if '_registrationStartTime' is less than the
    /// current 'block.timestamp' or if '_registrationStartTime' is greater than the '_registrationEndTime'
    /// or if '_registrationStartTime' is greater than the '_allocationStartTime' or if '_registrationEndTime'
    /// is greater than the '_allocationEndTime' or if '_allocationStartTime' is greater than the '_allocationEndTime'.
    /// If any of these conditions are true, this will revert.
    /// @param _registrationStartTime The start time for the registration
    /// @param _registrationEndTime The end time for the registration
    /// @param _allocationStartTime The start time for the allocation
    /// @param _allocationEndTime The end time for the allocation
    function _isPoolTimestampValid(
        uint64 _registrationStartTime,
        uint64 _registrationEndTime,
        uint64 _allocationStartTime,
        uint64 _allocationEndTime
    ) internal view {
        if (
            block.timestamp > _registrationStartTime || _registrationStartTime > _registrationEndTime
                || _registrationStartTime > _allocationStartTime || _allocationStartTime > _allocationEndTime
                || _registrationEndTime > _allocationEndTime
        ) {
            revert INVALID();
        }
    }

    /// @notice Checks whether a pool is active or not.
    /// @dev This will return true if the current 'block timestamp' is greater than or equal to the
    /// 'registrationStartTime' and less than or equal to the 'registrationEndTime'.
    /// @return 'true' if pool is active, otherwise 'false'
    function _isPoolActive() internal view override returns (bool) {
        if (registrationStartTime <= block.timestamp && block.timestamp <= registrationEndTime) {
            return true;
        }
        return false;
    }

    /// @notice Submit recipient to pool and set their status.
    /// @param _data The data to be decoded.
    /// @custom:data if 'useRegistryAnchor' is 'true' (address recipientId, address recipientAddress, Metadata metadata)
    /// @custom:data if 'useRegistryAnchor' is 'false' (address recipientAddress, address registryAnchor, Metadata metadata)
    /// @param _sender The sender of the transaction
    /// @return recipientId The ID of the recipient
    function _registerRecipient(bytes memory _data, address _sender)
        internal
        override
        onlyActiveRegistration
        returns (address recipientId)
    {
        bool isUsingRegistryAnchor;
        address recipientAddress;
        address registryAnchor;
        Metadata memory metadata;

        // decode data custom to this strategy
        if (useRegistryAnchor) {
            (recipientId, recipientAddress, metadata) = abi.decode(_data, (address, address, Metadata));

            // If the sender is not a profile member this will revert
            if (!_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        } else {
            (recipientAddress, registryAnchor, metadata) = abi.decode(_data, (address, address, Metadata));

            // Set this to 'true' if the registry anchor is not the zero address
            isUsingRegistryAnchor = registryAnchor != address(0);

            // If using the 'registryAnchor' we set the 'recipientId' to the 'registryAnchor', otherwise we set it to the 'msg.sender'
            recipientId = isUsingRegistryAnchor ? registryAnchor : _sender;

            // Checks if the '_sender' is a member of the profile 'anchor' being used and reverts if not
            if (isUsingRegistryAnchor && !_isProfileMember(recipientId, _sender)) {
                revert UNAUTHORIZED();
            }
        }

        // If the metadata is required and the metadata is invalid this will revert
        if (metadataRequired && (bytes(metadata.pointer).length == 0 || metadata.protocol == 0)) {
            revert INVALID_METADATA();
        }

        // If the recipient address is the zero address this will revert
        if (recipientAddress == address(0)) {
            revert RECIPIENT_ERROR(recipientId);
        }

        // Get the recipient
        Recipient storage recipient = _recipients[recipientId];

        // update the recipients data
        recipient.recipientAddress = recipientAddress;
        recipient.metadata = metadata;
        recipient.useRegistryAnchor = useRegistryAnchor ? true : isUsingRegistryAnchor;

        uint8 currentStatus = _getUintRecipientStatus(recipientId);

        if (currentStatus == uint8(Status.None)) {
            // recipient registering new application
            recipientToStatusIndexes[recipientId] = recipientsCounter;
            _setRecipientStatus(recipientId, uint8(Status.Pending));

            bytes memory extendedData = abi.encode(_data, recipientsCounter);
            emit Registered(recipientId, extendedData, _sender);

            recipientsCounter++;
        } else {
            if (currentStatus == uint8(Status.Accepted)) {
                // recipient updating accepted application
                _setRecipientStatus(recipientId, uint8(Status.Pending));
            } else if (currentStatus == uint8(Status.Rejected)) {
                // recipient updating rejected application
                _setRecipientStatus(recipientId, uint8(Status.Appealed));
            }
            emit UpdatedRegistration(recipientId, _data, _sender, _getUintRecipientStatus(recipientId));
        }
    }

    /// @notice Distribute funds to recipients.
    /// @dev 'distributionStarted' will be set to 'true' when called. Only the pool manager can call.
    ///      Emits a 'BatchPayoutSuccessful()' event.
    /// @param _data The data to be decoded
    /// @custom:data '(Distribution[] distributions)'
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        if (!distributionStarted) {
            distributionStarted = true;
        }

        // Decode the '_data' to get the distributions
        Distribution[] memory distributions = abi.decode(_data, (Distribution[]));
        uint256 length = distributions.length;

        // Loop through the distributions and distribute the funds
        for (uint256 i; i < length;) {
            _distributeSingle(distributions[i]);
            unchecked {
                i++;
            }
        }

        // Emit that the batch payout was successful
        emit BatchPayoutSuccessful(_sender);
    }

    /// @notice Allocate tokens to recipient.
    /// @dev This can only be called during the allocation period. Emits an 'Allocated()' event.
    /// @param _data The data to be decoded
    /// @custom:data (address recipientId, uint256 amount, address token)
    /// @param _sender The sender of the transaction
    function _allocate(bytes memory _data, address _sender) internal virtual override onlyActiveAllocation {
        // Decode the '_data' to get the recipientId, amount and token
        (address recipientId, uint256 amount, address token) = abi.decode(_data, (address, uint256, address));

        // If the recipient status is not 'Accepted' this will revert, the recipient must be accepted through registration
        if (Status(_getUintRecipientStatus(recipientId)) != Status.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        // The token must be in the allowed token list and not be native token or zero address
        if (!allowedTokens[token] && !allowedTokens[address(0)]) {
            revert INVALID();
        }

        // If the token is native, the amount must be equal to the value sent, otherwise it reverts
        if (msg.value > 0 && token != NATIVE || token == NATIVE && msg.value != amount) {
            revert INVALID();
        }

        // Emit that the amount has been allocated to the recipient by the sender
        emit Allocated(recipientId, amount, token, _sender);
    }

    /// @notice Check if sender is profile owner or member.
    /// @param _anchor Anchor of the profile
    /// @param _sender The sender of the transaction
    /// @return 'true' if the '_sender' is a profile member, otherwise 'false'
    function _isProfileMember(address _anchor, address _sender) internal view virtual returns (bool) {
        IRegistry.Profile memory profile = _registry.getProfileByAnchor(_anchor);
        return _registry.isOwnerOrMemberOfProfile(profile.id, _sender);
    }

    /// @notice Get the recipient details.
    /// @param _recipientId Id of the recipient
    /// @return Recipient details
    function _getRecipient(address _recipientId) internal view returns (Recipient memory) {
        return _recipients[_recipientId];
    }

    /// @notice Returns the payout summary for the accepted recipient.
    /// @param _data The data to be decoded
    /// @custom:data '(Distribution)'
    /// @return 'PayoutSummary' for a recipient
    function _getPayout(address, bytes memory _data) internal view override returns (PayoutSummary memory) {
        // Decode the '_data' to get the distribution
        Distribution memory distribution = abi.decode(_data, (Distribution));

        uint256 index = distribution.index;
        address recipientId = distribution.recipientId;
        uint256 amount = distribution.amount;
        bytes32[] memory merkleProof = distribution.merkleProof;

        address recipientAddress = _getRecipient(recipientId).recipientAddress;

        // Validate the distribution
        if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
            // Return a 'PayoutSummary' with the 'recipientAddress' and 'amount'
            return PayoutSummary(recipientAddress, amount);
        }

        // If the distribution is not valid, return a payout summary with the amount set to zero
        return PayoutSummary(recipientAddress, 0);
    }

    /// @notice Validate the distribution for the payout.
    /// @param _index index of the distribution
    /// @param _recipientId Id of the recipient
    /// @param _recipientAddress Address of the recipient
    /// @param _amount Amount of tokens to be distributed
    /// @param _merkleProof Merkle proof of the distribution
    /// @return 'true' if the distribution is valid, otherwise 'false'
    function _validateDistribution(
        uint256 _index,
        address _recipientId,
        address _recipientAddress,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) internal view returns (bool) {
        // If the '_index' has been distributed this will return 'false'
        if (_hasBeenDistributed(_index)) {
            return false;
        }

        // Generate the node that will be verified in the 'merkleRoot'
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(_index, _recipientId, _recipientAddress, _amount))));

        // If the node is not verified in the 'merkleRoot' this will return 'false'
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            return false;
        }

        // Return 'true', the distribution is valid at this point
        return true;
    }

    /// @notice Check if the distribution has been distributed.
    /// @param _index index of the distribution
    /// @return 'true' if the distribution has been distributed, otherwise 'false'
    function _hasBeenDistributed(uint256 _index) internal view returns (bool) {
        // Get the word index by dividing the '_index' by 256
        uint256 distributedWordIndex = _index / 256;

        // Get the bit index by getting the remainder of the '_index' divided by 256
        uint256 distributedBitIndex = _index % 256;

        // Get the word from the '_distributedBitMap' using the 'distributedWordIndex'
        uint256 distributedWord = _distributedBitMap[distributedWordIndex];

        // Get the mask by shifting 1 to the left of the 'distributedBitIndex'
        uint256 mask = (1 << distributedBitIndex);

        // Return 'true' if the 'distributedWord' and 'mask' are equal to the 'mask'
        return distributedWord & mask == mask;
    }

    /// @notice Mark distribution as done.
    /// @param _index index of the distribution
    function _setDistributed(uint256 _index) internal {
        // Get the word index by dividing the '_index' by 256
        uint256 distributedWordIndex = _index / 256;

        // Get the bit index by getting the remainder of the '_index' divided by 256
        uint256 distributedBitIndex = _index % 256;

        // Set the bit in the '_distributedBitMap' shifting 1 to the left of the 'distributedBitIndex'
        _distributedBitMap[distributedWordIndex] |= (1 << distributedBitIndex);
    }

    /// @notice Distribute funds to recipient.
    /// @dev Emits a 'FundsDistributed()' event
    /// @param _distribution Distribution to be distributed
    function _distributeSingle(Distribution memory _distribution) internal virtual {
        uint256 index = _distribution.index;
        address recipientId = _distribution.recipientId;
        uint256 amount = _distribution.amount;
        bytes32[] memory merkleProof = _distribution.merkleProof;

        address recipientAddress = _recipients[recipientId].recipientAddress;

        // Validate the distribution and transfer the funds to the recipient, otherwise revert if not valid
        if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            // Set the distribution as distributed
            _setDistributed(index);

            // Update the pool amount
            poolAmount -= amount;

            // Transfer the amount to the recipient
            _transferAmount(pool.token, payable(recipientAddress), amount);

            // Emit that the funds have been distributed to the recipient
            emit FundsDistributed(amount, recipientAddress, pool.token, recipientId);
        } else {
            revert RECIPIENT_ERROR(recipientId);
        }
    }

    /// @notice Set the recipient status.
    /// @param _recipientId ID of the recipient
    /// @param _status Status of the recipient
    function _setRecipientStatus(address _recipientId, uint256 _status) internal {
        // Get the row index, column index and current row
        (uint256 rowIndex, uint256 colIndex, uint256 currentRow) = _getStatusRowColumn(_recipientId);

        // Calculate the 'newRow'
        uint256 newRow = currentRow & ~(15 << colIndex);

        // Add the status to the mapping
        statusesBitMap[rowIndex] = newRow | (_status << colIndex);
    }

    /// @notice Get recipient status
    /// @param _recipientId ID of the recipient
    /// @return status The status of the recipient
    function _getUintRecipientStatus(address _recipientId) internal view returns (uint8 status) {
        // Get the column index and current row
        (, uint256 colIndex, uint256 currentRow) = _getStatusRowColumn(_recipientId);

        // Get the status from the 'currentRow' shifting by the 'colIndex'
        status = uint8((currentRow >> colIndex) & 15);

        // Return the status
        return status;
    }

    /// @notice Get recipient status 'rowIndex', 'colIndex' and 'currentRow'.
    /// @param _recipientId ID of the recipient
    /// @return (rowIndex, colIndex, currentRow)
    function _getStatusRowColumn(address _recipientId) internal view returns (uint256, uint256, uint256) {
        uint256 recipientIndex = recipientToStatusIndexes[_recipientId];

        uint256 rowIndex = recipientIndex / 64; // 256 / 4
        uint256 colIndex = (recipientIndex % 64) * 4;

        return (rowIndex, colIndex, statusesBitMap[rowIndex]);
    }

    /// @notice Contract should be able to receive ETH
    receive() external payable {}

    /// ===================================
    /// ============== Hooks ==============
    /// ===================================

    /// @notice Hook called before initializing the strategy.
    /// @param _poolId The 'poolId' to initialize
    /// @param _initializeData The data to be decoded to initialize the strategy
    function _beforeInitialize(uint256 _poolId, InitializeData memory _initializeData) internal virtual {}

    /// @notice Hook called after initializing the strategy.
    /// @param _poolId The 'poolId' to initialize
    /// @param _initializeData The data to be decoded to initialize the strategy
    function _afterInitialize(uint256 _poolId, InitializeData memory _initializeData) internal virtual {}
}

// 

interface AddressDriver {
    type StreamConfig is uint256;

    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event NewAdminProposed(address indexed currentAdmin, address indexed newAdmin);
    event Paused(address indexed pauser);
    event PauserGranted(address indexed pauser, address indexed admin);
    event PauserRevoked(address indexed pauser, address indexed admin);
    event Unpaused(address indexed pauser);
    event Upgraded(address indexed implementation);

    struct AccountMetadata {
        bytes32 key;
        bytes value;
    }

    struct SplitsReceiver {
        uint256 accountId;
        uint32 weight;
    }

    struct StreamReceiver {
        uint256 accountId;
        StreamConfig config;
    }

    function acceptAdmin() external;
    function admin() external view returns (address);
    function allPausers() external view returns (address[] memory pausersList);
    function calcAccountId(address addr) external view returns (uint256 accountId);
    function collect(address erc20, address transferTo) external returns (uint128 amt);
    function drips() external view returns (address);
    function driverId() external view returns (uint32);
    function emitAccountMetadata(AccountMetadata[] memory accountMetadata) external;
    function give(uint256 receiver, address erc20, uint128 amt) external;
    function grantPauser(address pauser) external;
    function implementation() external view returns (address);
    function isPaused() external view returns (bool);
    function isPauser(address pauser) external view returns (bool isAddrPauser);
    function isTrustedForwarder(address forwarder) external view returns (bool);
    function pause() external;
    function proposeNewAdmin(address newAdmin) external;
    function proposedAdmin() external view returns (address);
    function proxiableUUID() external view returns (bytes32);
    function renounceAdmin() external;
    function revokePauser(address pauser) external;
    function setSplits(SplitsReceiver[] memory receivers) external;
    function setStreams(
        address erc20,
        StreamReceiver[] memory currReceivers,
        int128 balanceDelta,
        StreamReceiver[] memory newReceivers,
        uint32 maxEndHint1,
        uint32 maxEndHint2,
        address transferTo
    ) external returns (int128 realBalanceDelta);
    function unpause() external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

interface Caller {
    event Authorized(address indexed sender, address indexed authorized);
    event CalledAs(address indexed sender, address indexed authorized);
    event CalledSigned(address indexed sender, uint256 nonce);
    event EIP712DomainChanged();
    event NonceSet(address indexed sender, uint256 newNonce);
    event Unauthorized(address indexed sender, address indexed unauthorized);
    event UnauthorizedAll(address indexed sender);

    struct Call {
        address target;
        bytes data;
        uint256 value;
    }

    function MAX_NONCE_INCREASE() external view returns (uint256);
    function allAuthorized(address sender) external view returns (address[] memory authorized);
    function authorize(address user) external;
    function callAs(address sender, address target, bytes memory data)
        external
        payable
        returns (bytes memory returnData);
    function callBatched(Call[] memory calls) external payable returns (bytes[] memory returnData);
    function callSigned(address sender, address target, bytes memory data, uint256 deadline, bytes32 r, bytes32 sv)
        external
        payable
        returns (bytes memory returnData);
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
    function isAuthorized(address sender, address user) external view returns (bool authorized);
    function isTrustedForwarder(address forwarder) external view returns (bool);
    function nonce(address sender) external view returns (uint256);
    function setNonce(uint256 newNonce) external;
    function unauthorize(address user) external;
    function unauthorizeAll() external;
}
// 

interface Drips {
    event AccountMetadataEmitted(uint256 indexed accountId, bytes32 indexed key, bytes value);
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event Collectable(uint256 indexed accountId, address indexed erc20, uint128 amt);
    event Collected(uint256 indexed accountId, address indexed erc20, uint128 collected);
    event DriverAddressUpdated(uint32 indexed driverId, address indexed oldDriverAddr, address indexed newDriverAddr);
    event DriverRegistered(uint32 indexed driverId, address indexed driverAddr);
    event Given(uint256 indexed accountId, uint256 indexed receiver, address indexed erc20, uint128 amt);
    event NewAdminProposed(address indexed currentAdmin, address indexed newAdmin);
    event Paused(address indexed pauser);
    event PauserGranted(address indexed pauser, address indexed admin);
    event PauserRevoked(address indexed pauser, address indexed admin);
    event ReceivedStreams(uint256 indexed accountId, address indexed erc20, uint128 amt, uint32 receivableCycles);
    event Split(uint256 indexed accountId, uint256 indexed receiver, address indexed erc20, uint128 amt);
    event SplitsReceiverSeen(bytes32 indexed receiversHash, uint256 indexed accountId, uint32 weight);
    event SplitsSet(uint256 indexed accountId, bytes32 indexed receiversHash);
    event SqueezedStreams(
        uint256 indexed accountId,
        address indexed erc20,
        uint256 indexed senderId,
        uint128 amt,
        bytes32[] streamsHistoryHashes
    );
    event StreamReceiverSeen(bytes32 indexed receiversHash, uint256 indexed accountId, uint256 config);
    event StreamsSet(
        uint256 indexed accountId,
        address indexed erc20,
        bytes32 indexed receiversHash,
        bytes32 streamsHistoryHash,
        uint128 balance,
        uint32 maxEnd
    );
    event Unpaused(address indexed pauser);
    event Upgraded(address indexed implementation);
    event Withdrawn(address indexed erc20, address indexed receiver, uint256 amt);

    struct AccountMetadata {
        bytes32 key;
        bytes value;
    }

    struct SplitsReceiver {
        uint256 accountId;
        uint32 weight;
    }

    struct StreamReceiver {
        uint256 accountId;
        uint256 config;
    }

    struct StreamsHistory {
        bytes32 streamsHash;
        StreamReceiver[] receivers;
        uint32 updateTime;
        uint32 maxEnd;
    }

    function AMT_PER_SEC_EXTRA_DECIMALS() external view returns (uint8);
    function AMT_PER_SEC_MULTIPLIER() external view returns (uint160);
    function DRIVER_ID_OFFSET() external view returns (uint8);
    function MAX_SPLITS_RECEIVERS() external view returns (uint256);
    function MAX_STREAMS_RECEIVERS() external view returns (uint256);
    function MAX_TOTAL_BALANCE() external view returns (uint128);
    function TOTAL_SPLITS_WEIGHT() external view returns (uint32);
    function acceptAdmin() external;
    function admin() external view returns (address);
    function allPausers() external view returns (address[] memory pausersList);
    function balanceAt(uint256 accountId, address erc20, StreamReceiver[] memory currReceivers, uint32 timestamp)
        external
        view
        returns (uint128 balance);
    function balances(address erc20) external view returns (uint128 streamsBalance, uint128 splitsBalance);
    function collect(uint256 accountId, address erc20) external returns (uint128 amt);
    function collectable(uint256 accountId, address erc20) external view returns (uint128 amt);
    function cycleSecs() external view returns (uint32);
    function driverAddress(uint32 driverId) external view returns (address driverAddr);
    function emitAccountMetadata(uint256 accountId, AccountMetadata[] memory accountMetadata) external;
    function give(uint256 accountId, uint256 receiver, address erc20, uint128 amt) external;
    function grantPauser(address pauser) external;
    function hashSplits(SplitsReceiver[] memory receivers) external pure returns (bytes32 receiversHash);
    function hashStreams(StreamReceiver[] memory receivers) external pure returns (bytes32 streamsHash);
    function hashStreamsHistory(bytes32 oldStreamsHistoryHash, bytes32 streamsHash, uint32 updateTime, uint32 maxEnd)
        external
        pure
        returns (bytes32 streamsHistoryHash);
    function implementation() external view returns (address);
    function isPaused() external view returns (bool);
    function isPauser(address pauser) external view returns (bool isAddrPauser);
    function minAmtPerSec() external view returns (uint160);
    function nextDriverId() external view returns (uint32 driverId);
    function pause() external;
    function proposeNewAdmin(address newAdmin) external;
    function proposedAdmin() external view returns (address);
    function proxiableUUID() external view returns (bytes32);
    function receivableStreamsCycles(uint256 accountId, address erc20) external view returns (uint32 cycles);
    function receiveStreams(uint256 accountId, address erc20, uint32 maxCycles)
        external
        returns (uint128 receivedAmt);
    function receiveStreamsResult(uint256 accountId, address erc20, uint32 maxCycles)
        external
        view
        returns (uint128 receivableAmt);
    function registerDriver(address driverAddr) external returns (uint32 driverId);
    function renounceAdmin() external;
    function revokePauser(address pauser) external;
    function setSplits(uint256 accountId, SplitsReceiver[] memory receivers) external;
    function setStreams(
        uint256 accountId,
        address erc20,
        StreamReceiver[] memory currReceivers,
        int128 balanceDelta,
        StreamReceiver[] memory newReceivers,
        uint32 maxEndHint1,
        uint32 maxEndHint2
    ) external returns (int128 realBalanceDelta);
    function split(uint256 accountId, address erc20, SplitsReceiver[] memory currReceivers)
        external
        returns (uint128 collectableAmt, uint128 splitAmt);
    function splitResult(uint256 accountId, SplitsReceiver[] memory currReceivers, uint128 amount)
        external
        view
        returns (uint128 collectableAmt, uint128 splitAmt);
    function splitsHash(uint256 accountId) external view returns (bytes32 currSplitsHash);
    function splittable(uint256 accountId, address erc20) external view returns (uint128 amt);
    function squeezeStreams(
        uint256 accountId,
        address erc20,
        uint256 senderId,
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory
    ) external returns (uint128 amt);
    function squeezeStreamsResult(
        uint256 accountId,
        address erc20,
        uint256 senderId,
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory
    ) external view returns (uint128 amt);
    function streamsState(uint256 accountId, address erc20)
        external
        view
        returns (bytes32 streamsHash, bytes32 streamsHistoryHash, uint32 updateTime, uint128 balance, uint32 maxEnd);
    function unpause() external;
    function updateDriverAddress(uint32 driverId, address newDriverAddr) external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    function withdraw(address erc20, address receiver, uint256 amt) external;
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// 

/// @notice Describes a streams configuration.
/// It's a 256-bit integer constructed by concatenating the configuration parameters:
/// `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`.
/// `streamId` is an arbitrary number used to identify a stream.
/// It's a part of the configuration but the protocol doesn't use it.
/// `amtPerSec` is the amount per second being streamed. Must never be zero.
/// It must have additional `Streams._AMT_PER_SEC_EXTRA_DECIMALS` decimals and can have fractions.
/// To achieve that its value must be multiplied by `Streams._AMT_PER_SEC_MULTIPLIER`.
/// `start` is the timestamp when streaming should start.
/// If zero, use the timestamp when the stream is configured.
/// `duration` is the duration of streaming.
/// If zero, stream until balance runs out.
type StreamConfig is uint256;

using StreamConfigImpl for AddressDriver.StreamConfig;

library StreamConfigImpl {
    /// @notice Create a new StreamConfig.
    /// @param streamId_ An arbitrary number used to identify a stream.
    /// It's a part of the configuration but the protocol doesn't use it.
    /// @param amtPerSec_ The amount per second being streamed. Must never be zero.
    /// It must have additional `Streams._AMT_PER_SEC_EXTRA_DECIMALS`
    /// decimals and can have fractions.
    /// To achieve that the passed value must be multiplied by `Streams._AMT_PER_SEC_MULTIPLIER`.
    /// @param start_ The timestamp when streaming should start.
    /// If zero, use the timestamp when the stream is configured.
    /// @param duration_ The duration of streaming. If zero, stream until the balance runs out.
    function create(uint32 streamId_, uint160 amtPerSec_, uint32 start_, uint32 duration_)
        internal
        pure
        returns (AddressDriver.StreamConfig)
    {
        // By assignment we get `config` value:
        // `zeros (224 bits) | streamId (32 bits)`
        uint256 config = streamId_;
        // By bit shifting we get `config` value:
        // `zeros (64 bits) | streamId (32 bits) | zeros (160 bits)`
        // By bit masking we get `config` value:
        // `zeros (64 bits) | streamId (32 bits) | amtPerSec (160 bits)`
        config = (config << 160) | amtPerSec_;
        // By bit shifting we get `config` value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | start (32 bits)`
        config = (config << 32) | start_;
        // By bit shifting we get `config` value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | zeros (32 bits)`
        // By bit masking we get `config` value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        config = (config << 32) | duration_;
        return AddressDriver.StreamConfig.wrap(config);
    }

    /// @notice Extracts streamId from a `StreamConfig`
    function streamId(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (224 bits) | streamId (32 bits)`
        // By casting down we get value:
        // `streamId (32 bits)`
        return uint32(StreamConfig.unwrap(config) >> 224);
    }

    /// @notice Extracts amtPerSec from a `StreamConfig`
    function amtPerSec(StreamConfig config) internal pure returns (uint160) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (64 bits) | streamId (32 bits) | amtPerSec (160 bits)`
        // By casting down we get value:
        // `amtPerSec (160 bits)`
        return uint160(StreamConfig.unwrap(config) >> 64);
    }

    /// @notice Extracts start from a `StreamConfig`
    function start(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By bit shifting we get value:
        // `zeros (32 bits) | streamId (32 bits) | amtPerSec (160 bits) | start (32 bits)`
        // By casting down we get value:
        // `start (32 bits)`
        return uint32(StreamConfig.unwrap(config) >> 32);
    }

    /// @notice Extracts duration from a `StreamConfig`
    function duration(StreamConfig config) internal pure returns (uint32) {
        // `config` has value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // By casting down we get value:
        // `duration (32 bits)`
        return uint32(StreamConfig.unwrap(config));
    }

    /// @notice Compares two `StreamConfig`s.
    /// First compares `streamId`s, then `amtPerSec`s, then `start`s and finally `duration`s.
    /// @return isLower True if `config` is strictly lower than `otherConfig`.
    function lt(StreamConfig config, StreamConfig otherConfig) internal pure returns (bool isLower) {
        // Both configs have value:
        // `streamId (32 bits) | amtPerSec (160 bits) | start (32 bits) | duration (32 bits)`
        // Comparing them as integers is equivalent to comparing their fields from left to right.
        return StreamConfig.unwrap(config) < StreamConfig.unwrap(otherConfig);
    }
}

contract DonationVotingMerkleDistributionDrip is DonationVotingMerkleDistributionBaseStrategy {
    /// ================================
    /// ========== Struct ==============
    /// ================================

    /// @notice Stores the details of the allocation
    struct Allocation {
        address recipientId;
        uint256 amount;
        address token;
    }

    /// @notice Stores the details of the distribution when it's a stream.
    struct StreamDistribution {
        uint256 index;
        address recipientId;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /// ===============================
    /// ========== Events =============
    /// ===============================

    /// @notice Emitted when a batch allocation is successful
    /// @param sender The sender of the transaction
    event BatchAllocationSuccessful(address indexed sender);

    /// @notice Emitted when a batch stream distribution is successful
    /// @param sender The sender of the transaction
    event BatchSetStreamSuccessful(address indexed sender, int128 realBalanceDelta);

    /// ================================
    /// ========== Storage =============
    /// ================================
    IERC20 public erc20;

    Drips public drips;
    Caller public caller;
    AddressDriver public driver;

    /// @notice Flag to indicate whether token streaming is required or not.
    bool public stream;

    /// ===============================
    /// ======== Constructor ==========
    /// ===============================

    /// @notice Constructor for the Donation Voting Merkle Distribution Strategy
    /// @param _allo The 'Allo' contract
    /// @param _name The name of the strategy
    constructor(address _allo, string memory _name) DonationVotingMerkleDistributionBaseStrategy(_allo, _name) {}

    /// ===============================
    /// ========= Initialize ==========
    /// ===============================

    /// @notice Hook called before initializing the strategy.
    /// @param _poolId The 'poolId' to initialize
    /// @param _initializeData The data to be decoded to initialize the strategy
    function _beforeInitialize(uint256 _poolId, InitializeData memory _initializeData) internal override {
        IAllo.Pool memory pool = allo.getPool(_poolId);

        if (pool.token == NATIVE && _initializeData.stream) {
            revert INVALID();
        }

        drips = Drips(_initializeData.drips);
        caller = Caller(_initializeData.dripsCaller);
        driver = AddressDriver(_initializeData.dripsAddressDriver);
        stream = _initializeData.stream;

        if (pool.token != NATIVE) {
            erc20 = IERC20(pool.token);
            erc20.approve(address(driver), type(uint256).max);
        }
    }

    /// ====================================
    /// ============ Internal ==============
    /// ====================================

    /// @notice Allocate tokens to recipients, the Allocation[] max is usually 100.
    /// @dev This can only be called during the allocation period. Emits an 'BatchAllocationSuccessful()' event.
    /// @param _data The data to be decoded
    /// @custom:data '(Allocations[] allocations)'
    // /// @param _sender The sender of the transaction
    function _allocate(bytes memory _data, address _sender) internal virtual override onlyActiveAllocation {
        // Decode the '_data' to get the allocations
        Allocation[] memory allocations = abi.decode(_data, (Allocation[]));
        uint256 length = allocations.length;

        // Loop through the allocations and allocate the funds
        for (uint8 i = 0; i < length; i++) {
            _allocateSingle(allocations[i], _sender);
        }

        // Emit batch allocation successful
        emit BatchAllocationSuccessful(_sender);
    }

    /// @notice Allocate funds to recipient.
    /// @dev Emits a 'FundsDistributed()' event
    /// @param _allocation Distribution to be distributed
    /// @param _sender The sender of the transaction
    function _allocateSingle(Allocation memory _allocation, address _sender) internal {
        address recipientId = _allocation.recipientId;
        uint256 amount = _allocation.amount;
        address token = _allocation.token;

        // If the recipient status is not 'Accepted' this will revert, the recipient must be accepted through registration
        if (Status(_getUintRecipientStatus(recipientId)) != Status.Accepted) {
            revert RECIPIENT_ERROR(recipientId);
        }

        //TODO: remove this once we can guarantee the safety of bulk native transfers
        // If the token is native reject,
        if (token == NATIVE) {
            revert INVALID();
        }

        // The token must be in the allowed token list and not be native token or zero address
        if (!allowedTokens[token] && !allowedTokens[address(0)]) {
            revert INVALID();
        }

        // If the token is native, the amount must be equal to the value sent, otherwise it reverts
        if (msg.value > 0 && token != NATIVE || token == NATIVE && msg.value != amount) {
            revert INVALID();
        }

        // Transfer the amount to recipient
        if (
            _transferAmountFrom(
                token, TransferData({from: _sender, to: _recipients[recipientId].recipientAddress, amount: amount})
            )
        ) {
            // revert INVALID();

            // Emit that the amount has been allocated to the recipient by the sender
            emit Allocated(recipientId, amount, token, _sender);
        }
    }

    /// @notice Distribute funds to recipients, the Distribution[] max is usually 100.
    /// @dev 'distributionStarted' will be set to 'true' when called. Only the pool manager can call.
    ///      Emits a 'BatchPayoutSuccessful()' event.
    /// @param _data The data to be decoded
    ///  @custom:data if 'stream' is 'true' (AddressDriver.StreamReceiver[] prevStreamReceivers,
    ///                StreamDistribution[] streamDistributions, int128 amt, uint32 duration, uint32 hint1, uint32 hint2)
    ///  @custom:data if 'stream' is 'false'(Distribution[] distributions)
    /// @param _sender The sender of the transaction
    function _distribute(address[] memory, bytes memory _data, address _sender)
        internal
        virtual
        override
        onlyPoolManager(_sender)
    {
        if (!distributionStarted) {
            distributionStarted = true;
        }

        if (stream) {
            AddressDriver.StreamReceiver[] memory prevStreamReceivers;
            StreamDistribution[] memory streamDistributions;
            int128 amt;
            uint32 duration;
            uint32 hint1;
            uint32 hint2;

            // Decode the '_data' to get the streamDistributions
            (prevStreamReceivers, streamDistributions, amt, duration, hint1, hint2) = abi.decode(
                _data, (AddressDriver.StreamReceiver[], StreamDistribution[], int128, uint32, uint32, uint32)
            );

            AddressDriver.StreamReceiver[] memory currentStreamReceivers =
                _buildStreamReceiver(streamDistributions, duration);

            int128 realBalanceDelta = driver.setStreams(
                address(erc20), prevStreamReceivers, amt, currentStreamReceivers, hint1, hint2, address(this)
            );

            // Emit that the batch payout was successful
            emit BatchSetStreamSuccessful(_sender, realBalanceDelta);
        } else {
            // Decode the '_data' to get the distributions
            Distribution[] memory distributions = abi.decode(_data, (Distribution[]));
            uint256 length = distributions.length;

            // Loop through the distributions and distribute the funds
            for (uint256 i = 0; i < length; i++) {
                _distributeSingle(distributions[i]);
            }

            // Emit that the batch payout was successful
            emit BatchPayoutSuccessful(_sender);
        }
    }

    /// @notice Distribute funds to recipient.
    /// @dev Emits a 'FundsDistributed()' event
    /// @param _distribution Distribution to be distributed
    function _distributeSingle(Distribution memory _distribution) internal override {
        uint256 index = _distribution.index;
        address recipientId = _distribution.recipientId;
        uint256 amount = _distribution.amount;
        bytes32[] memory merkleProof = _distribution.merkleProof;

        address recipientAddress = _recipients[recipientId].recipientAddress;

        // Validate the distribution and transfer the funds to the recipient, otherwise revert if not valid
        if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
            IAllo.Pool memory pool = allo.getPool(poolId);

            // Set the distribution as distributed
            _setDistributed(index);

            // Update the pool amount
            poolAmount -= amount;

            // Transfer the amount to the recipient
            _transferAmount(pool.token, payable(recipientAddress), amount);

            // Emit that the funds have been distributed to the recipient
            emit FundsDistributed(amount, recipientAddress, pool.token, recipientId);
        } else {
            revert RECIPIENT_ERROR(recipientId);
        }
    }

    function _buildStreamReceiver(StreamDistribution[] memory _distributions, uint32 _duration)
        internal
        returns (AddressDriver.StreamReceiver[] memory)
    {
        uint256 length = _distributions.length;

        AddressDriver.StreamReceiver[] memory receivers = new AddressDriver.StreamReceiver[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 index = _distributions[i].index;
            address recipientId = _distributions[i].recipientId;
            uint256 amount = _distributions[i].amount;
            bytes32[] memory merkleProof = _distributions[i].merkleProof;

            address recipientAddress = _recipients[recipientId].recipientAddress;

            if (_validateDistribution(index, recipientId, recipientAddress, amount, merkleProof)) {
                // Set the distribution as distributed
                _setDistributed(index);

                // Update the pool amount
                poolAmount -= amount;

                receivers[i].accountId = driver.calcAccountId(recipientAddress);
                // TODO: use merkleRoot for id instead of 0
                receivers[i].config =
                    StreamConfigImpl.create(0, calculateFlowRate(uint128(amount), _duration), 0, _duration);
            } else {
                revert RECIPIENT_ERROR(recipientId);
            }
        }

        return receivers;
    }

    /// @notice Calculate Precision Token Unit flow rate per second
    /// @dev This function calculates the precision token unit flow rate per second based on the tokens to send
    ///      and the streaming duration in seconds.
    /// @param tokensToSend_ The number of tokens to be sent
    /// @param duration_ The duration of the streaming in seconds
    /// @return The calculated precision token unit flow rate per second
    function calculateFlowRate(uint128 tokensToSend_, uint32 duration_) internal returns (uint160) {
        uint160 flowRate = tokensToSend_ * 10 ** 9 / duration_;
        if (flowRate < drips.minAmtPerSec()) {
            return drips.minAmtPerSec();
        }
        return flowRate;
    }
}
