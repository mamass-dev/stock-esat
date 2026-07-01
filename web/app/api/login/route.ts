import { cookies } from "next/headers";
import { verifyCredentials, createToken, COOKIE } from "@/lib/auth";

export async function POST(request: Request) {
  const { email, password } = await request.json().catch(() => ({}));
  if (!verifyCredentials(email ?? "", password ?? "")) {
    return new Response(JSON.stringify({ ok: false }), { status: 401 });
  }
  const c = await cookies();
  c.set(COOKIE, createToken(), {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 7,
  });
  return Response.json({ ok: true });
}
