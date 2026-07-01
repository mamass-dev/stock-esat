import { redirect } from "next/navigation";
import { isAuthed } from "@/lib/auth";
import Sidebar from "@/components/Sidebar";
import RealtimeRefresh from "@/components/RealtimeRefresh";

export default async function DashLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  if (!(await isAuthed())) redirect("/login");
  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 min-w-0">{children}</main>
      <RealtimeRefresh />
    </div>
  );
}
