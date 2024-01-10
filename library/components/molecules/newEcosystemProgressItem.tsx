import ProgressStep from "../atoms/Step";
import {
  Status,
  getLatestLoadingIndex,
  progressGap,
} from "../organisms/ProgressModal";

const NewEcosystemProgressItem = (prop: {
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
            return <>not</>;
          case 1:
            return <>this is loading now!</>;
          case 2:
            return <>not</>;
          case 3:
            return <>not</>;
          case 4:
            return <>not</>;
          default:
            return <>not</>;
        }
      })()}
    </div>
  );
};

export default NewEcosystemProgressItem;
