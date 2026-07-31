'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

export function load<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;
  try {
    const s = localStorage.getItem(key);
    return s ? (JSON.parse(s) as T) : fallback;
  } catch {
    return fallback;
  }
}

export function save<T>(key: string, value: T) {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* quota / privacy mode — ignore */
  }
}

export interface Collection<T extends { id: string }> {
  items: T[];
  set: React.Dispatch<React.SetStateAction<T[]>>;
  add: (item: T) => void;
  update: (id: string, patch: Partial<T>) => void;
  remove: (id: string) => void;
  replace: (id: string, item: T) => void;
}

/** localStorage-backed collection with deterministic seed fallback (mirrors Flutter stores). */
export function useCollection<T extends { id: string }>(
  key: string,
  seed: () => T[],
): Collection<T> {
  const [items, setItems] = useState<T[]>([]);
  const [mounted, setMounted] = useState(false);
  const hydrated = useRef(false);

  useEffect(() => {
    if (!hydrated.current) {
      const existing = load<T[] | null>(key, null);
      const initial = existing && existing.length ? existing : seed();
      setItems(initial);
      hydrated.current = true;
      setMounted(true);
    }
  }, [key, seed]);

  useEffect(() => {
    if (mounted) save(key, items);
  }, [items, mounted, key]);

  const add = useCallback((item: T) => setItems(prev => [item, ...prev]), []);
  const update = useCallback((id: string, patch: Partial<T>) =>
    setItems(prev => prev.map(x => (x.id === id ? { ...x, ...patch } : x))), []);
  const remove = useCallback((id: string) =>
    setItems(prev => prev.filter(x => x.id !== id)), []);
  const replace = useCallback((id: string, item: T) =>
    setItems(prev => prev.map(x => (x.id === id ? item : x))), []);

  return { items, set: setItems, add, update, remove, replace };
}

/** For cross-module reads (Overview reads bookings, etc.) */
export function useKeyValue<T>(key: string, fallback: T): [T, React.Dispatch<React.SetStateAction<T>>] {
  const [value, setValue] = useState<T>(fallback);
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setValue(load<T>(key, fallback)); setMounted(true); }, [key]);
  useEffect(() => { if (mounted) save(key, value); }, [value, mounted, key]);
  return [value, setValue];
}

/** Deterministic LCG mirroring Flutter's _SeededRandom. */
export function makeRng(seed: number) {
  let s = seed;
  return {
    next: () => {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s;
    },
    nextDouble: () => {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    },
    nextInt: (max: number) => {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return Math.floor((s / 0x7fffffff) * max);
    },
  };
}
