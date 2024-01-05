import Image from "next/image";
import Link from "next/link";
import Emoji from "../atoms/Emoji";

interface IEmojiCard {
  title: string;
  href: string;
  emoji: string;
}

interface IImageCard {
  title: string;
  href: string;
  logo: string;
}

type ICard = IEmojiCard | IImageCard;

const GrantCard = (card: ICard) => {
  return (
    <Link href={card.href}>
      <div className=" p-4 gap-4 flex flex-col items-center bg-[#DEE6E5] rounded-[10px]">
        <div className="p-6 grid place-items-center bg-[#ffffff] rounded-full">
          {"emoji" in card && (
            <Emoji className="w-14 text-5xl" emoji={card.emoji} />
          )}
          {"logo" in card && (
            <Image src={card.logo} alt={card.title} width={56} height={56} />
          )}
        </div>
        <p className=" text-xl font-semibold">{card.title}</p>
      </div>
    </Link>
  );
};

export default GrantCard;
