import {NativeModules} from "react-native";
const {IGImagePicker} = NativeModules;

const defaultOption = {
  showCamera: true,
  videoSinglePick: false,
  singlePickWithAutoComplete: false,
  imageOnly: false,
  videoOnly: false,
  maxCount: 5,
  columnCount: 4
};

export const showImagePicker = (options = {}) => {
  return IGImagePicker.openPicker({...defaultOption, ...options});
};

export const libaryPicker = options => {
  return IGImagePicker.openPicker({
    ...defaultOption,
    ...options,
    imageOnly: true
  });
};

export const videoPicker = options => {
  return IGImagePicker.openPicker({
    ...defaultOption,
    ...options,
    videoOnly: true
  });
};

export default {
  showImagePicker,
  libaryPicker,
  videoPicker
};
