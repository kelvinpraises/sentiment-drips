"use client";
import { Inter } from "next/font/google";
import { usePathname } from "next/navigation";

import { verifyAuthentication } from "@/library/siwe";
import { useStore } from "@/library/store/useStore";
import { ElementRef, useEffect, useRef } from "react";
import Footer from "../organisms/Footer";
import Header from "../organisms/Header";
import SideNav from "../organisms/SideNav";

const inter = Inter({ subsets: ["latin"], preload: true });

const LayoutWrapper = ({ children }: { children: React.ReactNode }) => {
  const pathname = usePathname();

  const setAppActive = useStore((store) => store.setAppActive);
  const setUserName = useStore((store) => store.setUserName);
  const setUserAddress = useStore((store) => store.setUserAddress);
  const setUserAvatarUrl = useStore((store) => store.setUserAvatarUrl);

  verifyAuthentication(async (res: Response) => {
    const data = await res.json();
    setAppActive(data.authenticated);
    setUserName(data.name);
    setUserAddress(data.address);
    setUserAvatarUrl(data.avatarUrl);
  });

  // Define an array of path patterns
  const pathPatterns = [
    // /documentation/:documentationId
    /^\/documentation+$/,
    /^\/documentation\/[a-zA-Z0-9_-]+$/,
  ];

  // Check if the current pathname matches any of the path patterns
  const isPathMatched = pathPatterns.some((pattern) => pattern.test(pathname));

  const modalRef = useRef<ElementRef<"div">>(null);
  const setModalElementId = useStore((state) => state.setModalElementId);

  useEffect(() => {
    // set up the modal
    if (modalRef.current) {
      setModalElementId(modalRef.current.id);
    }
  }, [modalRef]);

  return (
    <html lang="en">
      <body className={inter.className}>
        {isPathMatched ? (
          <main className=" flex flex-col gap-1 w-screen relative h-screen">
            <Header />
            <div className=" flex px-1 gap-1 h-full">{children}</div>
            <Footer className=" pt-8" />
          </main>
        ) : (
          <main className="flex flex-col gap-8 w-screen h-screen">
            <Header />
            <div className=" flex flex-1 px-8 overflow-hidden gap-8 relative w-full">
              <SideNav />
              <div
                ref={modalRef}
                id="layoutModal"
                className="relative flex w-full bg-white rounded-[10px] overflow-hidden shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]"
              >
                {children}
              </div>
            </div>
            <Footer />
          </main>
        )}
      </body>
    </html>
  );
};

export default LayoutWrapper;
