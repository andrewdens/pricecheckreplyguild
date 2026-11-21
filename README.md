# PriceCheck Reply – Guild

A World of Warcraft add-on that answers guild price checks. Use the movable **Reply** button to send prices directly to guild chat, or enable automatic replies.

## Installation

1. Install [PriceCheck Reply](https://github.com/Archydude/PriceCheckReply) and keep it enabled. The Guild add-on uses its pricing preferences.
2. Install **TradeSkillMaster** or **Auctionator** as a price source.
3. Download this repository as a ZIP and extract it. Rename the extracted folder to `PriceCheckReplyGuild` and place it in your client's `Interface/AddOns` folder. The file should be at `Interface/AddOns/PriceCheckReplyGuild/PriceCheckReplyGuild.toc`.
4. Enable **PriceCheck Reply – Guild** in WoW and enter `/pcrguild` to open its settings.

## Guild chat settings

| Setting | What happens when a guildmate requests a price |
| --- | --- |
| **Don't answer** | The Guild add-on takes no action. |
| **Show a reply button** | Click **Reply** to send the price to guild chat. |
| **Reply in guild chat automatically** | Sends the price to guild chat. If the realm restricts automatic guild messages, it whispers the asker instead. |
| **Whisper the asker and show a reply button** | Whispers the price to the asker and shows **Reply** so you can also post it in guild chat. |

Selecting an active mode here turns off the main add-on's automatic guild replies. Right-drag **Reply** to move it.

## Requesting a price

In guild chat, type `?pc` followed by an item link, such as `?pc [Copper Ore]`. You can also put `?` immediately before the item link. Shift-click the item to insert its link.

To test with your own guild messages, run `/pcrguild selftest`. Your requests will count for the next five minutes.

## License

[MIT](LICENSE)
