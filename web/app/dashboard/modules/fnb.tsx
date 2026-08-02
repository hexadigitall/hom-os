'use client';

import { useState } from 'react';
import { Plus, Trash2, Edit3, UtensilsCrossed, Receipt, BookOpen, Flame, Check, X } from 'lucide-react';
import {
  MenuItem, RestaurantTable, Order, OrderItem, TableStatus, MenuCategory, OrderItemStatus,
} from '@/lib/types';
import { seedMenu, seedTables, seedOrders } from '@/lib/seed';
import { useScopedCollection } from '@/lib/scoped';
import { useAuth } from '@/lib/auth';
import { tagFor, type Department } from '@/lib/rbac';
import { today, nowISO, uid, naira } from '@/lib/format';
import { Card, MetricCard, StatusChip, SectionHeader, Btn, IconBtn, Field, TextInput, NumberInput, Select, FormCard, FieldGrid, EmptyState } from '../ui';

type SubTab = 'tables' | 'orders' | 'menu';

const SUB_NAV: { id: SubTab; label: string; icon: any }[] = [
  { id: 'tables', label: 'Tables', icon: UtensilsCrossed },
  { id: 'orders', label: 'Orders', icon: Receipt },
  { id: 'menu', label: 'Menu', icon: BookOpen },
];

const TABLE_COLOR: Record<TableStatus, string> = {
  free: 'border-green-400 text-green-600 bg-green-50',
  occupied: 'border-red-400 text-red-600 bg-red-50',
  reserved: 'border-amber-400 text-amber-600 bg-amber-50',
  cleaning: 'border-zinc-300 text-zinc-500 bg-zinc-50',
};
const TABLE_CHIP: Record<TableStatus, string> = {
  free: 'bg-green-500', occupied: 'bg-red-500', reserved: 'bg-amber-500', cleaning: 'bg-zinc-400',
};

