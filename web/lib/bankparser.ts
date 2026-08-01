import { BankTransaction } from './types';

// Mirrors mobile/lib/utils/bank_parser.dart — keep in lockstep.

export interface BankParseResult {
  transactions: BankTransaction[];
  errors: string[];
  parsedCount: number;
  skippedCount: number;
}

let idCounter = 0;
const genId = () => `bt_${Date.now()}_${++idCounter}`;

export function parseBankCsv(raw: string, source = 'Bank Statement'): BankParseResult {
  const lines = raw.split(/\r?\n/).map(l => l.trim()).filter(l => l.length > 0);
  const transactions: BankTransaction[] = [];
  const errors: string[] = [];
  let skipped = 0;

  if (lines.length === 0) {
    return { transactions, errors: ['File is empty'], parsedCount: 0, skippedCount: 0 };
  }

  const header = lines[0].toLowerCase();
  const dataLines = lines.slice(1);

  if (header.includes('date') || header.includes('transaction')) {
    const cols = detectColumns(header);
    if (cols && cols.date != null) {
      dataLines.forEach(line => {
        const t = parseRow(line, cols, source);
        if (t) transactions.push(t); else skipped++;
      });
      return { transactions, errors, parsedCount: transactions.length, skippedCount: skipped };
    }
  }

  errors.push('Could not detect CSV format. Ensure header row contains Date, Description/Narration, and Amount columns.');
  return { transactions, errors, parsedCount: 0, skippedCount: dataLines.length };
}

interface ColumnMap { date?: number; description?: number; amount?: number; debit?: number; credit?: number; balance?: number; reference?: number }

function detectColumns(header: string): ColumnMap | null {
  const cols: ColumnMap = {};
  const parts = header.split(',').map(p => p.trim().toLowerCase().replaceAll('"', ''));
  parts.forEach((p, i) => {
    if (p.includes('date')) cols.date = i;
    else if (p.includes('narration') || p.includes('description') || p.includes('details') || p.includes('transaction remark')) cols.description = i;
    else if (p.includes('amount')) cols.amount = i;
    else if (p.includes('debit')) cols.debit = i;
    else if (p.includes('credit')) cols.credit = i;
    else if (p.includes('balance')) cols.balance = i;
    else if (p.includes('reference') || (p.includes('ref') && !p.includes('trans ref'))) cols.reference = i;
    else if (p.includes('trans ref') || p.includes('transaction ref') || p.includes('tran id')) cols.reference = i;
  });
  if (cols.date == null || (cols.amount == null && cols.debit == null && cols.credit == null)) return null;
  return cols;
}

function parseRow(line: string, cols: ColumnMap, source: string): BankTransaction | null {
  try {
    const parts = splitCsvLine(line);
    if (cols.date == null || parts.length <= cols.date) return null;

    const dateStr = parts[cols.date].trim().replaceAll('"', '');
    const date = parseDate(dateStr);
    if (!date) return null;

    const desc = cols.description != null && parts.length > cols.description
      ? parts[cols.description].trim().replaceAll('"', '') : '';

    let amount: number;
    let type: 'CR' | 'DR';
    if (cols.amount != null && parts.length > cols.amount) {
      const raw = parts[cols.amount].trim().replaceAll('"', '').replaceAll(',', '');
      const val = parseFloat(raw);
      if (Number.isNaN(val)) return null;
      amount = Math.abs(val);
      type = val >= 0 ? 'CR' : 'DR';
    } else {
      const debit = cols.debit != null && parts.length > cols.debit
        ? parseFloat(parts[cols.debit].trim().replaceAll('"', '').replaceAll(',', '')) : NaN;
      const credit = cols.credit != null && parts.length > cols.credit
        ? parseFloat(parts[cols.credit].trim().replaceAll('"', '').replaceAll(',', '')) : NaN;
      if (Number.isNaN(debit) && Number.isNaN(credit)) return null;
      amount = !Number.isNaN(credit) ? credit : debit;
      type = !Number.isNaN(debit) && debit > 0 ? 'DR' : 'CR';
    }

    const ref = cols.reference != null && parts.length > cols.reference
      ? parts[cols.reference].trim().replaceAll('"', '') : null;

    let balance: number | undefined;
    if (cols.balance != null && parts.length > cols.balance) {
      const b = parseFloat(parts[cols.balance].trim().replaceAll('"', '').replaceAll(',', ''));
      if (!Number.isNaN(b)) balance = b;
    }

    return { id: genId(), date, description: desc, amount, reference: ref || undefined, balance, source, type };
  } catch {
    return null;
  }
}

function parseDate(s: string): string | null {
  s = s.trim();
  const parts = s.split(/[/\-]/);
  if (parts.length !== 3) return null;
  const y = parseInt(parts[2], 10);
  const m = parseInt(parts[1], 10);
  const d = parseInt(parts[0], 10);
  if (Number.isNaN(y) || Number.isNaN(m) || Number.isNaN(d)) return null;
  const year = y < 100 ? y + 2000 : y;
  const dt = new Date(year, m - 1, d);
  if (isNaN(dt.getTime())) return null;
  const mm = String(m).padStart(2, '0');
  const dd = String(d).padStart(2, '0');
  return `${year}-${mm}-${dd}`;
}

function splitCsvLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === '"') inQuotes = !inQuotes;
    else if (c === ',' && !inQuotes) { result.push(current); current = ''; }
    else current += c;
  }
  result.push(current);
  return result;
}
