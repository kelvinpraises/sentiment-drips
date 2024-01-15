import { ellipsisAddress } from "@/library/utils";
import Button from "./Button";

const TxHashes = ({
  note,
  txHashes,
}: {
  note: string;
  txHashes: { [key: string]: string };
}) => {
  const openAllTxHashes = () => {
    Object.keys(txHashes).forEach((key) => {
      window.open(`https://sepolia.etherscan.io/tx/${txHashes[key]}`, "_blank");
    });
  };

  return (
    <div className="flex flex-col gap-4 max-h-60 overflow-auto">
      <p className="text-sm">{note}</p>
      <p className="font-bold">All Transactions Hash</p>
      <div className="flex flex-col gap-2">
        {Object.keys(txHashes).map((key) => {
          return (
            <div key={key} className="flex flex-col gap-2">
              <p className="text-sm font-bold">{key}</p>
              <a
                href={`https://sepolia.etherscan.io/tx/${txHashes[key]}`}
                target="_blank"
                rel="noreferrer"
                className="truncate rounded-md bg-stone-100 px-2 py-1 text-sm font-medium text-stone-600 transition-colors hover:bg-stone-200 dark:bg-stone-800 dark:text-stone-400 dark:hover:bg-stone-700"
              >
                {ellipsisAddress(txHashes[key], 12)} ↗
              </a>
            </div>
          );
        })}
      </div>
      <Button text={"Open all Hashes"} handleClick={openAllTxHashes} />
    </div>
  );
};

export default TxHashes;
