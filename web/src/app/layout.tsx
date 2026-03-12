import type { Metadata } from "next";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "NutriCompare — 영양제 비교 분석",
    template: "%s | NutriCompare",
  },
  description:
    "신뢰할 수 있는 영양제·건강기능식품 비교 분석 플랫폼. 규제 정보와 학술 근거를 분리하여 제공합니다.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body className="flex min-h-screen flex-col antialiased">
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
