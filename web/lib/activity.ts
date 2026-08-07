import { ActivityLog } from './types';
import { nowISO, uid } from './format';

/**
 * Append one entry to the shared activity feed collection. Callers pass the
 * `useSyncedCollection('activity_logs', ...)` handle from their module.
 */
export const postActivity = (
  feed: { add: (item: ActivityLog) => void },
  session: { userName?: string } | null | undefined,
  e: { dept: ActivityLog['dept']; action: string; message: string; refId?: string },
) =>
  feed.add({
    id: uid('act'),
    dept: e.dept,
    action: e.action,
    message: e.message,
    actor: session?.userName || 'Staff',
    refId: e.refId,
    createdAt: nowISO(),
  });
