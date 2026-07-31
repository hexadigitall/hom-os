import { load, save } from './storage';

export interface WhatsAppLogEntry { to: string; msg: string; time: string }

const KEY = 'hom_whatsapp_log';

export function appendWhatsAppLog(to: string, msg: string) {
  const existing = load<WhatsAppLogEntry[]>(KEY, []);
  save(KEY, [{ to, msg, time: new Date().toLocaleTimeString() }, ...existing].slice(0, 50));
}
