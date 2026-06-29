import { NextResponse, type NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { getUserRole, isAdminRole } from "@/lib/auth";

// Gate privileged surfaces. /admin/* renders with the service_role Drizzle
// client (RLS-bypassing), so without an auth gate any anonymous visitor who
// knows the URL could read internal/unpublished data. Fail closed: anyone who
// is not an admin role gets a 404 (which also hides that the route exists).
export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!isAdminRole(getUserRole(user))) {
    return new NextResponse(null, { status: 404 });
  }

  return response;
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};
