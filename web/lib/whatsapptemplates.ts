export type WhatsAppTemplateEntity =
  | 'booking'
  | 'staff'
  | 'vendor'
  | 'subscription'
  | 'compliance'
  | 'other';

export interface WhatsAppTemplate {
  id: string;
  name: string;
  entityType: WhatsAppTemplateEntity;
  message: string;
}

export function seedWhatsAppTemplates(): WhatsAppTemplate[] {
  return [
    {
      id: 't1', name: 'Booking Confirmation', entityType: 'booking',
      message:
        'Dear [Guest], your booking at HOM Hotel is confirmed!\n'
        + 'Room: [Room] | Check-in: [Checkin] | Check-out: [Checkout]\n'
        + 'Amount: ₦[Amount]\n'
        + 'Thank you for choosing HOM!',
    },
    {
      id: 't2', name: 'Guest Welcome', entityType: 'booking',
      message:
        'Welcome to HOM Hotel, [Guest]!\n'
        + 'Room [Room] is ready. Enjoy your stay.\n'
        + 'Front Desk: [HotelPhone]',
    },
    {
      id: 't3', name: 'Checkout Reminder', entityType: 'booking',
      message:
        'Dear [Guest], this is a reminder that your checkout '
        + 'from Room [Room] is tomorrow ([Checkout]).\n'
        + 'Thank you for staying with HOM!',
    },
    {
      id: 't4', name: 'Staff Payslip', entityType: 'staff',
      message:
        'HOM PAYROLL — [StaffName]\n'
        + 'Gross: ₦[Gross]\nPAYE (7%): ₦[Paye]\n'
        + 'Pension (8%): ₦[Pension]\nNet Pay: ₦[Net]\n'
        + 'Thank you for your service.',
    },
    {
      id: 't5', name: 'Purchase Order Notification', entityType: 'vendor',
      message:
        'New Purchase Order from HOM Hotel\n'
        + 'Items: [Items]\nAmount: ₦[Amount]\n'
        + 'Date: [Date]\nPlease process accordingly.',
    },
    {
      id: 't6', name: 'Subscription Renewal Reminder', entityType: 'subscription',
      message:
        'Renewal Reminder: [SubName] ([Provider])\n'
        + 'Amount: ₦[Amount]/[Cycle]\n'
        + 'Due in [Days] day(s)\n'
        + 'Please process renewal.',
    },
    {
      id: 't7', name: 'Fuel Theft Alert', entityType: 'other',
      message:
        '⚠️ FUEL THEFT ALERT — HOM Hotel\n'
        + '[FuelType]: [Rate] [Unit] — below efficiency threshold!\n'
        + 'Supplier: [Supplier] | Date: [Date]',
    },
    {
      id: 't8', name: 'General Reminder', entityType: 'other',
      message: 'Reminder from HOM Hotel:\n[Message]',
    },
  ];
}
