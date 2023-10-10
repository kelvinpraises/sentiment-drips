"use client";
import * as Popover from "@radix-ui/react-popover";
import { EmojiClickData, EmojiStyle } from "emoji-picker-react";
import dynamic from "next/dynamic";
import { useEffect, useState } from "react";
import Emoji from "../atoms/Emoji";

const _EmojiPicker = dynamic(() => import("emoji-picker-react"), {
  ssr: false,
  loading: () => <p>Loading ...</p>,
});

const EmojiPicker = ({
  setSelectedEmoji,
}: {
  setSelectedEmoji: React.Dispatch<Partial<{ emoji: string }>>;
}) => {
  const [selectedEmoji, _setSelectedEmoji] = useState<string>("1f60a");
  useEffect(() => {
    // initialize setSelected with default emoji
    setSelectedEmoji({ emoji: selectedEmoji });
  }, []);

  function onClick(emojiData: EmojiClickData, event: MouseEvent) {
    setSelectedEmoji({ emoji: emojiData.unified });
    _setSelectedEmoji(emojiData.unified);
  }

  return (
    <Popover.Root>
      <Popover.Trigger asChild>
        {selectedEmoji ? (
          <button
            className="border-[1.5px] border-dashed border-white rounded-[5px] py-[2px] px-1 text-2xl font-emoji text-text-slatePlaceholder"
            aria-label="Choose emoji"
          >
            <Emoji emoji={selectedEmoji} />
          </button>
        ) : (
          <button
            className="border-[1.5px] border-dashed border-white rounded-[5px] py-[2px] px-1 text-2xl font-emoji text-text-slatePlaceholder"
            aria-label="Choose emoji"
          >
            😊
          </button>
        )}
      </Popover.Trigger>
      <Popover.Portal>
        <Popover.Content sideOffset={5}>
          <_EmojiPicker
            onEmojiClick={onClick}
            autoFocusSearch={false}
            emojiStyle={EmojiStyle.NATIVE}
          />
          <Popover.Arrow className="fill-white" />
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  );
};

export default EmojiPicker;
