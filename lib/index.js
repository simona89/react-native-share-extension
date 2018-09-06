import { NativeModules, Platform } from "react-native";

export default {
  data(groupId) {
    if (Platform.OS === "ios")
      return NativeModules.ReactNativeShareExtension.data(groupId);
    else return NativeModules.ReactNativeShareExtension.data();
  },

  close(groupId) {
    if (Platform.OS === "ios")
    return NativeModules.ReactNativeShareExtension.close(groupId);
    else return NativeModules.ReactNativeShareExtension.close();
  }
};
