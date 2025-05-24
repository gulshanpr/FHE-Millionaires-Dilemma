"use client";

import { ENCRYPTED_MILLIONARIES_DILEMMA_CONTRACT_ADDRESS } from "@/utils/contract";
import { encryptValue } from "@/utils/inco-lite";
import { ArrowRight, Send } from "lucide-react";
import { useState } from "react";
import { parseEther } from "viem";
import { useAccount, usePublicClient, useWriteContract } from "wagmi";

const EncryptedSend = () => {
  const { address } = useAccount();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [amount, setAmount] = useState("");

  const { writeContractAsync } = useWriteContract();
  const publicClient = usePublicClient();

  const submitEncryptedBalances = async () => {
    setError("");

    if (!amount || isNaN(Number(amount))) {
      setError("Please enter a valid number");
      return;
    }

    try {
      setIsLoading(true);

      const parsedAmount = parseEther(amount);

      const encryptedData = await encryptValue({
        value: parsedAmount,
        address,
        contractAddress: ENCRYPTED_MILLIONARIES_DILEMMA_CONTRACT_ADDRESS,
      });

      console.log("Encrypted Data:", encryptedData);

      const hash = await writeContractAsync({
        address: ENCRYPTED_MILLIONARIES_DILEMMA_CONTRACT_ADDRESS,
        abi: [
          {
            type: "function",
            name: "submitBalance",
            inputs: [{ name: "valueInput", type: "bytes", internalType: "bytes" }],
            outputs: [],
            stateMutability: "nonpayable",
          },
        ],
        functionName: "submitBalance",
        args: [encryptedData],
      });

      const tx = await publicClient.waitForTransactionReceipt({ hash });

      if (tx.status !== "success") {
        throw new Error("Transaction failed");
      }

      alert("Transaction successful:", tx);
    } catch (err) {
      console.error("Transaction failed:", err);
      setError(err.message || "Transaction failed");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center w-full">
      <div className="w-full bg-gray-700/40 rounded-xl shadow-2xl border border-gray-700 overflow-hidden">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-white flex items-center">
              <Send className="mr-3 text-blue-400" />
              Submit Your Balance
            </h2>
          </div>

          <div className="space-y-5">
            {error && (
              <div className="bg-red-900/20 border border-red-500 text-red-400 p-3 rounded-lg text-center">{error}</div>
            )}

            <input
              type="number"
              inputMode="decimal"
              placeholder="Enter amount in cUSDC"
              className="w-full p-3 bg-gray-800 text-white rounded-lg border border-gray-600 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />

            <button
              onClick={submitEncryptedBalances}
              className="w-full p-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
              ) : (
                <div className="flex items-center">
                  Submit Balance <ArrowRight className="ml-2" />
                </div>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EncryptedSend;
