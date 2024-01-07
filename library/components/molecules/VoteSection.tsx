import Button from "../atoms/Button";

const VoteSection = ({ ecoFundId }: { ecoFundId: any }) => (
  <div className="flex flex-col gap-4">
    <div className=" flex justify-between">
      <p className=" text-sm">
        Vote on whether the proposal fits into the ecosystem
      </p>
      <Button text={"Vote on Proposal"} handleClick={undefined} />
    </div>
    <div className="flex flex-col gap-8">
      <p className="font-bold text-xl">Vote Info</p>
      <div className="w-[520px]">{}</div>
    </div>
  </div>
);

export default VoteSection;
