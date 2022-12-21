import "./globals.css";
import { Grandstander, Source_Sans_3 } from "@next/font/google";

const grandstander = Grandstander({
  variable: "--font-grandstander",
  subsets: ["latin"],
});
const sourceSans = Source_Sans_3({
  variable: "--font-source-sans",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${grandstander.variable} ${sourceSans.variable}`}
    >
      {/*
        <head /> will contain the components returned by the nearest parent
        head.tsx. Find out more at https://beta.nextjs.org/docs/api-reference/file-conventions/head
      */}
      <head />
      <body>{children}</body>
    </html>
  );
}
