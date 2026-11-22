# PriceCheck Reply – Guild

A World of Warcraft add-on that answers guild price checks. Use the movable **Reply** button to post prices in guild chat.

## Installation

1. Install [PriceCheck Reply](https://github.com/Archydude/PriceCheckReply) and keep it enabled. The Guild add-on uses its pricing preferences.
2. Install **TradeSkillMaster** or **Auctionator** as a price source.
3. Download this repository as a ZIP and extract it. Rename the extracted folder to `PriceCheckReplyGuild` and place it in your client's `Interface/AddOns` folder. The file should be at `Interface/AddOns/PriceCheckReplyGuild/PriceCheckReplyGuild.toc`.
4. Enable **PriceCheck Reply – Guild** in WoW.

## Using the Reply button

Click **Reply** once per line. If your client blocks direct guild sending, shift-click **Reply** to fill the guild chat box, then press Enter to send.

When multiple replies are ready, **Reply (3)** means three requests are queued, including the one shown in the tooltip. Finish each request's lines or click the **×** to skip that request and move to the next one.

The Guild add-on turns off the main add-on's automatic guild replies when it loads. Hover over **Reply** to preview the next line. Right-drag to move the button, or Shift-right-drag to resize it. Its size and position are saved.

## Requesting a price

In guild chat, type `?pc` followed by an item link, such as `?pc [Copper Ore]`. You can also put `?` immediately before the item link. Shift-click the item to insert its link.

Your own guild price requests count automatically. To test the button, send a price request in guild chat. Run `/pcrguild selftest` for a reminder in game.

A sound plays when a guild price request brings up a reply. Run `/pcrguild test` to hear the sound and show the button with a sample reply. You can hover, move, and resize it. Clicking it confirms the test locally. Run `/pcrguild test hide` to hide it without clicking.

## License

[MIT](LICENSE)
