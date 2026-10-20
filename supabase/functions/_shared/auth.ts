/** True when the bearer token is a project-signed JWT with role=service_role.
 *  The gateway (verify_jwt) already checked the signature; this narrows it to
 *  our own cron job, since anon and user JWTs pass the gateway too. */
export function isServiceRoleCaller(authHeader: string | null): boolean {
  if (!authHeader?.startsWith("Bearer ")) return false;
  const parts = authHeader.slice("Bearer ".length).split(".");
  if (parts.length !== 3) return false;
  try {
    const payload = JSON.parse(
      atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")),
    );
    return payload.role === "service_role";
  } catch {
    return false;
  }
}
