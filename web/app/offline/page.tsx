"use client"

export default function OfflinePage() {
  return (
    <div className="min-h-screen bg-hom-background text-hom-ink flex items-center justify-center px-6">
      <div className="text-center max-w-md">
        <div className="text-5xl mb-6">📡</div>
        <h1 className="text-2xl font-black mb-3">You&apos;re offline</h1>
        <p className="text-sm text-white/50 mb-8">
          HOM&apos;s latest screen couldn&apos;t load because you have no internet
          connection. Reconnect and try again — your data is safe.
        </p>
        <button
          type="button"
          onClick={() => window.location.reload()}
          className="px-6 py-3 rounded-xl bg-hom-primary text-black font-bold text-sm"
        >
          Retry
        </button>
      </div>
    </div>
  )
}
