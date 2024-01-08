"use client";
import { usePathname } from "next/navigation";
import { ElementRef, useEffect, useRef, useState } from "react";

import { getEcoFundById } from "@/library/backendAPI";
import EcoFundPassed from "@/library/components/organisms/EcoFundPassed";
import EcoFundProposal from "@/library/components/organisms/EcoFundProposal";
import { useStore } from "@/library/store/useStore";

export interface EcoFundState {
  id: string;
  title: string;
  description: string;
  tokenAmount: string;
  createdBy: string;
  strategyAddress: string;
  proposalPassed: number;
  createdAt: Date;
}

const page = () => {
  const pathname = usePathname();
  const id = pathname.split("/")[3];

  const [data, setData] = useState<Partial<EcoFundState>>();

  const modalRef = useRef<ElementRef<"div">>(null);
  const setModalElementId = useStore((state) => state.setModalElementId);

  useEffect(() => {
    // set up the modal
    if (modalRef.current) {
      setModalElementId(modalRef.current.id);
    }
  }, [modalRef]);

  useEffect(() => {
    (async () => {
      const data = await getEcoFundById(id);

      if (data) {
        setData({
          proposalPassed: data.proposalPassed,
        });
      }
    })();
  }, [id]);

  return (
    <main
      ref={modalRef}
      className="flex-1 relative bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]"
      id="fundModal"
    >
      {(() => {
        switch (data?.proposalPassed) {
          case 0:
            return <EcoFundProposal id={id} />; // TODO:
          case 1:
            return <EcoFundPassed id={id} />;
          default:
            return null;
        }
      })()}
    </main>
  );
};

export default page;
