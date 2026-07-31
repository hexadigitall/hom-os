'use client';

import { useState } from 'react';
import { Plus, Edit3, Trash2, Copy } from 'lucide-react';
import { useAuth } from '../../../lib/auth';
import {
  HotelUser, InviteCode, Department, AccountStatus, Permission, PERMISSIONS,
  PREBUILT_ROLES, DEPARTMENT_LABEL, ACCOUNT_STATUS_LABEL, findRoleById,
  hasPermission, hasIdentity,
} from '../../../lib/rbac';
import { Card, SectionHeader, Btn, IconBtn, Field, TextInput, Select, EmptyState, FormCard, StatusChip } from '../ui';

const ROLE_OPTIONS = PREBUILT_ROLES.filter(r => r.id !== 'super_admin' && r.id !== 'auditor');

const STATUS_COLOR: Record<AccountStatus, string> = {
  active: 'bg-green-100 text-green-700',
  pending: 'bg-amber-100 text-amber-700',
  suspended: 'bg-red-100 text-red-700',
};

function RoleChip({ label }: { label: string }) {
  return <span className="text-[10px] px-2 py-0.5 rounded-full font-medium bg-zinc-100 text-zinc-600 whitespace-nowrap">{label}</span>;
}

function DeptChip({ dept }: { dept: Department }) {
  return <span className="text-[10px] px-2 py-0.5 rounded-full font-medium bg-zinc-100 text-zinc-600 whitespace-nowrap">{DEPARTMENT_LABEL[dept]}</span>;
}

function AccountEditForm({ user, onClose }: { user: HotelUser; onClose: () => void }) {
  const { updateUser, deleteUser } = useAuth();
  const [roleIds, setRoleIds] = useState<string[]>(user.roleIds);
  const [depts, setDepts] = useState<Department[]>(user.assignedDepartments);
  const [isHead, setIsHead] = useState<boolean>(Object.values(user.isHeadOfDepartment).some(Boolean));
  const [status, setStatus] = useState<AccountStatus>(user.status);
  const isOwner = user.roleId === 'super_admin';

  const toggleRole = (id: string, on: boolean) => {
    setRoleIds(prev => (on ? [...prev, id] : prev.filter(x => x !== id)));
  };
  const toggleDept = (d: Department, on: boolean) => {
    setDepts(prev => (on ? [...prev, d] : prev.filter(x => x !== d)));
  };

  const save = () => {
    const heads: Record<string, boolean> = {};
    if (isHead) for (const d of depts) heads[d] = true;
    const next: HotelUser = {
      ...user,
      roleIds,
      roleId: roleIds.includes(user.roleId) || !roleIds.length ? user.roleId : roleIds[0],
      assignedDepartments: depts,
      isHeadOfDepartment: heads,
      status,
    };
    updateUser(next);
    onClose();
  };

  const remove = () => {
    if (!confirm(`Delete ${user.name}? Their access ends immediately.`)) return;
    deleteUser(user.userId);
    onClose();
  };

  return (
    <FormCard title={`Manage ${user.name}`} onCancel={onClose}>
      <p className="text-xs text-zinc-500 -mt-2 mb-4">{user.email} • {user.hotelName}</p>

      <div className="mb-4">
        <div className="text-xs font-semibold text-zinc-500 mb-1.5">Roles (additive)</div>
        <div className="space-y-1">
          {PREBUILT_ROLES.map(r => {
            const checked = roleIds.includes(r.id);
            return (
              <label key={r.id} className={`flex items-center gap-2 text-sm cursor-pointer ${isOwner && r.id === 'super_admin' ? 'opacity-60' : ''}`}>
                <input type="checkbox" checked={checked} disabled={isOwner && r.id === 'super_admin'} onChange={e => toggleRole(r.id, e.target.checked)} />
                <span>{r.name}</span>
                {isOwner && r.id === 'super_admin' && <span className="text-[10px] text-zinc-400">(owner — locked)</span>}
              </label>
            );
          })}
        </div>
      </div>

      <div className="mb-4">
        <div className="text-xs font-semibold text-zinc-500 mb-1.5">Department scope</div>
        <div className="flex flex-wrap gap-1.5">
          {(Object.keys(DEPARTMENT_LABEL) as Department[]).map(d => {
            const on = depts.includes(d);
            return (
              <button key={d} onClick={() => toggleDept(d, !on)}
                className={`text-[11px] px-2.5 py-1 rounded-full border font-medium ${on ? 'bg-hom-primary text-white border-hom-primary' : 'bg-white border-zinc-200 text-zinc-600 hover:border-zinc-400'}`}>
                {DEPARTMENT_LABEL[d]}
              </button>
            );
          })}
        </div>
      </div>

      <label className="flex items-center gap-2 text-sm mb-4 cursor-pointer">
        <input type="checkbox" checked={isHead} disabled={depts.length === 0} onChange={e => setIsHead(e.target.checked)} />
        <span className="font-semibold">Department Head</span>
        {depts.length === 0 && <span className="text-[10px] text-zinc-400">(select departments first)</span>}
        {depts.length > 0 && <span className="text-[10px] text-zinc-400">heads {depts.map(d => DEPARTMENT_LABEL[d]).join(', ')}</span>}
      </label>

      <Field label="Account status">
        <Select value={status} onChange={e => setStatus(e.target.value as AccountStatus)}>
          {(Object.keys(ACCOUNT_STATUS_LABEL) as AccountStatus[]).map(s => (
            <option key={s} value={s}>{ACCOUNT_STATUS_LABEL[s]}</option>
          ))}
        </Select>
      </Field>

      <div className="mt-5 flex gap-2">
        <Btn onClick={save}>Save Access</Btn>
        <Btn color="danger" onClick={remove}>Delete</Btn>
        <Btn color="outline" onClick={onClose}>Cancel</Btn>
      </div>
    </FormCard>
  );
}

