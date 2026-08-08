'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Check, CheckCheck, Send, UserPlus, Megaphone, Hash, User as UserIcon,
} from 'lucide-react';
import { ChatRoom, ChatMessage, ActivityLog } from '@/lib/types';
import { seedChatRooms, seedChatMessages, seedActivity } from '@/lib/seed';
import { useSyncedCollection } from '@/lib/synced';
import { useAuth } from '@/lib/auth';
import { hasPermission, canAccessDepartment, PERMISSIONS } from '@/lib/rbac';
import { uid, nowISO } from '@/lib/format';
import { postActivity } from '@/lib/activity';
import { Card, StatusChip, Btn } from '../ui';

const AVATAR_COLORS = [
  '#0E9F6E', '#2196F3', '#FFC107', '#FF9800', '#EF5350', '#9C27B0', '#009688',
];

const colorFor = (name: string): string => {
  let code = 0;
  for (const c of name) code += c.charCodeAt(0);
  return AVATAR_COLORS[code % AVATAR_COLORS.length];
};

const clock = (iso: string): string => {
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '';
  let h = d.getHours() % 12;
  if (h === 0) h = 12;
  return `${h}:${String(d.getMinutes()).padStart(2, '0')} ${d.getHours() >= 12 ? 'PM' : 'AM'}`;
};

const dayLabel = (iso: string): string => {
  const d = new Date(iso);
  const now = new Date();
  const same = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  if (same(d, now)) return 'Today';
  const y = new Date(now.getTime() - 86400000);
  if (same(d, y)) return 'Yesterday';
  return d.toLocaleDateString('en-NG', { day: 'numeric', month: 'short', year: 'numeric' });
};

