// Roles allowed to reach privileged (service-role / RLS-bypassing) surfaces.
// Mirrors the DB-side is_staff()/is_admin() check in db/002_rls_policies.sql,
// which reads the role from the Supabase Auth JWT app_metadata.role claim.
export const ADMIN_ROLES = [
  "admin",
  "scientific_reviewer",
  "regulatory_reviewer",
  "qa",
] as const;

export function isAdminRole(role: string | null | undefined): boolean {
  return role != null && (ADMIN_ROLES as readonly string[]).includes(role);
}

// Extracts the app_metadata.role claim from a Supabase user object.
export function getUserRole(
  user: { app_metadata?: Record<string, unknown> | null } | null | undefined,
): string | null {
  const role = user?.app_metadata?.role;
  return typeof role === "string" ? role : null;
}
