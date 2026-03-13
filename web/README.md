This is the web app for the supplement comparison project.

## Environment

Create `web/.env.local` from `web/.env.local.example`.

Required variables:

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=
FOODSAFETY_KOREA_API_KEY=
DATA_GO_KR_SERVICE_KEY_ENCODED=
DATA_GO_KR_SERVICE_KEY_DECODED=
```

Notes:

- `NEXT_PUBLIC_*` values are exposed to the browser. Keep API keys out of this prefix.
- `FOODSAFETY_KOREA_API_KEY` is for `foodsafetykorea.go.kr` Open API calls.
- `DATA_GO_KR_SERVICE_KEY_ENCODED` and `DATA_GO_KR_SERVICE_KEY_DECODED` are for `data.go.kr` Open API calls. Some clients or sample URLs expect the encoded key, while server-side code often works better with the decoded key.
- Government API keys should be used only in server-side code, route handlers, scripts, or background jobs.

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
