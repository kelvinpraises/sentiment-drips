"use client";
import useSIWE from "@/hooks/siwe";
import { useStore } from "@/store/useStore";
import Button from "../atoms/Button";
import LoginButton from "../molecules/LoginButton";

const Header = ({ className }: { className?: string }) => {
  return (
    <div
      className={` flex justify-between items-center px-4 min-h-[70px] bg-white pr-8 ${className}`}
    >
      <img src="/logo.svg" alt="" />
      <LoginButton />
    </div>
  );
};

export default Header;
