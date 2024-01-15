import * as Dialog from "@radix-ui/react-dialog";
import React from "react";

import { useStore } from "@/library/store/useStore";
import { isEmpty } from "@/library/utils";
import AllocateProgressItem from "../molecules/allocateProgressItem";
import NewEcosystemProgressItem from "../molecules/newEcosystemProgressItem";
import ReviewProgressItem from "../molecules/reviewProgressItem";
import StrategyProgressItem from "../molecules/strategyProgressItem";
import VoteProgressItem from "../molecules/voteProgressItem";

interface ModalProps {
  modalItem: ModalItem;
  children: React.ReactNode;
}

export type Status = "none" | "loading" | "errored" | "done";
type ModalItem = keyof typeof progressItems;

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

const ProgressModal: React.FC<ModalProps> = ({
  modalItem,
  children,
}: ModalProps) => {
  const modalElementId = useStore((state) => state.modalElementId);
  const modalStep = useStore((state) => state.modalStep);
  const txHashes = useStore((state) => state.txHashes);

  if (isEmpty(modalStep)) {
    return null;
  }

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
            switch (modalItem) {
              case "newEcosystem":
                return (
                  <NewEcosystemProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.newEcosystem,
                      modalStep
                    )}
                    txHashes={txHashes}
                  />
                );
              case "strategy":
                return (
                  <StrategyProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.strategy,
                      modalStep
                    )}
                    txHashes={txHashes}
                  />
                );
              case "vote":
                return (
                  <VoteProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.vote,
                      modalStep
                    )}
                    txHashes={txHashes}
                  />
                );
              case "review":
                return (
                  <ReviewProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.review,
                      modalStep
                    )}
                    txHashes={txHashes}
                  />
                );
              case "allocate":
                return (
                  <AllocateProgressItem
                    progressSteps={pairProgressWithState(
                      progressItems.allocate,
                      modalStep
                    )}
                    txHashes={txHashes}
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
  modalStep: { status: string }[]
): { name: string; status: Status }[] => {
  const combinedArray = progressItem.map((name: string, index: number) => {
    return { name, status: modalStep[index].status as Status };
  });
  return combinedArray;
};

export default ProgressModal;

// A utility to get the attest loading index
export const getLatestLoadingIndex = (
  progressSteps: { name: string; status: Status }[]
): number => {
  let latestIndex = -1;
  let allDone = true;
  progressSteps.forEach((step, index) => {
    if (step.status === "loading") {
      latestIndex = index;
      allDone = false;
    } else if (step.status !== "done") {
      allDone = false;
    }
  });
  if (allDone) {
    latestIndex = progressSteps.length - 1;
  }
  return latestIndex;
};