export function FnbModule() {
  const [tab, setTab] = useState<SubTab>('tables');
  return (
    <div className="space-y-4">
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {SUB_NAV.map(s => {
          const Icon = s.icon;
          return (
            <button key={s.id} onClick={() => setTab(s.id)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap flex items-center gap-1.5 ${tab === s.id ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>
              <Icon size={13} />{s.label}
            </button>
          );
        })}
      </div>
      {tab === 'tables' && <TablesTab />}
      {tab === 'orders' && <OrdersTab />}
      {tab === 'menu' && <MenuTab />}
    </div>
  );
}

// ─── Tables ──────────────────────────────────────────────────────────────────

function TablesTab() {
  const { session } = useAuth();
  const tables = useScopedCollection<RestaurantTable>('fnb_tables', seedTables, session);
  const orders = useScopedCollection<Order>('fnb_orders', seedOrders, session);
  const depts = tagFor(session, 'restaurants');
  const [showForm, setShowForm] = useState(false);
  const [editTable, setEditTable] = useState<RestaurantTable | null>(null);
  const [createFor, setCreateFor] = useState<RestaurantTable | null>(null);
  const [viewOrder, setViewOrder] = useState<Order | null>(null);

  const openOrderFor = (tableId: string) => orders.items.find(o => o.tableId === tableId && o.status !== 'paid' && o.status !== 'cancelled');

  return (
    <div className="space-y-4">
      <SectionHeader title={`Restaurant Tables (${tables.items.length})`}>
        <Btn onClick={() => { setShowForm(true); setEditTable(null); }}><Plus size={14} /> Add Table</Btn>
      </SectionHeader>
      {showForm && (
        <TableForm initial={editTable} depts={depts} onSave={(t) => {
          if (editTable) tables.replace(t.id, t); else tables.add(t);
          setShowForm(false); setEditTable(null);
        }} onCancel={() => { setShowForm(false); setEditTable(null); }} />
      )}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-3">
        {tables.items.map(t => {
          const openOrder = openOrderFor(t.id);
          return (
            <Card key={t.id} className={`p-4 flex flex-col items-center gap-1.5 border-2 ${TABLE_COLOR[t.status]}`}>
              <div className="font-black text-xl">{t.number}</div>
              <div className="text-[10px] text-zinc-500">{t.seats} seats</div>
              <span className={`${TABLE_CHIP[t.status]} text-white text-[9px] px-2 py-0.5 rounded-full font-bold`}>{t.status}</span>
              {openOrder && (
                <button onClick={() => setViewOrder(openOrder)} className="text-[10px] bg-white border rounded-lg px-2 py-1 font-bold text-zinc-700 hover:bg-zinc-50">
                  {naira(orderTotal(openOrder))}
                </button>
              )}
              {!openOrder && t.status === 'free' && (
                <button onClick={() => setCreateFor(t)} className="text-[10px] bg-hom-primary text-white rounded-lg px-2 py-1 font-bold hover:bg-hom-primary-dark">
                  New Order
                </button>
              )}
              <div className="flex gap-1 mt-1">
                <IconBtn onClick={() => { setEditTable(t); setShowForm(true); }}><Edit3 size={12} /></IconBtn>
                <IconBtn tone="red" onClick={() => tables.remove(t.id)}><Trash2 size={12} /></IconBtn>
              </div>
            </Card>
          );
        })}
        {tables.items.length === 0 && <div className="col-span-full"><EmptyState text="No tables configured" /></div>}
      </div>

      {createFor && (
        <NewOrderForm table={createFor} menu={[]} onSave={(name) => {
          const order: Order = { id: uid('fnb'), tableId: createFor.id, items: [], status: 'open', openedAt: nowISO(), servedBy: name, departments: depts };
          orders.add(order);
          tables.update(createFor.id, { status: 'occupied' });
          setViewOrder(order);
          setCreateFor(null);
        }} onCancel={() => setCreateFor(null)} />
      )}

      {viewOrder && (
        <OrderDetail order={viewOrder} tables={tables} orders={orders} menu={{}} onClose={() => setViewOrder(null)} />
      )}
    </div>
  );
}

const orderTotal = (o: Order) => {
  const subtotal = o.items.reduce((a, i) => a + i.quantity * i.unitPrice, 0);
  return subtotal - (o.discount || 0);
};

function NewOrderForm({ table, menu, onSave, onCancel }: { table: RestaurantTable; menu: MenuItem[]; onSave: (serverName: string) => void; onCancel: () => void }) {
  const [server, setServer] = useState('');
  return (
    <FormCard title={`New Order — Table ${table.number}`} onCancel={onCancel}>
      <Field label="Server Name"><TextInput value={server} onChange={e => setServer(e.target.value)} placeholder="Server name" /></Field>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => onSave(server.trim() || 'Staff')}>Create & Add Items</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

// ─── Orders ──────────────────────────────────────────────────────────────────

function OrdersTab() {
  const { session } = useAuth();
  const orders = useScopedCollection<Order>('fnb_orders', seedOrders, session);
  const tables = useScopedCollection<RestaurantTable>('fnb_tables', seedTables, session);
  const [view, setView] = useState<Order | null>(null);
  const [kds, setKds] = useState(false);

  const active = orders.items.filter(o => o.status !== 'paid' && o.status !== 'cancelled');

  return (
    <div className="space-y-4">
      <div className="flex gap-1.5">
        <button onClick={() => setKds(false)}
          className={`px-3 py-1.5 rounded-full text-xs font-bold ${!kds ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600'}`}>Active Orders ({active.length})</button>
        <button onClick={() => setKds(true)}
          className={`px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1 ${kds ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600'}`}><Flame size={12} /> Kitchen View (KDS)</button>
      </div>

      {!kds && (
        <>
          {active.length === 0 && <EmptyState text="No active orders" />}
          <div className="grid md:grid-cols-2 gap-4">
            {active.map(o => (
              <Card key={o.id} className="p-5">
                <div className="flex justify-between items-start gap-2">
                  <div>
                    <div className="font-bold">{tableNumber(tables.items, o.tableId)}</div>
                    <div className="text-[10px] text-zinc-500">{o.servedBy} • {o.status}</div>
                  </div>
                  <StatusChip status={o.status} />
                </div>
                <div className="mt-3 divide-y">
                  {o.items.map((it, i) => (
                    <div key={i} className="py-2 flex justify-between items-center text-sm">
                      <span className="font-medium">{it.quantity}x {it.name}</span>
                      <div className="flex items-center gap-2">
                        <span className="font-bold">{naira(it.quantity * it.unitPrice)}</span>
                        <StatusChip status={it.status} />
                      </div>
                    </div>
                  ))}
                  {o.items.length === 0 && <div className="text-xs text-zinc-400 py-2">No items yet</div>}
                </div>
                <div className="flex justify-between items-center mt-3 pt-3 border-t">
                  <span className="font-bold">{naira(orderTotal(o))}</span>
                  <Btn color="outline" className="!px-3 !py-1.5 !text-[11px]" onClick={() => setView(o)}>Open Order</Btn>
                </div>
              </Card>
            ))}
          </div>
        </>
      )}

      {kds && (
        <div className="grid md:grid-cols-2 gap-4">
          {active.filter(o => o.items.some(it => it.status !== 'served')).length === 0 && <div className="md:col-span-2"><EmptyState text="Kitchen is clear — nothing to prepare" /></div>}
          {active.map(o => {
            const pendingItems = o.items.filter(it => it.status !== 'served');
            if (pendingItems.length === 0) return null;
            return (
              <Card key={o.id} className="p-5 border-2 border-amber-200 bg-amber-50/40">
                <div className="flex justify-between items-center mb-3">
                  <div className="font-black">{tableNumber(tables.items, o.tableId)}</div>
                  <StatusChip status={o.status} />
                </div>
                <div className="space-y-2">
                  {pendingItems.map((it, i) => (
                    <div key={i} className="flex items-center justify-between bg-white rounded-xl px-3 py-2 border">
                      <div>
                        <div className="font-bold text-sm">{it.quantity}x {it.name}</div>
                        {it.note && <div className="text-[10px] text-amber-600">Note: {it.note}</div>}
                      </div>
                      <div className="flex items-center gap-2">
                        <StatusChip status={it.status} />
                        <IconBtn tone="green" title="Advance" onClick={() => advanceItem(orders, o, it)}>
                          {it.status === 'ready' ? <Check size={14} /> : it.status === 'preparing' ? <UtensilsCrossed size={14} /> : <Flame size={14} />}
                        </IconBtn>
                      </div>
                    </div>
                  ))}
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {view && (
        <OrderDetail order={view} tables={tables} orders={orders} menu={{}} onClose={() => setView(null)} />
      )}
    </div>
  );
}

const tableNumber = (tables: RestaurantTable[], id: string) => tables.find(t => t.id === id)?.number || id;

const ITEM_NEXT: Record<OrderItemStatus, OrderItemStatus | null> = {
  pending: 'preparing', preparing: 'ready', ready: 'served', served: null,
};

function advanceItem(orders: any, order: Order, item: OrderItem) {
  const next = ITEM_NEXT[item.status];
  if (!next) return;
  const updatedItems = order.items.map(x => x.id === item.id ? { ...x, status: next } : x);
  const allServed = updatedItems.every(x => x.status === 'served');
  orders.update(order.id, { items: updatedItems, status: allServed && order.status !== 'open' ? 'served' : next === 'preparing' && order.status === 'open' ? 'preparing' : order.status });
}

function OrderDetail({ order, tables, orders, menu, onClose }: { order: Order; tables: any; orders: any; menu: Record<string, never>; onClose: () => void }) {
  const { session } = useAuth();
  const menuItems = useScopedCollection<MenuItem>('fnb_menu', seedMenu, session);
  const [adding, setAdding] = useState(false);
  const [payMethod, setPayMethod] = useState('cash');

  const sendToKitchen = () => {
    const items = order.items.map(x => x.status === 'pending' ? { ...x, status: 'preparing' as OrderItemStatus } : x);
    orders.update(order.id, { items, status: 'preparing' });
  };

  const payOrder = () => {
    tables.update(order.tableId, { status: 'free' });
    orders.update(order.id, { status: 'paid', paymentMethod: payMethod, closedAt: nowISO() });
    onClose();
  };

  return (
    <FormCard title={`Order — Table ${tableNumber(tables.items, order.tableId)}`} onCancel={onClose}>
      <div className="text-xs text-zinc-500 mb-3">Server: {order.servedBy} • {order.status} • Opened {order.openedAt.slice(0, 10)}</div>
      <div className="divide-y rounded-xl border">
        {order.items.map((it, i) => (
          <div key={i} className="py-2 px-3 flex justify-between items-center text-sm">
            <span className="font-medium">{it.quantity}x {it.name}</span>
            <div className="flex items-center gap-2">
              <span className="font-bold">{naira(it.quantity * it.unitPrice)}</span>
              <StatusChip status={it.status} />
              {order.status !== 'paid' && order.status !== 'cancelled' && (
                <IconBtn tone="red" title="Remove item" onClick={() => {
                  const items = order.items.filter(x => x.id !== it.id);
                  orders.update(order.id, { items });
                }}><Trash2 size={13} /></IconBtn>
              )}
            </div>
          </div>
        ))}
        {order.items.length === 0 && <div className="p-4 text-sm text-zinc-400 text-center">No items yet</div>}
      </div>
      <div className="flex justify-between items-center mt-3">
        <span className="font-black text-lg">{naira(orderTotal(order))}</span>
      </div>

      {adding && (
        <div className="mt-4">
          <h4 className="font-bold text-sm mb-2">Add Items</h4>
          <div className="divide-y rounded-xl border max-h-56 overflow-y-auto">
            {menuItems.items.filter(m => m.available).map(m => (
              <div key={m.id} className="flex items-center justify-between px-3 py-2 text-sm">
                <div>
                  <div className="font-medium">{m.name}</div>
                  <div className="text-[10px] text-zinc-400 uppercase">{m.category}</div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-bold">{naira(m.price)}</span>
                  <button onClick={() => {
                    const items = [...order.items, { id: uid('oi'), menuItemId: m.id, name: m.name, quantity: 1, unitPrice: m.price, status: 'pending' as OrderItemStatus }];
                    orders.update(order.id, { items });
                  }} className="w-7 h-7 rounded-lg bg-hom-primary text-white flex items-center justify-center font-black">+</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="mt-4 flex gap-2 flex-wrap">
        {(order.status === 'open' || order.status === 'preparing') && (
          <>
            <Btn color="outline" onClick={() => setAdding(!adding)}>Add Items</Btn>
            {order.items.length > 0 && (
              <Btn color="amber" onClick={sendToKitchen} disabled={order.status === 'preparing'}>{order.status === 'preparing' ? 'In Kitchen' : 'Send to Kitchen'}</Btn>
            )}
          </>
        )}
        {order.items.length > 0 && order.status !== 'paid' && (
          <Btn color="green" onClick={payOrder}>Mark Paid — {naira(orderTotal(order))}</Btn>
        )}
        {(order.status === 'open' || order.status === 'preparing') && order.items.every(x => x.status === 'served') && order.items.length > 0 && (
          <Select value={payMethod} onChange={e => setPayMethod(e.target.value)} className="!w-36 !py-1.5 !text-xs">
            <option>cash</option><option>card</option><option>transfer</option><option>roomCharge</option>
          </Select>
        )}
        {order.status !== 'paid' && order.status !== 'cancelled' && (
          <Btn color="outline" className="!text-red-500" onClick={() => { orders.update(order.id, { status: 'cancelled' }); tables.update(order.tableId, { status: 'free' }); onClose(); }}><X size={14} /> Cancel Order</Btn>
        )}
        <Btn color="outline" className="!text-red-500" onClick={() => { orders.remove(order.id); tables.update(order.tableId, { status: 'free' }); onClose(); }}><Trash2 size={14} /> Delete Order</Btn>
      </div>
    </FormCard>
  );
}

// ─── Menu ────────────────────────────────────────────────────────────────────

const CAT_LABEL: Record<MenuCategory, string> = { food: 'Food', drink: 'Drinks', bar: 'Bar', wine: 'Wine', special: 'Specials' };

function MenuTab() {
  const { session } = useAuth();
  const menu = useScopedCollection<MenuItem>('fnb_menu', seedMenu, session);
  const depts = tagFor(session, 'restaurants');
  const [cat, setCat] = useState<MenuCategory>('food');
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState<MenuItem | null>(null);

  return (
    <div className="space-y-4">
      <SectionHeader title={`Menu (${menu.items.length} items)`}>
        <Btn onClick={() => { setShowForm(true); setEditItem(null); }}><Plus size={14} /> Add Item</Btn>
      </SectionHeader>
      <div className="flex gap-1.5 overflow-x-auto">
        {(Object.keys(CAT_LABEL) as MenuCategory[]).map(c => (
          <button key={c} onClick={() => setCat(c)}
            className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap ${cat === c ? 'bg-hom-primary text-white' : 'bg-white border text-zinc-600 hover:bg-zinc-50'}`}>{CAT_LABEL[c]}</button>
        ))}
      </div>
      {showForm && (
        <MenuForm initial={editItem} depts={depts} onSave={(m) => {
          if (editItem) menu.replace(m.id, m); else menu.add(m);
          setShowForm(false); setEditItem(null);
        }} onCancel={() => { setShowForm(false); setEditItem(null); }} />
      )}
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3">
        {menu.items.filter(m => m.category === cat).map(m => (
          <Card key={m.id} className={`p-4 ${m.available ? '' : 'opacity-50'}`}>
            <div className="flex justify-between items-start gap-2">
              <div>
                <div className="font-bold">{m.name}</div>
                {m.description && <div className="text-xs text-zinc-400 mt-0.5">{m.description}</div>}
              </div>
              <div className="font-black text-hom-primary">{naira(m.price)}</div>
            </div>
            <div className="mt-3 flex items-center gap-2">
              <button onClick={() => menu.update(m.id, { available: !m.available })}
                className={`text-[10px] px-2 py-1 rounded-full font-medium ${m.available ? 'bg-green-100 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>{m.available ? 'Available' : 'Unavailable'}</button>
              <IconBtn onClick={() => { setEditItem(m); setShowForm(true); }}><Edit3 size={14} /></IconBtn>
              <IconBtn tone="red" onClick={() => menu.remove(m.id)}><Trash2 size={14} /></IconBtn>
            </div>
          </Card>
        ))}
        {menu.items.filter(m => m.category === cat).length === 0 && <div className="md:col-span-3"><EmptyState text={`No ${CAT_LABEL[cat].toLowerCase()} on the menu`} /></div>}
      </div>
    </div>
  );
}

function MenuForm({ initial, depts, onSave, onCancel }: { initial: MenuItem | null; depts: Department[]; onSave: (m: MenuItem) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { name: initial.name, category: initial.category, price: String(initial.price), description: initial.description || '' }
    : { name: '', category: 'food' as MenuCategory, price: '', description: '' });
  return (
    <FormCard title={initial ? 'Edit Menu Item' : 'Add Menu Item'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Item Name"><TextInput value={f.name} onChange={e => setF({ ...f, name: e.target.value })} placeholder="Item name" /></Field>
        <Field label="Category">
          <Select value={f.category} onChange={e => setF({ ...f, category: e.target.value as MenuCategory })}>
            {(Object.keys(CAT_LABEL) as MenuCategory[]).map(c => <option key={c} value={c}>{CAT_LABEL[c]}</option>)}
          </Select>
        </Field>
        <Field label="Price (₦)"><NumberInput value={f.price} onChange={e => setF({ ...f, price: e.target.value })} placeholder="Price" /></Field>
        <Field label="Description"><TextInput value={f.description} onChange={e => setF({ ...f, description: e.target.value })} placeholder="Description" /></Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.name || !f.price) return alert('Name and price required'); onSave({ id: initial?.id || uid('fnb'), ...f, price: Number(f.price), available: initial?.available ?? true, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Item'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

function TableForm({ initial, depts, onSave, onCancel }: { initial: RestaurantTable | null; depts: Department[]; onSave: (t: RestaurantTable) => void; onCancel: () => void }) {
  const [f, setF] = useState(initial
    ? { number: initial.number, seats: String(initial.seats), status: initial.status }
    : { number: '', seats: '4', status: 'free' as TableStatus });
  return (
    <FormCard title={initial ? 'Edit Table' : 'Add Table'} onCancel={onCancel}>
      <FieldGrid>
        <Field label="Table Name"><TextInput value={f.number} onChange={e => setF({ ...f, number: e.target.value })} placeholder="Table name" /></Field>
        <Field label="Seats"><NumberInput value={f.seats} onChange={e => setF({ ...f, seats: e.target.value })} placeholder="Capacity" /></Field>
        <Field label="Status">
          <Select value={f.status} onChange={e => setF({ ...f, status: e.target.value as TableStatus })}>
            <option value="free">Free</option><option value="occupied">Occupied</option><option value="reserved">Reserved</option><option value="cleaning">Cleaning</option>
          </Select>
        </Field>
      </FieldGrid>
      <div className="mt-4 flex gap-2">
        <Btn onClick={() => { if (!f.number) return alert('Table name required'); onSave({ id: initial?.id || uid('fnb'), number: f.number, seats: Number(f.seats) || 4, status: f.status, departments: initial?.departments || depts }); }}>{initial ? 'Update' : 'Add Table'}</Btn>
        <Btn color="outline" onClick={onCancel}>Cancel</Btn>
      </div>
    </FormCard>
  );
}