function InviteForm({ onClose }: { onClose: () => void }) {
  const { generateInvite } = useAuth();
  const [roleId, setRoleId] = useState<string>(ROLE_OPTIONS[0]?.id || '');
  const [depts, setDepts] = useState<Department[]>([]);
  const [isHead, setIsHead] = useState(false);
  const [code, setCode] = useState('');

  const toggleDept = (d: Department, on: boolean) => {
    setDepts(prev => (on ? [...prev, d] : prev.filter(x => x !== d)));
  };

  const generate = () => {
    if (!roleId) return;
    setCode(generateInvite({ roleId, departments: depts, isHead }));
  };

  const copy = async () => {
    await navigator.clipboard.writeText(code);
  };

  return (
    <FormCard title="Invite Staff" onCancel={onClose}>
      <div className="grid md:grid-cols-3 gap-3 mb-3">
        <Field label="Role">
          <Select value={roleId} onChange={e => setRoleId(e.target.value)}>
            {ROLE_OPTIONS.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
          </Select>
        </Field>
        <div className="md:col-span-2">
          <div className="text-xs font-semibold text-zinc-500 mb-1.5">Department scope</div>
          <div className="flex flex-wrap gap-1.5">
            {(Object.keys(DEPARTMENT_LABEL) as Department[]).map(d => {
              const on = depts.includes(d);
              return (
                <button key={d} onClick={() => toggleDept(d, !on)}
                  className={`text-[11px] px-2.5 py-1 rounded-full border font-medium ${on ? 'bg-hom-primary text-white border-hom-primary' : 'bg-white border-zinc-200 text-zinc-600 hover:border-zinc-400'}`}>
                  {DEPARTMENT_LABEL[d]}
                </button>
              );
            })}
          </div>
        </div>
      </div>
      <label className="flex items-center gap-2 text-sm mb-4 cursor-pointer">
        <input type="checkbox" checked={isHead} disabled={depts.length === 0} onChange={e => setIsHead(e.target.checked)} />
        <span className="font-semibold">Department Head</span>
        {depts.length === 0 && <span className="text-[10px] text-zinc-400">(select departments first)</span>}
      </label>
      <div className="flex gap-2">
        <Btn onClick={generate} disabled={!roleId}><Plus size={14} /> Generate Code</Btn>
        <Btn color="outline" onClick={onClose}>Cancel</Btn>
      </div>
      {code && (
        <Card className="mt-4 p-4 text-center bg-hom-background">
          <div className="font-black tracking-widest text-xl text-hom-primary select-all">{code}</div>
          <div className="text-[11px] text-zinc-500 mt-1.5">
            {ROLE_OPTIONS.find(r => r.id === roleId)?.name}
            {depts.length ? ` • Scope: ${depts.map(d => DEPARTMENT_LABEL[d]).join(', ')}` : ''}
            {isHead ? ' • Department Head' : ''}
          </div>
          <Btn color="green" className="mt-3 !py-1.5 !text-xs" onClick={copy}><Copy size={12} /> Copy Code</Btn>
        </Card>
      )}
    </FormCard>
  );
}

export function AccountsModule() {
  const { session, users, invites, deleteInvite } = useAuth();
  const [editUser, setEditUser] = useState<HotelUser | null>(null);
  const [showInvite, setShowInvite] = useState(false);

  if (!hasIdentity(session) || !hasPermission(session, PERMISSIONS.manageUsers)) {
    return <EmptyState text="You do not have permission to manage app accounts." />;
  }

  const myId = session.userId;
  const others = users.filter(u => u.userId !== myId);

  return (
    <div className="space-y-6">
      <SectionHeader title={`App Accounts (${users.length})`}>
        <Btn color="amber" onClick={() => setShowInvite(true)}><Plus size={14} /> Invite Staff</Btn>
      </SectionHeader>

      {editUser && <AccountEditForm user={editUser} onClose={() => setEditUser(null)} />}
      {showInvite && <InviteForm onClose={() => setShowInvite(false)} />}

      <div className="space-y-3">
        {users.map(u => {
          const isMe = u.userId === myId;
          const roles = u.roleIds.map(id => findRoleById(id)?.name || id).join(', ');
          const scope = u.assignedDepartments.length
            ? u.assignedDepartments.map(d => DEPARTMENT_LABEL[d]).join(', ')
            : 'All (Management)';
          const heads = Object.keys(u.isHeadOfDepartment).filter(d => u.isHeadOfDepartment[d]).map(d => DEPARTMENT_LABEL[d as Department] || d);
          return (
            <Card key={u.userId} className="p-4">
              <div className="flex items-start justify-between gap-3 flex-wrap">
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-bold">{u.name}</span>
                    {isMe && <span className="text-[10px] font-bold bg-hom-primary/10 text-hom-primary px-2 py-0.5 rounded-full">YOU</span>}
                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${STATUS_COLOR[u.status]}`}>{ACCOUNT_STATUS_LABEL[u.status]}</span>
                  </div>
                  <div className="text-xs text-zinc-500 mt-0.5">{u.email}</div>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    <RoleChip label={roles} />
                    <RoleChip label={scope} />
                    {heads.map(h => <span key={h} className="text-[10px] px-2 py-0.5 rounded-full font-medium bg-green-100 text-green-700 whitespace-nowrap">Heads {h}</span>)}
                  </div>
                </div>
                <IconBtn onClick={() => setEditUser(u)} title={isMe ? 'Manage my own access' : 'Manage access'}><Edit3 size={15} /></IconBtn>
              </div>
            </Card>
          );
        })}
        {users.length === 0 && <EmptyState text="No app accounts yet" />}
      </div>

      <div>
        <SectionHeader title={`Invite Codes (${invites.length})`} />
        <Card className="mt-3 overflow-hidden">
          <div className="divide-y">
            {invites.map((inv: InviteCode) => {
              const role = findRoleById(inv.roleId);
              const used = !!inv.usedByUserId;
              return (
                <div key={inv.code} className="p-4 flex items-center justify-between gap-3 flex-wrap">
                  <div className="min-w-0">
                    <div className="font-bold tracking-wider text-hom-primary select-all">{inv.code}</div>
                    <div className="text-xs text-zinc-500 mt-0.5">
                      {role?.name || inv.roleName}
                      {inv.departments.length ? ` • ${inv.departments.map(d => DEPARTMENT_LABEL[d]).join(', ')}` : ''}
                      {inv.isHead ? ' • Department Head' : ''}
                      {used ? ` • used ${inv.usedAt ? new Date(inv.usedAt).toLocaleDateString() : ''}` : ''}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusChip status={used ? 'delivered' : 'pending'} label={used ? 'Used' : 'Pending'} />
                    <IconBtn tone="red" title="Revoke code" onClick={() => deleteInvite(inv.code)}><Trash2 size={14} /></IconBtn>
                  </div>
                </div>
              );
            })}
            {invites.length === 0 && <div className="p-6 text-center text-xs text-zinc-400">No invite codes yet</div>}
          </div>
        </Card>
      </div>
    </div>
  );
}
