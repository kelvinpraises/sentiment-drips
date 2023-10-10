import Button from "../atoms/Button";

const VoteSection = ({ docFundId }: { docFundId: any }) => (
  <div className="flex flex-col gap-4">
    <div className=" flex justify-between">
      <p className=" text-sm">Vote for what counts for the ecosystem</p>
      <Button text={"Accept Proposals"} handleClick={undefined} />
      <Button text={"Reject Proposals"} handleClick={undefined} />
      <Button text={"Skip Proposals"} handleClick={undefined} />
    </div>
    <div className="flex flex-col gap-8">
      <p className="font-bold text-xl">Vote Info</p>
      <div className="w-[520px]">{}</div>
    </div>
  </div>
);

export default VoteSection;
