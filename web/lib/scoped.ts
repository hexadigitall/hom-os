'use client';

import { useMemo } from 'react';
import { useCollection } from './storage';
import { scopedRecords, type Session, type Department } from './rbac';

/**
 * localStorage collection whose returned `items` are filtered to the user's
 * department scope (management / unrestricted sessions see everything).
 * Mutations still operate on the full backing store.
 */
export function useScopedCollection<T extends { id: string }>(
  key: string,
  seed: () => T[],
  session: Session | null | undefined,
) {
  const col = useCollection<T>(key, seed);
  const items = useMemo(
    () => (session
      ? scopedRecords(col.items as (T & { departments?: Department[] })[], session)
      : col.items),
    [col.items, session],
  );
  return { ...col, items };
}
