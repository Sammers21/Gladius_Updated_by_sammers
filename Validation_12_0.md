# 12.0 Restrictions Map and Validation

## Restrictions map
- COMBAT_LOG_EVENT_UNFILTERED: blocked for addons in Midnight (12.0+). Attempting to RegisterEvent triggers ADDON_ACTION_FORBIDDEN.
  - Impacted modules: DRTracker, Dispel, Interrupt.
  - Behavior in Gladius: event registration is skipped in 12.0+, so these features will not update.
- Chat/addon comm restrictions in instances: Gladius does not use chat or addon comms, so there is no direct impact.

## In-game validation checklist
1. Log in out of combat in a non-instance zone.
2. `/reload` and confirm no ADDON_ACTION_FORBIDDEN errors.
3. Open `/gladius ui`; toggle modules and save; no errors.
4. Run `/gladius test 5`; frames show; move anchor; lock/unlock.
5. Enter arena (skirmish or shuffle); frames update (health, power, castbar).
6. Confirm DR/Dispel/Interrupt indicators do not update (expected under 12.0 restrictions).
7. Exit arena and `/reload`; no new errors.
