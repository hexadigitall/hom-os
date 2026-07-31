'use client';

import { ReactNode } from 'react';
import { X } from 'lucide-react';

export function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <div className={`bg-white rounded-2xl border ${className}`}>{children}</div>;
}

const CHIP: Record<string, string> = {
  available: 'bg-green-100 text-green-700',
  'checked-in': 'bg-green-100 text-green-700',
  approved: 'bg-green-100 text-green-700',
  delivered: 'bg-green-100 text-green-700',
  running: 'bg-green-100 text-green-700',
  paid: 'bg-green-100 text-green-700',
  resolved: 'bg-green-100 text-green-700',
  locked: 'bg-green-100 text-green-700',
  active: 'bg-green-100 text-green-700',
  valid: 'bg-green-100 text-green-700',
  matched: 'bg-green-100 text-green-700',
  settled: 'bg-green-100 text-green-700',
  served: 'bg-green-100 text-green-700',
  free: 'bg-green-100 text-green-700',
  completed: 'bg-green-100 text-green-700',
  returned: 'bg-green-100 text-green-700',
  safe: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
  maintenance: 'bg-red-100 text-red-700',
  fault: 'bg-red-100 text-red-700',
  overdue: 'bg-red-100 text-red-700',
  expired: 'bg-red-100 text-red-700',
  condemned: 'bg-red-100 text-red-700',
  mismatched: 'bg-red-100 text-red-700',
  flagged: 'bg-red-100 text-red-700',
  occupied: 'bg-red-100 text-red-700',
  low: 'bg-red-100 text-red-700',
  theft: 'bg-red-100 text-red-700',
  'theft risk': 'bg-red-100 text-red-700',
  pending: 'bg-amber-100 text-amber-700',
  expiring: 'bg-amber-100 text-amber-700',
  open: 'bg-amber-100 text-amber-700',
  investigating: 'bg-amber-100 text-amber-700',
  reserved: 'bg-amber-100 text-amber-700',
  preparing: 'bg-amber-100 text-amber-700',
  cleaning: 'bg-amber-100 text-amber-700',
  draft: 'bg-amber-100 text-amber-700',
  confirmed: 'bg-blue-100 text-blue-700',
  ordered: 'bg-blue-100 text-blue-700',
  received: 'bg-blue-100 text-blue-700',
  washing: 'bg-blue-100 text-blue-700',
  drying: 'bg-blue-100 text-blue-700',
  ironing: 'bg-blue-100 text-blue-700',
  ready: 'bg-blue-100 text-blue-700',
  'pending-renewal': 'bg-blue-100 text-blue-700',
  filed: 'bg-blue-100 text-blue-700',
  'checked-out': 'bg-zinc-100 text-zinc-600',
  idle: 'bg-zinc-100 text-zinc-600',
  inactive: 'bg-zinc-100 text-zinc-600',
  routine: 'bg-zinc-100 text-zinc-600',
};

export function StatusChip({ status, label }: { status: string; label?: string }) {
  const key = status.toLowerCase();
  return (
    <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium whitespace-nowrap ${CHIP[key] || 'bg-zinc-100 text-zinc-600'}`}>
      {label || status}
    </span>
  );
}

export function MetricCard({ label, value, sub, color = 'bg-blue-50 text-blue-700' }: { label: string; value: ReactNode; sub?: string; color?: string }) {
  return (
    <div className="rounded-2xl p-5 border bg-white">
      <div className={`text-xs font-bold ${color} px-2 py-0.5 rounded-full inline-block`}>{label}</div>
      <div className="text-3xl font-black mt-2 truncate">{value}</div>
      {sub && <div className="text-xs text-zinc-500 mt-1 truncate">{sub}</div>}
    </div>
  );
}

export function SectionHeader({ title, children, sub }: { title: ReactNode; children?: ReactNode; sub?: string }) {
  return (
    <div className="flex justify-between items-center gap-3 flex-wrap">
      <div className="min-w-0">
        <h2 className="font-bold truncate">{title}</h2>
        {sub && <p className="text-xs text-zinc-500 mt-0.5">{sub}</p>}
      </div>
      <div className="flex gap-2 flex-wrap shrink-0">{children}</div>
    </div>
  );
}

export function Btn({ onClick, children, color = 'primary', className = '', disabled }: { onClick?: () => void; children: ReactNode; color?: 'primary' | 'amber' | 'outline' | 'danger' | 'green'; className?: string; disabled?: boolean }) {
  const base = 'px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-1.5 transition-colors';
  const colors = {
    primary: 'bg-hom-primary text-white hover:bg-hom-primary-dark',
    amber: 'bg-amber-500 text-white hover:bg-amber-600',
    outline: 'border hover:bg-zinc-50',
    danger: 'bg-red-600 text-white hover:bg-red-700',
    green: 'bg-green-600 text-white hover:bg-green-700',
  };
  return (
    <button onClick={onClick} disabled={disabled} className={`${base} ${colors[color]} ${disabled ? 'opacity-40 pointer-events-none' : ''} ${className}`}>{children}</button>
  );
}

export function IconBtn({ onClick, title, children, tone = 'zinc' }: { onClick?: () => void; title?: string; children: ReactNode; tone?: 'zinc' | 'red' | 'green' | 'amber' }) {
  const tones = { zinc: 'hover:bg-zinc-100', red: 'hover:bg-red-50 text-red-500', green: 'hover:bg-green-50 text-green-600', amber: 'hover:bg-amber-50 text-amber-600' };
  return (
    <button onClick={onClick} title={title} className={`p-1.5 rounded-lg transition-colors ${tones[tone]}`}>{children}</button>
  );
}

export function Field({ label, children, className = '' }: { label: string; children: ReactNode; className?: string }) {
  return (
    <label className={`block ${className}`}>
      <span className="block text-xs font-semibold text-zinc-500 mb-1">{label}</span>
      {children}
    </label>
  );
}

export const inputCls = 'border rounded-xl px-4 py-2.5 text-sm w-full focus:outline-none focus:ring-2 focus:ring-hom-primary/30 focus:border-hom-primary';

export function TextInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={`${inputCls} ${props.className || ''}`} />;
}
export function NumberInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input type="number" {...props} className={`${inputCls} ${props.className || ''}`} />;
}
export function DateInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input type="date" {...props} className={`${inputCls} ${props.className || ''}`} />;
}
export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <select {...props} className={`${inputCls} ${props.className || ''}`} />;
}
export function TextArea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea {...props} className={`${inputCls} ${props.className || ''}`} />;
}

export function FormCard({ title, onCancel, children }: { title: string; onCancel?: () => void; children: ReactNode }) {
  return (
    <Card className="p-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-bold">{title}</h3>
        {onCancel && <IconBtn onClick={onCancel} title="Close"><X size={16} /></IconBtn>}
      </div>
      {children}
    </Card>
  );
}

export function EmptyState({ text }: { text: string }) {
  return <div className="p-8 text-center text-sm text-zinc-400 bg-white rounded-2xl border">{text}</div>;
}

export function FieldGrid({ children }: { children: ReactNode }) {
  return <div className="grid md:grid-cols-2 gap-3">{children}</div>;
}

export const paye = (s: number) => Math.round(s * 0.07);
export const pension = (s: number) => Math.round(s * 0.08);
export const netPay = (s: number) => s - paye(s) - pension(s);