export function ChatModule() {
  const { session } = useAuth();
  const rooms = useSyncedCollection<ChatRoom>('chat_rooms', 'chat_rooms', seedChatRooms, session);
  const messages = useSyncedCollection<ChatMessage>('chat_messages', 'chat_messages', seedChatMessages, session);
  const feed = useSyncedCollection<ActivityLog>('activity_logs', 'activity_logs', seedActivity, session);
  const [activeId, setActiveId] = useState<string>('');
  const [mobileThread, setMobileThread] = useState(false);

  const canView = hasPermission(session, PERMISSIONS.viewDepartmentChat);
  const canSend = hasPermission(session, PERMISSIONS.sendChatMessage);
  const canManage = hasPermission(session, PERMISSIONS.manageChat);

  const who = (session?.userId?.length ? session.userId : session?.userName) || '';
  const whoName = session?.userName || 'Staff';

  const visible = useMemo(() => {
    if (!canView) return [];
    return rooms.items.filter(r => {
      if (r.kind === 'dm') {
        return r.members.includes(who) || r.members.includes(whoName);
      }
      if (r.kind === 'general') return true;
      if (!r.departments || r.departments.length === 0) return true;
      return r.departments.some(d => canAccessDepartment(session, d));
    }).sort((a, b) => {
      const rank = (x: ChatRoom) => (x.kind === 'general' ? 0 : x.kind === 'channel' ? 1 : 2);
      if (rank(a) !== rank(b)) return rank(a) - rank(b);
      return new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime();
    });
  }, [rooms.items, session, who, whoName, canView]);

  const activeRoom = visible.find(r => r.id === activeId) || visible[0] || null;
  const effectiveId = activeRoom?.id || '';

  const roomMessages = useMemo(
    () => messages.items
      .filter(m => m.roomId === effectiveId)
      .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()),
    [messages.items, effectiveId],
  );

  const unreadIn = (roomId: string): number => {
    if (!who) return 0;
    return messages.items.filter(m => m.roomId === roomId && !(m.readBy || []).includes(who)).length;
  };

  const canPost = (room: ChatRoom | null): boolean => {
    if (!room) return false;
    if (!canSend) return false;
    if (room.kind === 'general') return canManage;
    return true;
  };

  // Mark everything in the active thread as read by the current user.
  useEffect(() => {
    if (!who || !effectiveId) return;
    for (const m of messages.items) {
      if (m.roomId === effectiveId && !(m.readBy || []).includes(who)) {
        messages.update(m.id, { readBy: [...(m.readBy || []), who] });
      }
    }
  }, [effectiveId, who]); // eslint-disable-line react-hooks/exhaustive-deps

  const send = (text: string) => {
    const room = activeRoom;
    if (!room || !text.trim() || !canPost(room)) return;
    const trimmed = text.trim();
    const msg: ChatMessage = {
      id: uid('msg'),
      roomId: room.id,
      sender: whoName,
      senderId: session?.userId || '',
      text: trimmed,
      createdAt: nowISO(),
      readBy: [who || whoName],
    };
    messages.add(msg);
    rooms.replace(room.id, {
      ...room,
      lastMessage: trimmed,
      lastMessageAt: nowISO(),
    });
    postActivity(feed, session, {
      dept: room.kind === 'general' ? 'management' : (room.departments?.[0] || 'management'),
      action: 'chat.sent',
      message: `Message posted in ${room.name}`,
      refId: msg.id,
    });
  };

  const newDm = () => {
    const name = window.prompt('Start a direct message — enter the staff name:');
    if (!name || !name.trim()) return;
    const member = whoName || who;
    const existing = rooms.items.find(r =>
      r.kind === 'dm' && (r.members.includes(who) || r.members.includes(whoName)) && r.members.includes(name.trim()));
    if (existing) {
      setActiveId(existing.id);
      setMobileThread(true);
      return;
    }
    const room: ChatRoom = {
      id: uid('room'),
      name: name.trim(),
      kind: 'dm',
      departments: [],
      members: [member, name.trim()],
      lastMessage: '',
      lastMessageAt: nowISO(),
      createdAt: nowISO(),
    };
    rooms.add(room);
    setActiveId(room.id);
    setMobileThread(true);
  };

  if (!canView) {
    return <Card className="p-8 text-center text-sm text-zinc-400">No chat access for your role.</Card>;
  }

  const generalLocked = !!activeRoom && activeRoom.kind === 'general' && !canManage;

  return (
    <div className="grid grid-cols-1 md:grid-cols-[300px_1fr] gap-4 h-[calc(100vh-180px)] min-h-[420px]">
      {/* Room list */}
      <Card className={`p-2 overflow-y-auto md:block ${mobileThread ? 'hidden' : 'block'}`}>
        <div className="flex items-center justify-between px-2 pt-2 pb-1">
          <div className="text-xs font-bold text-zinc-500 uppercase tracking-widest">Rooms</div>
          {canSend && (
            <Btn onClick={newDm} color="outline" className="!px-2 !py-1 !text-xs"><UserPlus size={13} /> New DM</Btn>
          )}
        </div>
        {visible.length === 0 && (
          <div className="p-6 text-center text-xs text-zinc-400">No rooms available for your scope.</div>
        )}
        {visible.map(r => {
          const un = unreadIn(r.id);
          const active = r.id === effectiveId;
          return (
            <button key={r.id}
              onClick={() => { setActiveId(r.id); setMobileThread(true); }}
              className={`w-full text-left rounded-xl px-3 py-2.5 flex items-center gap-2.5 transition-colors ${active ? 'bg-hom-primary/10' : 'hover:bg-zinc-50'}`}>
              <span className="h-9 w-9 rounded-full flex items-center justify-center text-white shrink-0"
                style={{ backgroundColor: colorFor(r.name) }}>
                {r.kind === 'general' ? <Megaphone size={16} />
                  : r.kind === 'dm' ? <UserIcon size={16} /> : <Hash size={16} />}
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-bold truncate">{r.name}</span>
                <span className={`block text-xs truncate ${un > 0 ? 'font-semibold text-zinc-800' : 'text-zinc-400'}`}>
                  {r.lastMessage || 'No messages yet'}
                </span>
              </span>
              <span className="flex flex-col items-end shrink-0">
                <span className="text-[10px] text-zinc-400">{clock(r.lastMessageAt)}</span>
                {un > 0 && (
                  <span className="mt-0.5 min-w-[18px] h-[18px] px-1 rounded-full bg-hom-primary text-white text-[10px] font-bold flex items-center justify-center">{un}</span>
                )}
              </span>
            </button>
          );
        })}
      </Card>

      {/* Thread */}
      <Card className={`flex flex-col min-w-0 md:flex ${mobileThread ? 'flex' : 'hidden'}`}>
        {!activeRoom ? (
          <div className="p-8 text-center text-sm text-zinc-400">Select a room to start chatting.</div>
        ) : (
          <>
            <div className="px-4 py-3 border-b flex items-center gap-2.5 shrink-0">
              <button className="md:hidden" onClick={() => setMobileThread(false)} aria-label="Back">←</button>
              <span className="h-9 w-9 rounded-full flex items-center justify-center text-white"
                style={{ backgroundColor: colorFor(activeRoom.name) }}>
                {activeRoom.kind === 'general' ? <Megaphone size={16} />
                  : activeRoom.kind === 'dm' ? <UserIcon size={16} /> : <Hash size={16} />}
              </span>
              <div className="min-w-0">
                <div className="text-sm font-bold truncate">{activeRoom.name}</div>
                <div className="text-[10px] text-zinc-400">
                  {activeRoom.kind === 'general' ? 'Hotel-wide · broadcast'
                    : activeRoom.kind === 'dm' ? 'Direct message'
                    : activeRoom.departments?.join(' · ') || 'Channel'}
                </div>
              </div>
            </div>

            {generalLocked && (
              <div className="px-4 py-2 bg-amber-50 border-b text-xs font-semibold text-amber-700 flex items-center gap-2 shrink-0">
                <Megaphone size={14} /> Broadcast channel — only management & department heads can post.
              </div>
            )}

            <div className="flex-1 overflow-y-auto p-4 space-y-1 bg-zinc-50/60">
              {roomMessages.length === 0 && (
                <div className="p-6 text-center text-xs text-zinc-400">No messages yet — say hello!</div>
              )}
              {roomMessages.map((m, i) => {
                const mine = (m.senderId && session?.userId && m.senderId === session.userId) || (!m.senderId && m.sender === whoName);
                const showName = !mine && (i === 0 || roomMessages[i - 1].sender !== m.sender);
                const showDay = i === 0 || dayLabel(m.createdAt) !== dayLabel(roomMessages[i - 1].createdAt);
                const read = mine && (m.readBy || []).length > 1;
                return (
                  <div key={m.id}>
                    {showDay && (
                      <div className="text-center py-2">
                        <span className="text-[10px] font-bold text-zinc-500 bg-white px-3 py-1 rounded-full border">{dayLabel(m.createdAt)}</span>
                      </div>
                    )}
                    <div className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
                      <div className={`max-w-[78%] ${mine ? 'items-end' : 'items-start'} flex flex-col`}>
                        {showName && (
                          <span className="text-[10px] font-bold mb-0.5 px-1" style={{ color: colorFor(m.sender) }}>{m.sender}</span>
                        )}
                        <div className={`rounded-2xl px-3.5 py-2 ${mine ? 'bg-hom-primary text-white rounded-br-md' : 'bg-white border rounded-bl-md'}`}>
                          <p className="text-sm whitespace-pre-wrap break-words">{m.text}</p>
                          <div className={`flex items-center gap-1 mt-0.5 ${mine ? 'justify-end' : 'justify-start'}`}>
                            <span className={`text-[9px] ${mine ? 'text-white/70' : 'text-zinc-400'}`}>{clock(m.createdAt)}</span>
                            {mine && (read ? <CheckCheck size={12} className="text-white" /> : <Check size={12} className="text-white/70" />)}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="p-3 border-t shrink-0">
              {!canPost(activeRoom) ? (
                <div className="text-xs text-zinc-400 text-center py-1.5">You have read-only access.</div>
              ) : (
                <Composer onSend={send} placeholder={`Message ${activeRoom.name}…`} />
              )}
            </div>
          </>
        )}
      </Card>
    </div>
  );
}

function Composer({ onSend, placeholder }: { onSend: (t: string) => void; placeholder: string }) {
  const [text, setText] = useState('');
  const ref = useRef<HTMLTextAreaElement>(null);
  const submit = () => {
    if (!text.trim()) return;
    onSend(text);
    setText('');
    ref.current?.focus();
  };
  return (
    <div className="flex items-end gap-2">
      <textarea ref={ref} value={text} onChange={e => setText(e.target.value)}
        onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submit(); } }}
        placeholder={placeholder} rows={1}
        className="flex-1 resize-none border rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-hom-primary/30 focus:border-hom-primary" />
      <button onClick={submit} disabled={!text.trim()}
        className={`h-10 w-10 rounded-full flex items-center justify-center transition-colors ${text.trim() ? 'bg-hom-primary text-white hover:bg-hom-primary-dark' : 'bg-zinc-100 text-zinc-400'}`}>
        <Send size={17} />
      </button>
    </div>
  );
}
