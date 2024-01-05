import Image from "next/image";
import Button from "../atoms/Button";

const ConnectWallet = () => {
  return (
    <div className=" w-[250px] flex flex-col gap-8 items-center pb-[160px]">
      <Image src={"/wand.svg"} alt={"wand"} width={30} height={30} />
      <p className=" text-center">
        Connect your wallet to interact and see your projects
      </p>
      <Button text={"Connect wallet"} handleClick={undefined} />
    </div>
  );
};

export default ConnectWallet;
