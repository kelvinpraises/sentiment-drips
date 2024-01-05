import TextHead from "@/library/components/molecules/TextHead";
import LargeCard from "@/library/components/molecules/LargeCard";
import Link from "next/link";

const data = {
  title: "Sentiment Drips",
  link: "View all ecosystems",
  linkHref: "/ecosystems",
  subtitle: "Supporting impactful retroactive project fundings for stakeholders and builders",
  tag: "Home",

  cardArray: [
    {
      href: "/new-ecosystem",
      typeIsLink: true,
      image: "rocket.svg",
      title: "Fund Ecosystem Projects",
      description: "Create pooled funds to support builders in your community.",
      buttonText: "Create Ecosystem",
    },
    {
      href: "/showcase-project",
      typeIsLink: true,
      image: "timer.svg",
      title: "Receive Ecosystem Funding",
      description:
        "Showcase a project to qualify for an ecosystem funding round.",
      buttonText: "Showcase Project",
    },
  ],
};

const page = () => {
  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]">
      <TextHead title={data.title} description={data.subtitle} tag={data.tag} />

      <Link href={data.linkHref || ""} className=" font-semibold">
        {data.link}
      </Link>

      <div className=" grid grid-cols-2 gap-8">
        {data.cardArray?.map((card, index) => (
          <LargeCard
            typeIsLink={card.typeIsLink}
            href={card.href}
            image={card.image}
            key={index}
            title={card.title}
            description={card.description}
            buttonText={card.buttonText}
          />
        ))}
      </div>
    </div>
  );
};

export default page;
