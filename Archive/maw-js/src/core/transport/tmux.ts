// Barrel re-export. The tmux abstraction is split across:
//   tmux-types.ts      — types + q() + resolveSocket() + tmuxCmd()
//   tmux-class.ts      — Tmux class + default `tmux` instance
//   tmux-pane-lock.ts  — withPaneLock + splitWindowLocked
//   tmux-pane-tags.ts  — tagPane + readPaneTags
// Importers should keep using `./tmux` — this stub forwards everything.

export type { TmuxPane, TmuxWindow, TmuxSession } from "./tmux-types";
export { resolveSocket, tmuxCmd } from "./tmux-types";
export { Tmux, tmux } from "./tmux-class";

import { withPaneLock as _withPaneLock, splitWindowLocked as _splitWindowLocked } from "./tmux-pane-lock";
import type { SplitWindowLockedOpts as _SplitWindowLockedOpts } from "./tmux-pane-lock";
export const withPaneLock = _withPaneLock;
export const splitWindowLocked = _splitWindowLocked;
export type SplitWindowLockedOpts = _SplitWindowLockedOpts;

import { tagPane as _tagPane, readPaneTags as _readPaneTags } from "./tmux-pane-tags";
import type { TagPaneOpts as _TagPaneOpts, PaneTags as _PaneTags } from "./tmux-pane-tags";
export const tagPane = _tagPane;
export const readPaneTags = _readPaneTags;
export type TagPaneOpts = _TagPaneOpts;
export type PaneTags = _PaneTags;
