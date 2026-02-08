# Summary

It's WoW arena frame addon.

## Rules

* in the end of the process you should call `sync_to_wow.sh` script to sync the changes to WoW directory.

## Reference Links

* [WoW 12.0 API Changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
* [WoW Interface Customization](https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization)
* [WoW Programming API Docs](https://wowprogramming.com/docs/api.html)
* [Ace3 Libraries](https://www.wowace.com/projects/ace3)

## DR Tracking

Since WoW 12.0 (Midnight), `COMBAT_LOG_EVENT_UNFILTERED` is protected and cannot be used by addons to track diminishing returns. Instead, the DRTracker module reparents Blizzard's built-in `SpellDiminishStatusTray` from `CompactArenaFrameMember<N>` onto the Gladius unit button frames and scales/repositions it. To reduce taint risk with secret values, avoid hooking or overriding Blizzard tray internals.
