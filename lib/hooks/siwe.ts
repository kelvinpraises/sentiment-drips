import { BrowserProvider } from "ethers";
import { SiweMessage } from "siwe";

const domain = typeof window !== "undefined" ? window.location.host : undefined;
const origin =
  typeof window !== "undefined" ? window.location.origin : undefined;
const provider =
  typeof window !== "undefined"
    ? new BrowserProvider((window as any).ethereum)
    : undefined;
const BACKEND_ADDR = "http://localhost:3002";

const useSIWE = () => {
  function disconnectWallet(callback: () => void) {
    fetch(`${BACKEND_ADDR}/logout`, {
      credentials: "include",
    }).then(() => callback());
  }

  function connectWallet(
    callback: ({
      name,
      address,
    }: {
      name: string;
      address: string;
      avatarUrl: string;
    }) => void
  ) {
    provider
      ?.send("eth_requestAccounts", [])
      .then(() => {
        signInWithEthereum().then((res) => {
          res
            ?.json()
            .then(
              (userData: {
                name: string;
                address: string;
                avatarUrl: string;
              }) => {
                callback(userData);
              }
            );
        });
      })
      .catch(() => console.log("user rejected request"));
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

  async function signInWithEthereum() {
    const signer = await provider?.getSigner();

    if (!signer) {
      return;
    }
    const message = await createSiweMessage(
      await signer.getAddress(),
      "Sign in with Ethereum to the app."
    );
    const signature = await signer.signMessage(message);

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

  function verifyAuthentication(callback: (res: Response) => void) {
    fetch(`${BACKEND_ADDR}/verifyAuthentication`, {
      credentials: "include",
    }).then((res) => {
      callback(res);
    });
  }

  return { connectWallet, disconnectWallet, verifyAuthentication };
};

export default useSIWE;
