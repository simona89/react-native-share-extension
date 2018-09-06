import { NativeModules, Platform } from "react-native";

export default {
  data(groupId) {
    if (Platform.OS === "ios")
      NativeModules.ReactNativeShareExtension.data(groupId);
    else NativeModules.ReactNativeShareExtension.data();
  },

  close(groupId) {
    if (Platform.OS === "ios")
      NativeModules.ReactNativeShareExtension.close(groupId);
    else NativeModules.ReactNativeShareExtension.close();
  }
};
