'use client';

import { useState, useEffect, ReactNode } from 'react';
import { useAuth } from '../../lib/auth';
import { hasIdentity } from '../../lib/rbac';
import { Card, Field, TextInput, Btn } from './ui';

function Shell({ children }: { children: ReactNode }) {
  return (
    <main className="min-h-dvh bg-hom-background flex justify-center overflow-y-auto p-6 py-8">
      <div className="w-full max-w-md my-auto">
        <div className="flex items-center gap-3 mb-6 justify-center">
          <div className="h-12 w-12 rounded-[14px] bg-white border-2 border-hom-primary p-1.5 shadow-sm">
            <img src="/logo.png" alt="HOM" className="h-full w-full object-contain" />
          </div>
          <div>
            <div className="font-black tracking-tight text-lg leading-none">HOM</div>
            <div className="text-[9px] font-bold text-hom-primary tracking-widest uppercase">Hospitality Operations Manager</div>
          </div>
        </div>
        {children}
      </div>
    </main>
  );
}

function GateMessage({ icon, title, message }: { icon: ReactNode; title: string; message: string }) {
  const { logout } = useAuth();
  return (
    <Shell>
      <Card className="p-8 text-center">
        <div className="text-5xl mb-4 flex justify-center">{icon}</div>
        <h1 className="text-xl font-black">{title}</h1>
        <p className="text-sm text-zinc-500 mt-2">{message}</p>
        <div className="mt-6">
          <Btn onClick={logout} color="outline">Sign out</Btn>
        </div>
      </Card>
    </Shell>
  );
}

export function AwaitingScreen() {
  return (
    <GateMessage
      icon={<span>⏳</span>}
      title="Awaiting Assignment"
      message="Your account is active but no roles or departments have been assigned yet. Ask your administrator to assign your access."
    />
  );
}

export function SuspendedScreen() {
  return (
    <GateMessage
      icon={<span>🔒</span>}
      title="Account Suspended"
      message="Your access has been suspended. Contact your administrator if you believe this is a mistake."
    />
  );
}

function OwnerRegisterScreen({ onSignIn, onStaff }: { onSignIn?: () => void; onStaff?: () => void }) {
  const { registerOwner } = useAuth();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [hotel, setHotel] = useState('');
  const [pw, setPw] = useState('');
  const [pw2, setPw2] = useState('');
  const [err, setErr] = useState('');

  const submit = () => {
    if (!name.trim() || !email.trim() || !hotel.trim() || !pw) return setErr('Please fill in all required fields');
    if (pw.length < 6) return setErr('Password must be at least 6 characters');
    if (pw !== pw2) return setErr('Passwords do not match');
    registerOwner({ name: name.trim(), email: email.trim(), phone: phone.trim(), password: pw, hotelName: hotel.trim() });
  };

  return (
    <Shell>
      <Card className="p-6">
        <h1 className="text-lg font-black">Create your hotel account</h1>
        <p className="text-xs text-zinc-500 mt-1 mb-5">Set up your hotel to get started. As owner you get full access.</p>
        <div className="space-y-3">
          <Field label="Your full name"><TextInput value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Amina Yusuf" /></Field>
          <Field label="Email address"><TextInput type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="owner@hotel.com" /></Field>
          <Field label="Phone (optional)"><TextInput value={phone} onChange={e => setPhone(e.target.value)} placeholder="+234..." /></Field>
          <Field label="Hotel / Business name"><TextInput value={hotel} onChange={e => setHotel(e.target.value)} placeholder="e.g. Lagos Suites" /></Field>
          <Field label="Password"><TextInput type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="At least 6 characters" /></Field>
          <Field label="Confirm password"><TextInput type="password" value={pw2} onChange={e => setPw2(e.target.value)} placeholder="Repeat password" /></Field>
          {err && <p className="text-xs text-red-600">{err}</p>}
          <Btn onClick={submit} className="w-full justify-center">Create Account</Btn>
          {onStaff && (
            <button onClick={onStaff} className="w-full text-center text-xs font-bold text-hom-primary mt-1">New staff? Join with an invite code</button>
          )}
          {onSignIn && (
            <button onClick={onSignIn} className="w-full text-center text-xs font-bold text-hom-primary">Already registered? Sign in</button>
          )}
        </div>
      </Card>
    </Shell>
  );
}

