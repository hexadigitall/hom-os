'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  setDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';
import { getFirestoreInstance } from './firebase';
import { load, save } from './storage';
import { scopedRecords, type Session, type Department } from './rbac';

const epoch = (v: unknown): number =>
  v instanceof Timestamp ? v.toMillis() : typeof v === 'number' ? v : 0;

export interface SyncedCollection<T extends { id: string }> {
  items: T[];
  set: (items: T[]) => void;
  add: (item: T) => void;
  update: (id: string, patch: Partial<T>) => void;
  remove: (id: string) => void;
  replace: (id: string, item: T) => void;
}

const mergeById = <T extends { id: string }>(prev: T[], cloud: T[]): T[] => {
  const cloudIds = new Set(cloud.map((c) => c.id));
  const localOnly = prev.filter((p) => !cloudIds.has(p.id));
  return [...cloud, ...localOnly];
};

/**
 * Firestore-backed, offline-first collection hook. Drop-in for
 * `useScopedCollection` (same department scoping) but reads and writes
 * `hotels/{hotelId}/{collection}` with a persistent IndexedDB cache, so work
 * performed while offline queues locally and syncs on reconnection. When no
 * hotel session exists it falls back to localStorage + seed so the UI still
 * renders.
 *
 * [collectionName] is the Firestore collection under the hotel; [cacheKey] is
 * the existing localStorage key used for the offline mirror.
 */
export function useSyncedCollection<T extends { id: string }>(
  collectionName: string,
  cacheKey: string,
  seed: () => T[],
  session: Session | null | undefined,
): SyncedCollection<T> {
  const db = getFirestoreInstance();
  const hotelId = session?.hotelId;
  const [items, setItems] = useState<T[]>([]);
  const [mounted, setMounted] = useState(false);
  const hydrated = useRef(false);
  const seeded = useRef(false);
  const unsubRef = useRef<(() => void) | null>(null);

  // Hydrate once from localStorage (or the seed) so the UI is instant.
  useEffect(() => {
    if (hydrated.current) return;
    const existing = load<T[] | null>(cacheKey, null);
    setItems(existing && existing.length ? existing : seed());
    hydrated.current = true;
    setMounted(true);
  }, [cacheKey, seed]);

  // Mirror to localStorage so the offline cache stays current.
  useEffect(() => {
    if (mounted) save(cacheKey, items);
  }, [items, mounted, cacheKey]);

  // Subscribe to the hotel's cloud collection when a session is active.
  useEffect(() => {
    unsubRef.current?.();
    if (!hotelId) return;
    const col = collection(db, 'hotels', hotelId, collectionName);
    unsubRef.current = onSnapshot(
      col,
      (snap) => {
        const docs = snap.docs.map((d) => ({
          id: d.id,
          ...d.data(),
        })) as unknown as T[];
        if (docs.length === 0) {
          // First run for this hotel: backfill the seed / cached data once.
          if (seeded.current) return;
          seeded.current = true;
          const cached = load<T[] | null>(cacheKey, null);
          const toPush = cached && cached.length ? cached : seed();
          for (const item of toPush) {
            void setDoc(doc(col, item.id), {
              ...item,
              createdAt: serverTimestamp(),
              updatedAt: serverTimestamp(),
            }).catch(() => {});
          }
          return;
        }
        const sorted = [...docs].sort(
          (a, b) =>
            epoch((a as Record<string, unknown>).createdAt) -
            epoch((b as Record<string, unknown>).createdAt),
        );
        setItems((prev) => mergeById(prev, sorted));
        save(cacheKey, sorted);
      },
      () => {
        /* offline / permission denied — keep local state */
      },
    );
    return () => {
      unsubRef.current?.();
      unsubRef.current = null;
    };
  }, [db, hotelId, collectionName, cacheKey, seed]);

  const ts = () => serverTimestamp();

  const add = useCallback(
    (item: T) => {
      setItems((prev) => [item, ...prev]);
      if (!hotelId) return;
      void setDoc(doc(db, 'hotels', hotelId, collectionName, item.id), {
        ...item,
        createdAt: ts(),
        updatedAt: ts(),
      }).catch(() => {});
    },
    [db, hotelId, collectionName],
  );

  const update = useCallback(
    (id: string, patch: Partial<T>) => {
      setItems((prev) => prev.map((x) => (x.id === id ? { ...x, ...patch } : x)));
      if (!hotelId) return;
      void setDoc(doc(db, 'hotels', hotelId, collectionName, id), {
        ...patch,
        updatedAt: ts(),
      }, { merge: true }).catch(() => {});
    },
    [db, hotelId, collectionName],
  );

  const remove = useCallback(
    (id: string) => {
      setItems((prev) => prev.filter((x) => x.id !== id));
      if (!hotelId) return;
      void deleteDoc(doc(db, 'hotels', hotelId, collectionName, id)).catch(() => {});
    },
    [db, hotelId, collectionName],
  );

  const replace = useCallback(
    (id: string, item: T) => {
      setItems((prev) => prev.map((x) => (x.id === id ? item : x)));
      if (!hotelId) return;
      void setDoc(doc(db, 'hotels', hotelId, collectionName, id), {
        ...item,
        updatedAt: ts(),
      }).catch(() => {});
    },
    [db, hotelId, collectionName],
  );

  const set = useCallback((list: T[]) => setItems(list), []);

  const visible = useMemo(
    () =>
      session
        ? scopedRecords(items as (T & { departments?: Department[] })[], session)
        : items,
    [items, session],
  );

  return { items: visible, set, add, update, remove, replace };
}
