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

function GoogleBtn({ onClick, loading, label = 'Continue with Google' }: { onClick: () => void; loading?: boolean; label?: string }) {
  return (
    <button
      onClick={onClick}
      disabled={loading}
      className="w-full flex items-center justify-center gap-2.5 rounded-xl border border-zinc-300 bg-white px-4 py-2.5 text-sm font-bold text-zinc-700 hover:bg-zinc-50 transition-colors disabled:opacity-50"
    >
      <svg viewBox="0 0 24 24" className="h-4 w-4" aria-hidden="true">
        <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.27-4.74 3.27-8.1z" />
        <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
        <path fill="#FBBC05" d="M5.84 14.1c-.22-.66-.35-1.36-.35-2.1s.13-1.44.35-2.1V7.06H2.18A11 11 0 0 0 1 12c0 1.77.43 3.45 1.18 4.94l3.66-2.84z" />
        <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
      </svg>
      {loading ? 'Please wait…' : label}
    </button>
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

function LoadingScreen() {
  return (
    <Shell>
      <Card className="p-10 text-center">
        <div className="text-4xl mb-3">🏨</div>
        <div className="text-sm text-zinc-500">Loading HOM…</div>
      </Card>
    </Shell>
  );
}

function OwnerRegisterScreen({ onSignIn, onStaff }: { onSignIn?: () => void; onStaff?: () => void }) {
  const { registerOwner, signInWithGoogle, provisionOwner } = useAuth();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [hotel, setHotel] = useState('');
  const [pw, setPw] = useState('');
  const [pw2, setPw2] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);
  const [googleStep, setGoogleStep] = useState<'idle' | 'busy' | 'hotel'>('idle');

  const submit = async () => {
    if (!name.trim() || !email.trim() || !hotel.trim() || !pw) return setErr('Please fill in all required fields');
    if (pw.length < 6) return setErr('Password must be at least 6 characters');
    if (pw !== pw2) return setErr('Passwords do not match');
    setBusy(true); setErr('');
    const error = await registerOwner({ name: name.trim(), email: email.trim(), phone: phone.trim(), password: pw, hotelName: hotel.trim() });
    setBusy(false);
    if (error) setErr(error);
  };

  const google = async () => {
    setGoogleStep('busy'); setErr('');
    try {
      const result = await signInWithGoogle();
      if (result === 'unprovisioned') {
        setGoogleStep('hotel');
      }
    } catch (e: any) {
      setErr(e?.message || 'Google sign-in failed.');
      setGoogleStep('idle');
    }
  };

  const googleName = googleStep === 'hotel' ? (name || '') : '';
  const finishGoogle = async () => {
    if (!googleName.trim() || !hotel.trim()) return setErr('Your name and hotel name are required.');
    setBusy(true); setErr('');
    const error = await provisionOwner({ name: googleName.trim(), hotelName: hotel.trim(), phone: phone.trim() });
    setBusy(false);
    if (error) setErr(error);
  };

  return (
    <Shell>
      <Card className="p-6">
        <h1 className="text-lg font-black">Create your hotel account</h1>
        <p className="text-xs text-zinc-500 mt-1 mb-5">Set up your hotel to get started. As owner you get full access.</p>
        <div className="space-y-3">
          {googleStep !== 'hotel' ? (
            <>
              <GoogleBtn onClick={google} loading={googleStep === 'busy'} />
              <div className="flex items-center gap-3 text-[10px] font-bold text-zinc-300 uppercase">
                <span className="flex-1 h-px bg-zinc-200" /> or with email <span className="flex-1 h-px bg-zinc-200" />
              </div>
            </>
          ) : (
            <p className="text-xs text-zinc-500 bg-zinc-50 border border-zinc-200 rounded-xl p-3">
              Google connected — now finish setting up your hotel.
            </p>
          )}
          <Field label="Your full name"><TextInput value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Amina Yusuf" /></Field>
          <Field label="Email address"><TextInput type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="owner@hotel.com" /></Field>
          <Field label="Phone (optional)"><TextInput value={phone} onChange={e => setPhone(e.target.value)} placeholder="+234..." /></Field>
          <Field label="Hotel / Business name"><TextInput value={hotel} onChange={e => setHotel(e.target.value)} placeholder="e.g. Lagos Suites" /></Field>
          {googleStep !== 'hotel' && (
            <>
              <Field label="Password"><TextInput type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="At least 6 characters" /></Field>
              <Field label="Confirm password"><TextInput type="password" value={pw2} onChange={e => setPw2(e.target.value)} placeholder="Repeat password" /></Field>
            </>
          )}
          {err && <p className="text-xs text-red-600">{err}</p>}
          {googleStep === 'hotel' ? (
            <Btn onClick={finishGoogle} className="w-full justify-center" disabled={busy}>Create Hotel with Google</Btn>
          ) : (
            <Btn onClick={submit} className="w-full justify-center" disabled={busy}>Create Account</Btn>
          )}
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

function StaffRegisterScreen({ initialCode, googleMode, onBack, onOwner }: { initialCode?: string; googleMode?: boolean; onBack?: () => void; onOwner?: () => void }) {
  const { registerStaff, redeemInvite, signInWithGoogle } = useAuth();
  const [code, setCode] = useState(initialCode?.toUpperCase() || '');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [pw, setPw] = useState('');
  const [pw2, setPw2] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);
  const [googleBusy, setGoogleBusy] = useState(false);

  const submit = async () => {
    if (!code.trim() || !name.trim() || !email.trim() || !pw) return setErr('Please fill in all required fields');
    if (pw.length < 6) return setErr('Password must be at least 6 characters');
    if (pw !== pw2) return setErr('Passwords do not match');
    setBusy(true); setErr('');
    const error = await registerStaff({ inviteCode: code, name: name.trim(), email: email.trim(), phone: phone.trim(), password: pw });
    setBusy(false);
    if (error) setErr(error);
  };

  const redeem = async () => {
    if (!code.trim()) return setErr('Enter your invite code.');
    setBusy(true); setErr('');
    const error = await redeemInvite(code);
    setBusy(false);
    if (error) setErr(error);
  };

  const google = async () => {
    setGoogleBusy(true); setErr('');
    try {
      const result = await signInWithGoogle();
      if (result === 'unprovisioned' && !googleMode) {
        // Session now represents a signed-in unprovisioned Google user; the
        // AuthGate will re-render this screen in googleMode automatically.
      }
    } catch (e: any) {
      setErr(e?.message || 'Google sign-in failed.');
    } finally {
      setGoogleBusy(false);
    }
  };

  return (
    <Shell>
      <Card className="p-6">
        <h1 className="text-lg font-black">{googleMode ? 'Connect your invite' : 'Join your hotel'}</h1>
        <p className="text-xs text-zinc-500 mt-1 mb-5">
          {googleMode
            ? 'Your Google account is connected. Enter the invite code your administrator sent you.'
            : initialCode
              ? 'Your invite was found — finish setting up your account.'
              : 'Enter the invite code your administrator sent you.'}
        </p>
        <div className="space-y-3">
          <Field label="Invite code"><TextInput value={code} onChange={e => setCode(e.target.value.toUpperCase())} placeholder="e.g. M1K2X3AB4C" /></Field>
          {!googleMode && (
            <>
              <Field label="Full name"><TextInput value={name} onChange={e => setName(e.target.value)} placeholder="e.g. John Doe" /></Field>
              <Field label="Email address"><TextInput type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@hotel.com" /></Field>
              <Field label="Phone (optional)"><TextInput value={phone} onChange={e => setPhone(e.target.value)} placeholder="+234..." /></Field>
              <Field label="Password"><TextInput type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="At least 6 characters" /></Field>
              <Field label="Confirm password"><TextInput type="password" value={pw2} onChange={e => setPw2(e.target.value)} placeholder="Repeat password" /></Field>
            </>
          )}
          {err && <p className="text-xs text-red-600">{err}</p>}
          {googleMode ? (
            <Btn onClick={redeem} className="w-full justify-center" disabled={busy}>Connect Invite Code</Btn>
          ) : (
            <>
              <Btn onClick={submit} className="w-full justify-center" disabled={busy}>Register with Invite</Btn>
              <GoogleBtn onClick={google} loading={googleBusy} />
            </>
          )}
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

function LoginScreen({ onStaffRegister, onOwnerRegister }: { onStaffRegister?: () => void; onOwnerRegister?: () => void }) {
  const { login, signInWithGoogle } = useAuth();
  const [email, setEmail] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);
  const [googleBusy, setGoogleBusy] = useState(false);

  const submit = async () => {
    if (!email.trim() || !pw) return setErr('Enter your email and password');
    setBusy(true); setErr('');
    const error = await login(email, pw);
    setBusy(false);
    if (error) setErr(error);
  };

  const google = async () => {
    setGoogleBusy(true); setErr('');
    try {
      await signInWithGoogle();
      // If provisioned, the role listener signs us in; if not, AuthGate
      // switches to the invite-code step automatically.
    } catch (e: any) {
      setErr(e?.message || 'Google sign-in failed.');
    } finally {
      setGoogleBusy(false);
    }
  };

  return (
    <Shell>
      <Card className="p-6">
        <h1 className="text-lg font-black">Sign in to HOM</h1>
        <p className="text-xs text-zinc-500 mt-1 mb-5">Your access is determined by your assigned roles and departments.</p>
        <div className="space-y-3">
          <GoogleBtn onClick={google} loading={googleBusy} />
          <div className="flex items-center gap-3 text-[10px] font-bold text-zinc-300 uppercase">
            <span className="flex-1 h-px bg-zinc-200" /> or with email <span className="flex-1 h-px bg-zinc-200" />
          </div>
          <Field label="Email address"><TextInput type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@hotel.com" /></Field>
          <Field label="Password"><TextInput type="password" value={pw} onChange={e => setPw(e.target.value)} placeholder="••••••••" onKeyDown={e => e.key === 'Enter' && submit()} /></Field>
          {err && <p className="text-xs text-red-600">{err}</p>}
          <Btn onClick={submit} className="w-full justify-center" disabled={busy}>Sign In</Btn>
          {onStaffRegister && (
            <button onClick={onStaffRegister} className="w-full text-center text-xs font-bold text-hom-primary">New staff? Register with an invite code</button>
          )}
          {onOwnerRegister && (
            <button onClick={onOwnerRegister} className="w-full text-center text-xs font-bold text-hom-primary">Create a hotel account</button>
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
  const { session, authReady, firebaseUid } = useAuth();
  const inviteCode = useInviteCode();
  const [mode, setMode] = useState<'staff' | 'owner' | null>(null);

  if (!authReady) return <LoadingScreen />;

  // Signed in via Google but not yet provisioned → must connect an invite.
  const signedInUnprovisioned = firebaseUid.length > 0 && !hasIdentity(session);
  if (signedInUnprovisioned) {
    return <StaffRegisterScreen googleMode initialCode={inviteCode} onOwner={() => setMode('owner')} />;
  }

  if (!hasIdentity(session)) {
    if (inviteCode || mode === 'staff') {
      return <StaffRegisterScreen initialCode={inviteCode} onBack={() => setMode(null)} onOwner={() => setMode('owner')} />;
    }
    if (mode === 'owner') {
      return <OwnerRegisterScreen onSignIn={() => setMode(null)} onStaff={() => setMode('staff')} />;
    }
    return <LoginScreen onStaffRegister={() => setMode('staff')} onOwnerRegister={() => setMode('owner')} />;
  }
  if (session.status === 'pending') return <AwaitingScreen />;
  if (session.status === 'suspended') return <SuspendedScreen />;
  return <>{children}</>;
}
