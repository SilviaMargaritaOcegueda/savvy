import { configureServerSideSIWE } from "connectkit-next-siwe";

export const siweServer = configureServerSideSIWE({
  session: {
    cookieName: "connectkit-next-siwe",
    password: process.env.NEXT_PUBLIC_SESSION_SECRET,
    cookieOptions: {
      secure: process.env.NODE_ENV === "production",
    },
  },
});