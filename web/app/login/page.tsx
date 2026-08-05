"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [step, setStep] = useState<"phone" | "otp">("phone");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function sendOtp(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.signInWithOtp({ phone });
    setLoading(false);
    if (error) {
      setError(error.message);
      return;
    }
    setStep("otp");
  }

  async function verifyOtp(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.verifyOtp({ phone, token: otp, type: "sms" });
    setLoading(false);
    if (error) {
      setError(error.message);
      return;
    }
    router.push("/dashboard");
    router.refresh();
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-surface p-4">
      <div className="w-full max-w-sm rounded-xl bg-white p-8 shadow-sm border border-outline-variant">
        <h1 className="font-heading text-2xl font-bold text-on-surface mb-1">Admin Login</h1>
        <p className="text-sm text-on-surface-variant mb-6">Bonding Love Garden management</p>

        {step === "phone" ? (
          <form onSubmit={sendOtp} className="flex flex-col gap-4">
            <label className="flex flex-col gap-1 text-sm font-medium text-on-surface">
              Phone number
              <input
                type="tel"
                required
                autoFocus
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+255700000000"
                className="rounded-lg border border-outline-variant px-3 py-2 font-normal focus:border-primary focus:outline-none"
              />
            </label>
            {error && <p className="text-sm text-error">{error}</p>}
            <button
              type="submit"
              disabled={loading}
              className="rounded-xl bg-primary text-on-primary py-2.5 font-medium disabled:opacity-50"
            >
              {loading ? "Sending…" : "Send code"}
            </button>
          </form>
        ) : (
          <form onSubmit={verifyOtp} className="flex flex-col gap-4">
            <p className="text-sm text-on-surface-variant">Enter the code sent to {phone}</p>
            <input
              type="text"
              required
              autoFocus
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="123456"
              className="rounded-lg border border-outline-variant px-3 py-2 tracking-[0.3em] text-center focus:border-primary focus:outline-none"
            />
            {error && <p className="text-sm text-error">{error}</p>}
            <button
              type="submit"
              disabled={loading}
              className="rounded-xl bg-primary text-on-primary py-2.5 font-medium disabled:opacity-50"
            >
              {loading ? "Verifying…" : "Verify"}
            </button>
            <button
              type="button"
              onClick={() => setStep("phone")}
              className="text-sm text-on-surface-variant underline"
            >
              Use a different number
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
