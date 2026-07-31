export const naira = (n: number) => `₦${Math.round(n).toLocaleString('en-NG')}`;

export const today = () => new Date().toISOString().slice(0, 10);

export const nowISO = () => new Date().toISOString();

export const fmtDate = (d?: string) => {
  if (!d) return '';
  const p = d.slice(0, 10).split('-');
  if (p.length !== 3) return d;
  return `${p[2]}/${p[1]}/${p[0]}`;
};

export const addDays = (d: string, n: number) => {
  const x = new Date(d + 'T00:00:00');
  x.setDate(x.getDate() + n);
  return x.toISOString().slice(0, 10);
};

export const addMonths = (d: string, n: number) => {
  const x = new Date(d + 'T00:00:00');
  x.setMonth(x.getMonth() + n);
  return x.toISOString().slice(0, 10);
};

export const daysBetween = (a: string, b: string) =>
  Math.round((new Date(b + 'T00:00:00').getTime() - new Date(a + 'T00:00:00').getTime()) / 86400000);

export const uid = (prefix: string) =>
  `${prefix}_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 7)}`;

export const monthStart = () => addDays(today(), -new Date().getDate() + 1);

export const monthEnd = () => {
  const d = new Date(today() + 'T00:00:00');
  d.setMonth(d.getMonth() + 1, 0);
  return d.toISOString().slice(0, 10);
};
