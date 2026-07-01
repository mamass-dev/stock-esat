import "server-only";
import crypto from "crypto";
import { cookies } from "next/headers";

const EMAIL = "axel.masson@vyv3.fr";
// Hash scrypt (salt:hash) du mot de passe — jamais le mot de passe en clair.
const PWD_HASH =
  "fd89f5a89922855c7f61027ec6100d74:4a38f805d5a0d795dddfc8913c612055bf75f0f8288d88fe96441ed7d02e85952df0a541ad8b39390b86664c977616c658baab5490bc5611a32903d8ecbbb30b";
const SECRET =
  process.env.SESSION_SECRET ??
  "f38b8bc1469cfd31b76d32635e3e14c9a51ceb7e6efd1483bb8cf782ccb3b429";

export const COOKIE = "stock_session";

export function verifyCredentials(email: string, password: string): boolean {
  if (email.trim().toLowerCase() !== EMAIL) return false;
  const [salt, hash] = PWD_HASH.split(":");
  const test = crypto.scryptSync(password, salt, 64).toString("hex");
  const a = Buffer.from(test, "hex");
  const b = Buffer.from(hash, "hex");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function sign(data: string): string {
  return crypto.createHmac("sha256", SECRET).update(data).digest("hex");
}

export function createToken(): string {
  const exp = Date.now() + 1000 * 60 * 60 * 24 * 7; // 7 jours
  const payload = `${EMAIL}|${exp}`;
  return `${Buffer.from(payload).toString("base64url")}.${sign(payload)}`;
}

export function verifyToken(token: string | undefined): boolean {
  if (!token) return false;
  const [b64, sig] = token.split(".");
  if (!b64 || !sig) return false;
  const payload = Buffer.from(b64, "base64url").toString();
  const expected = sign(payload);
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return false;
  const exp = Number(payload.split("|")[1]);
  return exp > Date.now();
}

export async function isAuthed(): Promise<boolean> {
  const c = await cookies();
  return verifyToken(c.get(COOKIE)?.value);
}
