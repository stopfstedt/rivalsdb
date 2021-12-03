import { Magic } from "magic-sdk";
import type { App } from "./app";

const magic = new Magic("pk_live_1FB57945CEA1A727");

export async function afterSignin(app: App, did: string): Promise<void> {
  const meta = await magic.user.getMetadata();

  if (did && meta) {
    app.ports.signInReceiver.send({ token: did, user: meta.issuer });
    window.setTimeout(async () => {
      const newDid = await magic.user.getIdToken();
      afterSignin(app, newDid);
    }, 14 * 60 * 1000);
  }
}

export async function signInWithQueryCrendetials(app: App): Promise<void> {
  try {
    const did = await magic.auth.loginWithCredential();
    await afterSignin(app, did);
  } catch (e) {
    window.location.href = window.location.origin;
  }
}

export async function trySignInFromCache(app: App): Promise<void> {
  const isLoggedIn = await magic.user.isLoggedIn();
  if (isLoggedIn) {
    const did = await magic.user.getIdToken();
    await afterSignin(app, did);
  }
}

export async function preloadSigninModal(): Promise<void> {
  await magic.preload();
}

export async function signOut(): Promise<void> {
  await magic.user.logout();
}

export async function signIn(email: string): Promise<string> {
  const did = await magic.auth.loginWithMagicLink({
    email,
    redirectURI: window.location.origin,
  });
  return did;
}
