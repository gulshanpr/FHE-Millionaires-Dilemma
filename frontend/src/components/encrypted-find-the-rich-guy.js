import { useChainBalance } from "@/provider/balance-provider";
import { ENCRYPTED_MILLIONARIES_DILEMMA_CONTRACT_ADDRESS } from "@/utils/contract";
import { CreditCard, Lock, RefreshCw, Unlock } from "lucide-react";
import { useState } from "react";
import { parseAbiItem } from "viem";
import { useAccount, usePublicClient, useWalletClient, useWriteContract } from "wagmi";

const EncryptedTokenInterface = () => {
  const [amount, setAmount] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const { address } = useAccount();
  const { writeContractAsync } = useWriteContract();
  const publicClient = usePublicClient();
  const walletClient = useWalletClient();

  const { fetchEncryptedBalance, encryptedBalance, isEncryptedLoading } = useChainBalance();

  const reEncrypt = async () => {
    try {
      await fetchEncryptedBalance({ wc: walletClient });
    } catch (error) {
      console.error("Error in reEncrypt function:", error);
      setError("Failed to refresh balance");
    }
  };

  const findTheGuy = async () => {
    try {
      startWinnerListener(); // <-- Start listening first

      const txHash = await writeContractAsync({
        address: ENCRYPTED_MILLIONARIES_DILEMMA_CONTRACT_ADDRESS,
        abi: [{ type: "function", name: "findWhoIsRich", inputs: [], outputs: [], stateMutability: "nonpayable" }],
        functionName: "findWhoIsRich",
      });

      const tx = await publicClient.waitForTransactionReceipt({ hash: txHash });
      if (tx.status !== "success") throw new Error("Transaction failed");

      console.log("✅ findWhoIsRich transaction confirmed");

      for (const log of logs) {
        console.log("Winner found:", log.args);
      }
    } catch (err) {
      console.error("Error finding the guy:", err);
      // throw new Error("Failed to find who is rich, sed");
    }
  };

  const handleFind = async () => {
    try {
      await findTheGuy();

      // Reset form
      setAmount("");
    } catch (err) {
      console.error("Error finding the guy:", err);
      // setError("Failed to find who is rich, sed");
    } finally {
      setIsLoading(false);
    }
  };

  const startWinnerListener = () => {
    const unwatch = publicClient.watchEvent({
      address: ENCRYPTED_MILLIONARIES_DILEMMA_CONTRACT_ADDRESS,
      event: parseAbiItem("event WhoIsTheMillionaire(address indexed winner, bool isTie, address[3] participants)"),
      onLogs: (logs) => {
        for (const log of logs) {
          const { winner, isTie, participants } = log.args;

          alert(`🏆 Winner: ${winner}\n🤝 Tie: ${isTie}\n🧑‍🤝‍🧑 Participants:\n${participants.join("\n")}`);

          console.log("Winner event data:", { winner, isTie, participants });

          unwatch();
        }
      },
    });

    return unwatch;
  };

  return (
    <div className="flex items-center justify-center w-full">
      <div className="w-full">
        <div className="w-full bg-gray-700/40 rounded-xl shadow-2xl border border-gray-700 overflow-hidden">
          <div className="p-6 space-y-4">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-white flex items-center">
                <CreditCard className="mr-3 text-blue-400" />
                Encrypted Balance
              </h2>
              <button
                onClick={reEncrypt}
                className="text-gray-400 hover:text-white transition-colors"
                disabled={isEncryptedLoading}
              >
                <RefreshCw className={`${isEncryptedLoading ? "animate-spin" : ""}`} />
              </button>
            </div>

            <div className="bg-gray-700 rounded-lg p-4">
              <div className="flex items-center justify-between">
                <span className="text-gray-300">Encrypted Balance</span>
                <div className="flex items-center">
                  {isEncryptedLoading ? (
                    <span className="text-gray-500 animate-pulse">Loading...</span>
                  ) : (
                    <span className="text-white font-semibold">{encryptedBalance || "0.00"} cUSDC</span>
                  )}
                  {encryptedBalance ? (
                    <Lock className="ml-2 text-blue-400 w-4 h-4" />
                  ) : (
                    <Unlock className="ml-2 text-red-400 w-4 h-4" />
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-4">
              {error && (
                <div className="bg-red-900/20 border border-red-500 text-red-400 p-3 rounded-lg text-center">
                  {error}
                </div>
              )}

              <button
                onClick={handleFind}
                className="w-full p-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? (
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                ) : (
                  "Find Who is Rich?"
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EncryptedTokenInterface;
