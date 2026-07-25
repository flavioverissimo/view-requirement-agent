/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx}",
    "./components/**/*.{js,jsx}",
    "./lib/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        paper: "#f7f1e7",
        ink: "#172121",
        ember: "#b84b2f",
        moss: "#3e5c4d",
        mist: "#d8e2dc",
        slate: "#415a77",
      },
      boxShadow: {
        panel: "0 24px 60px rgba(23, 33, 33, 0.12)",
      },
      fontFamily: {
        display: ["Georgia", "Palatino Linotype", "serif"],
        body: ["Segoe UI", "Aptos", "sans-serif"],
      },
      backgroundImage: {
        grain:
          "radial-gradient(circle at 20% 20%, rgba(184, 75, 47, 0.12), transparent 28%), radial-gradient(circle at 80% 0%, rgba(62, 92, 77, 0.14), transparent 22%), linear-gradient(180deg, rgba(255,255,255,0.86), rgba(255,255,255,0.88))",
      },
    },
  },
  plugins: [],
};
