import { SiweMessage } from "siwe";
import { Address, createWalletClient, custom } from "viem";
import { sepolia } from "viem/chains";

interface UserData {
  name: string;
  address: string;
  avatarUrl: string;
}

const hasWindow = typeof window !== "undefined";

const domain = hasWindow ? window.location.host : undefined;
const origin = hasWindow ? window.location.origin : undefined;
const BACKEND_ADDR = "http://localhost:3002";

export const walletClient = createWalletClient({
  chain: sepolia,
  transport: custom(hasWindow ? (window as any).ethereum : null),
});

export function disconnectWallet(callback: () => void) {
  fetch(`${BACKEND_ADDR}/logout`, {
    credentials: "include",
  }).then(() => callback());
}

export async function connectWallet(callback: (data: UserData) => void) {
  await walletClient.switchChain({ id: sepolia.id });
  const [address] = await walletClient.requestAddresses();
  const res = await signInWithEthereum(address);
  const userData: UserData = await res?.json();
  callback(userData);
}

export async function verifyAuthentication(callback: (res: Response) => void) {
  const res = await fetch(`${BACKEND_ADDR}/verifyAuthentication`, {
    credentials: "include",
  });
  callback(res);
}

async function createSiweMessage(address: string, statement: string) {
  const res = await fetch(`${BACKEND_ADDR}/nonce`, {
    credentials: "include",
  });
  const message = new SiweMessage({
    domain,
    address,
    statement,
    uri: origin,
    version: "1",
    chainId: 1,
    nonce: await res.text(),
  });
  return message.prepareMessage();
}

async function signInWithEthereum(address: Address) {
  const message = await createSiweMessage(
    address,
    "Sign in with Ethereum to the app."
  );

  const signature = await walletClient.signMessage({
    account: address,
    message,
  });

  const res = await fetch(`${BACKEND_ADDR}/verify`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ message, signature }),
    credentials: "include",
  });

  return res;
}