function StaffRegisterScreen({ initialCode, onBack, onOwner }: { initialCode?: string; onBack?: () => void; onOwner?: () => void }) {
  const { registerStaff } = useAuth();
  const [code, setCode] = useState(initialCode?.toUpperCase() || '');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [pw, setPw] = useState('');
  const [pw2, setPw2] = useState('');
  const [err, setErr] = useState('');

  const submit = () => {
    if (!code.trim() || !name.trim() || !email.trim() || !pw) return setErr('Please fill in all required fields');
    if (pw.length < 6) return setErr('Password must be at least 6 characters');
    if (pw !== pw2) return setErr('Passwords do not match');
    const ok = registerStaff({ inviteCode: code, name: name.trim(), email: email.trim(), phone: phone.trim(), password: pw });
    if (!ok) setErr('Invalid or already-used invite code');
  };

  return (
    <Shell>
      <Card className="p-6">
        <h1 className="text-lg font-black">Join your hotel</h1>
        <p className="text-xs text-zinc-500 mt-1 mb-5">
          {initialCode ? 'Your invite was found — finish setting up your account.' : 'Enter the invite code your administrator sent you.'}
        </p>
        <div className="space-y-3">
          <Field label="Invite code"><TextInput value={code} onChange={e => setCode(e.target.value.toUpperCase())} placeholder="e.g. M1K2X3AB4C" /></Field>
          <Field label="Full name"><TextInput value={name} onChange={e => setName(e.target.value)} placeholder="e.g. John Doe" /></Field>
          <Field label="Email address"><TextInput type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@hotel.com" /></Field>
          <Field label="Phone (optional)"><TextInput value={phone} onChange={e => setPhone(e.target.value)} placeholder="+234..." /></Field>
          <Field label="Password"><TextInput type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="At least 6 characters" /></Field>
          <Field label="Confirm password"><TextInput type="password" value={pw2} onChange={e => setPw2(e.target.value)} placeholder="Repeat password" /></Field>
          {err && <p className="text-xs text-red-600">{err}</p>}
          <Btn onClick={submit} className="w-full justify-center">Register with Invite</Btn>
          {onOwner && (
            <button onClick={onOwner} className="w-full text-center text-xs font-bold text-hom-primary">Own a hotel? Create your account</button>
          )}
          {onBack && (
            <button onClick={onBack} className="w-full text-center text-xs font-bold text-hom-primary">Back to sign in</button>
          )}
        </div>
      </Card>
    </Shell>
  );
}

function LoginScreen({ onStaffRegister }: { onStaffRegister?: () => void }) {
  const { login, ownerRegistered } = useAuth();
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState('');

  const submit = () => {
    if (!email.trim() || !pw) return setErr('Enter your email and password');
    const ok = login(email, pw);
    if (!ok) setErr('Invalid email or password');
  };

  return (
    <Shell>
      <Card className="p-6">
        <h1 className="text-lg font-black">Sign in to HOM</h1>
        <p className="text-xs text-zinc-500 mt-1 mb-5">Your access is determined by your assigned roles and departments.</p>
        <div className="space-y-3">
          <Field label="Email address"><TextInput type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@hotel.com" /></Field>
          <Field label="Password"><TextInput type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="••••••••" onKeyDown={e => e.key === 'Enter' && submit()} /></Field>
          {err && <p className="text-xs text-red-600">{err}</p>}
          <Btn onClick={submit} className="w-full justify-center">Sign In</Btn>
          {onStaffRegister && (
            <button onClick={onStaffRegister} className="w-full text-center text-xs font-bold text-hom-primary">New staff? Register with an invite code</button>
          )}
        </div>
      </Card>
    </Shell>
  );
}

/** Reads ?code= from the URL so WhatsApp invite links can pre-fill sign-up. */
function useInviteCode(): string {
  const [code, setCode] = useState('');
  useEffect(() => {
    if (typeof window === 'undefined') return;
    setCode(new URLSearchParams(window.location.search).get('code') || '');
  }, []);
  return code;
}

/** Zero-trust gate: no default access. Renders login/register/pending/suspended states. */
export function AuthGate({ children }: { children: ReactNode }) {
  const { session, ownerRegistered } = useAuth();
  const inviteCode = useInviteCode();
  const [mode, setMode] = useState<'staff' | 'owner' | null>(null);

  if (!hasIdentity(session)) {
    if (inviteCode || mode === 'staff') {
      return <StaffRegisterScreen initialCode={inviteCode} onBack={() => setMode(null)} onOwner={() => setMode('owner')} />;
    }
    if (mode === 'owner') {
      return <OwnerRegisterScreen onSignIn={() => setMode(null)} onStaff={() => setMode('staff')} />;
    }
    if (!ownerRegistered) {
      return <OwnerRegisterScreen onStaff={() => setMode('staff')} />;
    }
    return <LoginScreen onStaffRegister={() => setMode('staff')} />;
  }
  if (session.status === 'pending') return <AwaitingScreen />;
  if (session.status === 'suspended') return <SuspendedScreen />;
  return <>{children}</>;
}
