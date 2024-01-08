import { immer } from "zustand/middleware/immer";

type State = {
  appActive: boolean;
  userAddress: string;
  userName: string;
  userAvatarUrl: string;
  modalElementId: string;
};

type Actions = {
  setAppActive: (isActive: boolean) => void;
  setUserAddress: (address: string) => void;
  setUserName: (name: string) => void;
  setUserAvatarUrl: (avatarUrl: string) => void;
  setModalElementId: (id: string) => void;
};

export default immer<State & Actions>((set) => ({
  appActive: false,
  userAddress: "",
  userName: "",
  userAvatarUrl: "",
  modalElementId: "",

  setAppActive: (isActive) =>
    set((state) => {
      state.appActive = isActive;
    }),

  setUserAddress: (address) =>
    set((state) => {
      state.userAddress = address;
    }),

  setUserName: (name) =>
    set((state) => {
      state.userName = name;
    }),

  setUserAvatarUrl: (avatarUrl) =>
    set((state) => {
      state.userAvatarUrl = avatarUrl;
    }),

  setModalElementId: (id) =>
    set((state) => {
      state.modalElementId = id;
    }),
}));
