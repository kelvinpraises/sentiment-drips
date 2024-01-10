import { useStore } from "@/library/store/useStore";
import { cn } from "@/library/utils";
import * as Dialog from "@radix-ui/react-dialog";
import React from "react";

const progressItems = {
  newEcosystem: [
    "Deploying Token",
    "Prepping Governance",
    "Confirming State",
    "Ecosystem Created",
  ],
  strategy: [
    "Deploy Strategy",
    "Uploading Proposal",
    "Confirming State",
    "Proposal Created",
  ],
  vote: ["Voted", "Uploading Vote", "Confirming State", "Voted"],
  review: [
    "Review Project",
    "Uploading Review",
    "Confirming State",
    "Recipients Reviewed",
  ],
  allocate: [
    "Allocate Sentiment",
    "Uploading Allocation",
    "Confirming State",
    "Allocation Complete",
  ],
};

interface ModalProps {
  step: number;
  children: React.ReactNode;
}

type status = "none" | "loading" | "errored" | "passed";

const state = [
  { status: "passed" },
  { status: "loading" },
  { status: "none" },
  { status: "none" },
];

const ProgressModal: React.FC<ModalProps> = ({
  step,
  children,
}: ModalProps) => {
  const modalElementId = useStore((state) => state.modalElementId);

  return (
    <Dialog.Root>
      <Dialog.Trigger>{children}</Dialog.Trigger>

      <Dialog.Portal
        container={
          typeof window !== "undefined"
            ? document.getElementById(modalElementId)
            : null
        }
      >
        <Dialog.Overlay className="backdrop-blur-xl data-[state=open]:animate-overlayShow absolute inset-0" />
        <Dialog.Content className="data-[state=open]:animate-contentShow overflow-scroll absolute max-h-[80%] top-[50%] left-[50%] w-[90vw] max-w-[500px] translate-x-[-50%] translate-y-[-50%] rounded-xl bg-white p-[25px] shadow-[hsl(206_22%_7%_/_35%)_0px_10px_38px_-10px,_hsl(206_22%_7%_/_20%)_0px_10px_20px_-15px] focus:outline-none">
          {(() => {
            switch (step) {
              case 0:
                return (
                  <NewEcosystemProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.newEcosystem,
                      state
                    )}
                  />
                );
              case 1:
                return (
                  <StrategyProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.strategy,
                      state
                    )}
                  />
                );
              case 2:
                return (
                  <VoteProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.vote,
                      state
                    )}
                  />
                );
              case 3:
                return (
                  <ReviewProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.review,
                      state
                    )}
                  />
                );
              case 4:
                return (
                  <AllocateProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.allocate,
                      state
                    )}
                  />
                );
              default:
                return null;
            }
          })()}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
};

interface ProgressStepProp {
  index: number;
  name: string;
  status: status;
  last: boolean;
}

const progressGap = "2";
const progressStepGap = "after:h-[2rem]"; // progressGap

const ProgressStep = (prop: ProgressStepProp) => {
  return (
    <div className={cn("flex items-center min-h-fit gap-2")}>
      <div
        className={cn(
          "flex items-center justify-center relative h-8 w-8 rounded-full bg-white shadow-[0_0_0_2.5px] shadow-[#DEE6E5] outline-none",
          "after:absolute after:top-[100%] after:content-[''] after:w-1 after:bg-[#DEE6E5] after:left-[50%] after:translate-x-[-50%]",
          progressStepGap,
          // prop.status === "loading" && "shadow-[#313B3D]",
          prop.status === "errored" && "after:bg-[#FF5353]  shadow-[#FF5353]",
          prop.status === "passed" &&
            "after:bg-[#313B3D] bg-[#313B3D] shadow-[#313B3D]",
          prop.last && "after:w-0"
        )}
      >
        {(() => {
          switch (prop.status) {
            case "none":
              return prop.index + 1;
            case "loading":
              return <img className=" w-3/4 h-3/4" src={"/circles.svg"} />;
            case "errored":
              return <></>;
            case "passed":
              return <></>;
            default:
              return <></>;
          }
        })()}
      </div>
      <div>
        <p className="text-sm text-gray-600">{prop.name}</p>
      </div>
    </div>
  );
};

const NewEcosystemProgressItem = (prop: {
  progressSteps: { name: string; status: status }[];
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

const StrategyProgressItem = (prop: {
  progressSteps: { name: string; status: status }[];
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

const VoteProgressItem = (prop: {
  progressSteps: { name: string; status: status }[];
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

const ReviewProgressItem = (prop: {
  progressSteps: { name: string; status: status }[];
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

const AllocateProgressItem = (prop: {
  progressSteps: { name: string; status: status }[];
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

// A utility function to join the progress item and state arrays
const pairProgressWithState = (
  progressItem: string[],
  state: { status: string }[]
): { name: string; status: status }[] => {
  const combinedArray = progressItem.map((name: string, index: number) => {
    return { name, status: state[index].status as status };
  });
  return combinedArray;
};

export default ProgressModal;

// A utility to get the attest loading index
const getLatestLoadingIndex = (
  progressSteps: { name: string; status: status }[]
): number => {
  let latestIndex = -1;
  progressSteps.forEach((step, index) => {
    if (step.status === "loading") {
      latestIndex = index;
    }
  });
  return latestIndex;
};
