import * as Dialog from "@radix-ui/react-dialog";
import React from "react";

import { useStore } from "@/library/store/useStore";
import AllocateProgressItem from "../molecules/allocateProgressItem";
import NewEcosystemProgressItem from "../molecules/newEcosystemProgressItem";
import ReviewProgressItem from "../molecules/reviewProgressItem";
import StrategyProgressItem from "../molecules/strategyProgressItem";
import VoteProgressItem from "../molecules/voteProgressItem";

interface ModalProps {
  step: number;
  children: React.ReactNode;
}

export type Status = "none" | "loading" | "errored" | "passed";

export const progressGap = "2";
export const progressStepGap = "after:h-[2rem]";

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

const state = [
  { status: "loading" },
  { status: "none" },
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

// A utility function to join the progress item and state arrays
export const pairProgressWithState = (
  progressItem: string[],
  state: { status: string }[]
): { name: string; status: Status }[] => {
  const combinedArray = progressItem.map((name: string, index: number) => {
    return { name, status: state[index].status as Status };
  });
  return combinedArray;
};

export default ProgressModal;

// A utility to get the attest loading index
export const getLatestLoadingIndex = (
  progressSteps: { name: string; status: Status }[]
): number => {
  let latestIndex = -1;
  progressSteps.forEach((step, index) => {
    if (step.status === "loading") {
      latestIndex = index;
    }
  });
  return latestIndex;
};
