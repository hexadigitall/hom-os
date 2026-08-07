'use client';

import { useState } from 'react';
import { Rss } from 'lucide-react';
import { ActivityLog } from '@/lib/types';
import { seedActivity } from '@/lib/seed';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { DEPARTMENT_LABEL, type Department } from '@/lib/rbac';
import { Card, SectionHeader, EmptyState } from '../ui';

const timeAgo = (iso: string): string => {
  const t = new Date(iso).getTime();
  if (!t) return '';
  const diff = Date.now() - t;
  const m = Math.floor(diff / 60000);
  if (m < 1) return 'now';
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  return new Date(iso).toISOString().slice(0, 10);
};

const DEPT_COLOR: Record<string, string> = {
  restaurants: '#0E9F6E', kitchen: '#F43F5E', banqueting: '#B45309',
  housekeeping: '#8B5CF6', laundry: '#7C3AED', engineering: '#F59E0B',
  reception: '#06B6D4', reservations: '#0EA5E9', concierge: '#14B8A6',
  security: '#EF4444', accounts: '#3B82F6', procurement: '#6366F1',
  management: '#0E9F6E',
};

const deptLabel = (d: Department): string =>
  DEPARTMENT_LABEL[d] ?? d;

export function FeedModule() {
  const { session } = useAuth();
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const [dept, setDept] = useState<Department | null>(null);

  const depts = Array.from(new Set(feed.items.map((l) => l.dept)));
  const logs = feed.items
    .filter((l) => !dept || l.dept === dept)
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  return (
    <div className="space-y-4">
      <SectionHeader title={`Activity Feed (${logs.length})`}>
        <div className="flex gap-1.5 flex-wrap">
          <button onClick={() => setDept(null)}
            className={`px-3 py-1.5 rounded-full text-xs font-bold ${!dept ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
            All
          </button>
          {depts.map((d) => (
            <button key={d} onClick={() => setDept(d)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold ${dept === d ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
              {deptLabel(d)}
            </button>
          ))}
        </div>
      </SectionHeader>

      {logs.length === 0 && <EmptyState text="No activity yet" />}

      <div className="space-y-2">
        {logs.map((l) => {
          const color = DEPT_COLOR[l.dept] ?? '#616161';
          return (
            <Card key={l.id} className="p-4">
              <div className="flex items-start gap-3">
                <div className="h-9 w-9 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: `${color}22` }}>
                  <Rss size={14} style={{ color }} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-[10px] font-black uppercase tracking-wide px-2 py-0.5 rounded-md" style={{ backgroundColor: `${color}22`, color }}>{deptLabel(l.dept)}</span>
                    <span className="text-[10px] text-zinc-400 ml-auto">{timeAgo(l.createdAt)}</span>
                  </div>
                  <p className="mt-1.5 text-sm font-semibold text-zinc-700 leading-snug">{l.message}</p>
                  <p className="mt-1 text-[11px] text-zinc-500">by {l.actor}</p>
                </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
