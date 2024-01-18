"use client";

import * as React from "react";
import "@/styles/globals.css";
import type { AppProps } from "next/app";

import { WagmiConfig, createConfig } from "wagmi";
import { ConnectKitProvider, ConnectKitButton, getDefaultConfig } from "connectkit";


const config = createConfig(
  getDefaultConfig({
    alchemyId: process.env.NEXT_PUBLIC_ALCHEMY_ID || "", 
    walletConnectProjectId: process.env.NEXT_PUBLIC_PROJECT_ID || "",
    appName: "Savvy",
    appDescription: "DeFi for Teens",
    appUrl: "https://savvy.vercel.app", 
    appIcon: "/logo.png",
  }),
);

export default function App({ Component, pageProps }: AppProps) {
  return <WagmiConfig config={config}>
          <ConnectKitProvider>
      <Component {...pageProps} /> </ConnectKitProvider>
    </WagmiConfig>;
}
