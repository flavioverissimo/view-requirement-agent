import "./globals.css";

export const metadata = {
  title: "Requirement Interpretation Console",
  description:
    "Next.js interface for selecting a view and sending free-text criteria to the FastAPI backend.",
};

export default function RootLayout({ children }) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
