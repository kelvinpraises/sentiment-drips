import ProgressStep from "../atoms/Step";
import {
  Status,
  getLatestLoadingIndex,
  progressGap,
} from "../organisms/ProgressModal";

const StrategyProgressItem = (prop: {
  progressSteps: { name: string; status: Status }[];
}) => {
  return (
    <div className="w-full flex">
      <div className={"flex flex-col"} style={{ gap: `${progressGap}rem` }}>
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

      {(() => {
        const index = getLatestLoadingIndex(prop.progressSteps);
        switch (index) {
          case 0:
            return <></>;
          case 1:
            return <></>;
          case 2:
            return <></>;
          case 3:
            return <></>;
          case 4:
            return <></>;
          default:
            return <></>;
        }
      })()}
    </div>
  );
};

export default StrategyProgressItem;
