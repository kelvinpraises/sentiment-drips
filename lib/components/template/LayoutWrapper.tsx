"use client";
import { Inter } from "next/font/google";
import { usePathname } from "next/navigation";

import ProjectEcoFundNav from "../organisms/ProjectEcoFundNav";
import useSIWE from "@/lib/hooks/siwe";
import { useStore } from "@/lib/store/useStore";
import Footer from "../organisms/Footer";
import Header from "../organisms/Header";

const inter = Inter({ subsets: ["latin"] });

const LayoutWrapper = ({ children }: { children: React.ReactNode }) => {
  const pathname = usePathname();
  // check login and update state
  const { verifyAuthentication } = useSIWE();

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
    // /:spaceId/:documentationId/tutorials/:tutorialId
    /^\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+\/explanations\/[a-zA-Z0-9_-]+$/,
    /^\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+\/explanations\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$/,
    /^\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+\/reference+$/,
    /^\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+\/tutorials\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$/,
    /^\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+\/guides\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$/,
  ];

  // Check if the current pathname matches any of the path patterns
  const isPathMatched = pathPatterns.some((pattern) => pattern.test(pathname));

  return (
    <html lang="en">
      <body className={inter.className}>
        {isPathMatched ? (
          <main className=" flex flex-col gap-1 w-screen relative">
            <Header
              className={
                "fixed top-[2px] z-10 w-full border-solid border-b-4 border-b-[#F2F4F8]"
              }
            />
            <div className=" flex px-1 gap-1">{children}</div>
            <Footer className=" pt-8" />
          </main>
        ) : (
          <main className=" flex flex-col gap-8 w-screen h-screen">
            <Header />
            <div className=" flex flex-1 overflow-y-scroll px-8 gap-8">
              <ProjectEcoFundNav />
              {children}
            </div>
            <Footer />
          </main>
        )}
      </body>
    </html>
  );
};

export default LayoutWrapper;
