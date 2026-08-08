import { apiCall } from './firebase';
import { load, save } from './storage';

export interface WhatsAppSendResult {
  ok: boolean;
  mocked?: boolean;
  waId?: string | null;
  reason?: string;
}

export interface WhatsAppSettings {
  phoneId: string;
  wabaId: string;
  displayName: string;
  verified: boolean;
  templateApprovals: string[];
  autoSend: Record<string, boolean>;
}

const SETTINGS_KEY = 'hom_whatsapp_settings';
const DEFAULT_AUTOSEND: Record<string, boolean> = {
  bookingConfirm: true,
  guestWelcome: false,
  checkoutReminder: true,
  payslip: false,
  purchaseOrder: false,
};

let cachedSettings: WhatsAppSettings | null = null;

/**
 * Fetch the per-hotel WABA settings (cached for the session). Callers can
 * respect the `autoSend` toggles before triggering a send.
 */
export async function getWhatsAppSettings(refresh = false): Promise<WhatsAppSettings> {
  if (!refresh && cachedSettings) return cachedSettings;
  try {
    const s = await apiCall<WhatsAppSettings>('GET', '/api/whatsapp/settings');
    cachedSettings = { ...s, autoSend: { ...DEFAULT_AUTOSEND, ...(s.autoSend ?? {}) } };
    save(SETTINGS_KEY, cachedSettings);
    return cachedSettings;
  } catch (err) {
    console.log('Failed to load WhatsApp settings, using defaults.', err);
    return { phoneId: '', wabaId: '', displayName: '', verified: false, templateApprovals: [], autoSend: { ...DEFAULT_AUTOSEND } };
  }
}

/** Whether an auto-send trigger is enabled (defaults ON so zero-config still works). */
export function autoSendEnabled(key: string, settings?: WhatsAppSettings): boolean {
  const s = settings ?? cachedSettings ?? load<WhatsAppSettings | null>(SETTINGS_KEY, null);
  return s?.autoSend?.[key] ?? DEFAULT_AUTOSEND[key] ?? true;
}

/**
 * Send a WhatsApp message through HOM's centralized server route.
 *
 * The WABA token never ships client-side: this function calls
 * `/api/whatsapp/send` with the caller's Firebase ID token, and the server
 * reads the hotel-scoped credential via the Admin SDK.
 *
 * When the hotel has not configured WABA yet (or the server is unreachable)
 * it returns `{ ok: false, mocked: true }` — callers should fall back to a
 * wa.me deep link so messaging still works with zero configuration.
 */
export async function sendWhatsApp(
  to: string,
  message: string,
): Promise<WhatsAppSendResult> {
  try {
    return await apiCall<WhatsAppSendResult>('POST', '/api/whatsapp/send', {
      to,
      message,
    });
  } catch (err) {
    console.log(`[WHATSAPP MOCK] To ${to}: ${message}`, err);
    return { ok: false, mocked: true, reason: 'Server unreachable.' };
  }
}

/** Build a wa.me deep link (zero-cost fallback when WABA is not configured). */
export function waMeUrl(to: string, message: string): string {
  const phone = to.replace(/\D/g, '').replace(/^0/, '234');
  return `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;
}

export function bookingConfirmationTemplate(
  g: string,
  r: string,
  c: string,
): string {
  return `Hello ${g}, your HOM booking Room ${r} from ${c} confirmed. — HOM Hospitality Operations Manager`;
}

export function guestWelcomeTemplate(
  g: string,
  r: string,
  phone: string,
): string {
  return `Welcome to HOM Hotel, ${g}! Room ${r} is ready. Enjoy your stay. Front Desk: ${phone}`;
}

export function checkoutReminderTemplate(
  g: string,
  r: string,
  d: string,
): string {
  return `Dear ${g}, this is a reminder that your checkout from Room ${r} is tomorrow (${d}). Thank you for staying with HOM!`;
}

export function payslipTemplate(n: string, net: number): string {
  return `Hi ${n}, Net ₦${net.toLocaleString()} (PAYE 7% + Pension 8% deducted). Sent via HOM.`;
}

export function poNotificationTemplate(
  vendor: string,
  items: string,
  amount: number,
): string {
  return `New Purchase Order from HOM Hotel\nItems: ${items}\nAmount: ₦${amount.toLocaleString()}\nDate: ${new Date().toISOString().slice(0, 10)}\nPlease process accordingly.\n— Vendor: ${vendor}`;
}
