import TxHashes from "../atoms/TxHash";
import ProgressStep from "../atoms/Step";
import {
  Status,
  getLatestLoadingIndex,
  progressGap,
} from "../organisms/ProgressModal";

const NewEcosystemProgressItem = (prop: {
  progressSteps: { name: string; status: Status }[];
  txHashes: { [key: string]: string };
}) => {
  return (
    <div className="w-full flex gap-2 items-center">
      <div
        className={"flex flex-col min-w-fit"}
        style={{ gap: `${progressGap}rem` }}
      >
        {prop.progressSteps.map((step, index, items) => {
          return (
            <ProgressStep
              name={step.name}
              last={items.length === index + 1}
              index={index}
              status={step.status}
            />
          );
        })}
      </div>
      <div className="w-full flex items-center">
        {(() => {
          const index = getLatestLoadingIndex(prop.progressSteps);
          switch (index) {
            case 0:
              return <p>Deploying the governance voting token</p>;
            case 1:
              return <p>Setting up the governance, timeLock contract</p>;
            case 2:
              return <p>...</p>;
            case 3:
              return (
                <TxHashes
                  note="Ecosystem created successfully (re-routing to Ecosystem page in 5 secs)"
                  txHashes={prop.txHashes}
                />
              );
            default:
              return <>not</>;
          }
        })()}
      </div>
    </div>
  );
};

export default NewEcosystemProgressItem;
