/**
 * gbrain-sync preamble block.
 *
 * Emits bash that runs at every skill invocation:
 *   0. Live gbrain-availability hint (per /plan-eng-review): when gbrain is
 *      configured, emit one of two variants (steady-state vs empty-corpus
 *      emergency). Zero context cost when gbrain is not configured.
 *   1. If ~/.gstack-brain-remote.txt exists AND ~/.gstack/.git is missing,
 *      surface a restore-available hint (does NOT auto-run restore).
 *   2. If sync is on, run `gstack-brain-sync --once` (drain + push).
 *   3. On first skill of the day (24h cache via .brain-last-pull):
 *      `git fetch` + ff-only merge (JSONL merge driver handles conflicts).
 *   4. Emit a `BRAIN_SYNC:` status line so every skill surfaces health.
 *
 * Also emits prose instructions for the host LLM to fire a one-time privacy
 * stop-gate via AskUserQuestion when gbrain_sync_mode is unset and gbrain
 * is available on the host.
 *
 * Block emitted across all tiers. Internal bash short-circuits when feature
 * is disabled; cost is <5ms.
 *
 * Skill-end sync is handled by the completion-status generator via a call
 * to `gstack-brain-sync --discover-new` + `--once`.
 */
import type { TemplateContext } from '../types';

export function generateBrainSyncBlock(ctx: TemplateContext): string {
  // Stripped: gbrain self-promotion removed
  return '';
}
