'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  UserCircle, Mail, Phone, Building2, ShieldCheck, LogOut, Save,
  Lock, CheckCircle2, Bell, Rows3, Globe, Camera,
} from 'lucide-react';
import { useAuth } from '../../../lib/auth';
import {
  Department, Department as Dept, DEPARTMENT_LABEL, ACCOUNT_STATUS_LABEL,
  findRoleById, effectivePermissions, hasIdentity, isManagement,
  DEFAULT_PREFERENCES, UserPreferences,
} from '../../../lib/rbac';
import { Card, SectionHeader, Btn, Field, TextInput, Select, EmptyState, FieldGrid } from '../ui';

const permLabel = (p: string) =>
  p.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/^./, c => c.toUpperCase());

const STATUS_COLOR: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  pending: 'bg-amber-100 text-amber-700',
  suspended: 'bg-red-100 text-red-700',
};

function Chip({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return (
    <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium whitespace-nowrap ${className || 'bg-zinc-100 text-zinc-600'}`}>
      {children}
    </span>
  );
}

function DetailRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center gap-2.5 py-1.5 text-sm">
      <span className="text-zinc-400 shrink-0">{icon}</span>
      <span className="text-zinc-500 shrink-0">{label}</span>
      <span className="font-semibold truncate">{value || '—'}</span>
    </div>
  );
}

interface Profile {
  phone: string;
  photoUrl: string;
  preferences: UserPreferences;
}

const loadProfile = (): Profile => {
  try {
    const raw = localStorage.getItem('hom_web_profile');
    if (raw) {
      const p = JSON.parse(raw);
      return {
        phone: p?.phone || '',
        photoUrl: p?.photoUrl || '',
        preferences: { ...DEFAULT_PREFERENCES, ...(p?.preferences || {}) },
      };
    }
  } catch { /* ignore */ }
  return { phone: '', photoUrl: '', preferences: { ...DEFAULT_PREFERENCES } };
};

function ProfileForm({ onSaved }: { onSaved: (msg: string) => void }) {
  const { session, updateUser } = useAuth();
  const cached = useMemo(loadProfile, []);
  const [name, setName] = useState(session.userName);
  const [phone, setPhone] = useState(cached.phone);
  const [photoUrl, setPhotoUrl] = useState(cached.photoUrl);
  const [saving, setSaving] = useState(false);

  const save = async () => {
    if (!name.trim()) return;
    setSaving(true);
    try {
      if (name.trim() !== session.userName && session.userId) {
        const error = await updateUser(session.userId, { userName: name.trim() });
        if (error) { alert(error); return; }
      }
      try {
        localStorage.setItem('hom_web_profile', JSON.stringify({ phone: phone.trim(), photoUrl: photoUrl.trim(), preferences: cached.preferences }));
      } catch { /* ignore */ }
      onSaved('Profile updated.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Card className="p-6">
      <div className="flex items-center gap-2 mb-4">
        <UserCircle size={18} className="text-hom-primary" />
        <h3 className="font-bold">Profile</h3>
      </div>
      <div className="space-y-3">
        <FieldGrid>
          <Field label="Full name"><TextInput value={name} onChange={e => setName(e.target.value)} placeholder="Your full name" /></Field>
          <Field label="Phone"><TextInput value={phone} onChange={e => setPhone(e.target.value)} placeholder="+234..." /></Field>
        </FieldGrid>
        <Field label="Profile photo URL">
          <div className="flex gap-2 items-center">
            {photoUrl.trim()
              ? <img src={photoUrl.trim()} alt="" className="h-10 w-10 rounded-full object-cover border shrink-0" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
              : <div className="h-10 w-10 rounded-full bg-hom-primary text-white flex items-center justify-center text-sm font-black shrink-0"><Camera size={16} /></div>}
            <TextInput value={photoUrl} onChange={e => setPhotoUrl(e.target.value)} placeholder="https://..." />
          </div>
        </Field>
        <div className="pt-2">
          <Btn onClick={save} disabled={saving}><Save size={14} /> Save Profile</Btn>
        </div>
      </div>
    </Card>
  );
}

function Toggle({ label, icon, active, onChange }: {
  label: string; icon: React.ReactNode; active: boolean; onChange: (v: boolean) => void;
}) {
  return (
    <div className="w-full flex items-center justify-between gap-3 py-2 text-sm">
      <span className="flex items-center gap-2">
        <span className="text-zinc-400">{icon}</span>
        {label}
      </span>
      <button type="button" onClick={() => onChange(!active)} aria-pressed={active}
        className={`relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors ${active ? 'bg-hom-primary' : 'bg-zinc-200'}`}>
        <span className={`inline-block h-4 w-4 rounded-full bg-white shadow transform transition-transform ${active ? 'translate-x-6' : 'translate-x-1'}`} />
      </button>
    </div>
  );
}

function PreferencesForm({ onSaved }: { onSaved: (msg: string) => void }) {
  const cached = useMemo(loadProfile, []);
  const [notifications, setNotifications] = useState(cached.preferences.notificationsEnabled);
  const [compact, setCompact] = useState(cached.preferences.compactMode);
  const [language, setLanguage] = useState(cached.preferences.language);

  const save = () => {
    try {
      localStorage.setItem('hom_web_profile', JSON.stringify({
        phone: cached.phone,
        photoUrl: cached.photoUrl,
        preferences: { notificationsEnabled: notifications, compactMode: compact, language },
      }));
      onSaved('Preferences saved.');
    } catch { /* ignore */ }
  };

  return (
    <Card className="p-6">
      <div className="flex items-center gap-2 mb-4">
        <Globe size={18} className="text-hom-primary" />
        <h3 className="font-bold">App Preferences</h3>
      </div>
      <div className="space-y-3">
        <Toggle label="Notifications" icon={<Bell size={15} />} active={notifications} onChange={setNotifications} />
        <Toggle label="Compact Mode" icon={<Rows3 size={15} />} active={compact} onChange={setCompact} />
        <Field label="Language">
          <Select value={language} onChange={e => setLanguage(e.target.value)}>
            {[{ code: 'en', label: 'English' }, { code: 'fr', label: 'French' }, { code: 'es', label: 'Spanish' }, { code: 'ha', label: 'Hausa' }, { code: 'yo', label: 'Yoruba' }, { code: 'ig', label: 'Igbo' }].map(l => (
              <option key={l.code} value={l.code}>{l.label}</option>
            ))}
          </Select>
        </Field>
        <div className="pt-2">
          <Btn onClick={save}><Save size={14} /> Save Preferences</Btn>
        </div>
      </div>
    </Card>
  );
}

export function AccountModule() {
  const { session, logout } = useAuth();
  const [saved, setSaved] = useState('');
  const cached = useMemo(loadProfile, []);

  if (!hasIdentity(session)) {
    return <EmptyState text="You are not signed in." />;
  }

  const perms = effectivePermissions(session);
  const roles = session.roleIds.map(id => findRoleById(id)?.name || id);
  const depts = session.assignedDepartments.length
    ? session.assignedDepartments
    : (isManagement(session) ? ['management' as Dept] : []);
  const heads = Object.keys(session.isHeadOfDepartment)
    .filter(d => session.isHeadOfDepartment[d]);

  const flash = (m: string) => { setSaved(m); window.setTimeout(() => setSaved(''), 2500); };

  const initials = (session.userName || 'U').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();
  const avatar = session.photoUrl || cached.photoUrl
    ? <img src={session.photoUrl || cached.photoUrl} alt="" className="h-16 w-16 rounded-full object-cover border-2 border-hom-primary shrink-0" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
    : <div className="h-16 w-16 rounded-full bg-hom-primary text-white flex items-center justify-center text-xl font-black shrink-0">{initials}</div>;

  return (
    <div className="space-y-6 max-w-4xl">
      <SectionHeader title="My Account" sub="Your identity, access and preferences in one place." />

      {saved && (
        <div className="flex items-center gap-2 text-sm text-green-700 bg-green-50 border border-green-200 rounded-xl px-4 py-2.5">
          <CheckCircle2 size={16} /> {saved}
        </div>
      )}

      <Card className="p-6">
        <div className="flex items-start gap-4 flex-wrap">
          {avatar}
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className="text-lg font-black">{session.userName}</h3>
              <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${STATUS_COLOR[session.status] || 'bg-zinc-100 text-zinc-600'}`}>
                {ACCOUNT_STATUS_LABEL[session.status]}
              </span>
            </div>
            <div className="flex flex-wrap gap-1.5 mt-2">
              {roles.map(r => <Chip key={r} className="bg-hom-primary/10 text-hom-primary font-bold">{r}</Chip>)}
              {depts.map(d => <Chip key={d}>{DEPARTMENT_LABEL[d]}</Chip>)}
              {heads.map(h => <Chip key={h} className="bg-green-100 text-green-700">Heads {DEPARTMENT_LABEL[h as Department]}</Chip>)}
              {session.customPermissions.length > 0 && <Chip className="bg-amber-100 text-amber-700">+{session.customPermissions.length} custom grants</Chip>}
            </div>
            <div className="mt-3 space-y-1">
              <DetailRow icon={<Mail size={15} />} label="Email" value={session.email} />
              <DetailRow icon={<Phone size={15} />} label="Phone" value={cached.phone} />
              <DetailRow icon={<Building2 size={15} />} label="Hotel" value={session.hotelId || ''} />
            </div>
          </div>
        </div>
      </Card>

      <ProfileForm onSaved={flash} />
      <PreferencesForm onSaved={flash} />

      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <Lock size={18} className="text-hom-primary" />
          <h3 className="font-bold">Password</h3>
        </div>
        <p className="text-xs text-zinc-500">
          Your password is managed by your sign-in provider (Google or email). Use the{' '}
          <span className="font-semibold">Forgot password</span> link on the sign-in screen to reset it via email.
        </p>
      </Card>

      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <ShieldCheck size={18} className="text-hom-primary" />
          <h3 className="font-bold">Your Permissions ({perms.length})</h3>
        </div>
        <p className="text-xs text-zinc-500 mb-3">
          Union of your roles plus custom grants — these decide what you can see and do.
        </p>
        <div className="flex flex-wrap gap-1.5 max-h-52 overflow-y-auto">
          {perms.length === 0 && <span className="text-xs text-zinc-400">No permissions yet — awaiting assignment.</span>}
          {perms.map(p => <Chip key={p} className="bg-zinc-100 text-zinc-600">{permLabel(p)}</Chip>)}
        </div>
      </Card>

      <div className="pt-2">
        <Btn color="outline" className="!text-red-500 !border-red-200 hover:!bg-red-50" onClick={logout}>
          <LogOut size={15} /> Sign Out
        </Btn>
      </div>
    </div>
  );
}
