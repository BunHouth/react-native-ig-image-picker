# react-native-ig-image-picker

## Getting started

`$ npm install react-native-ig-image-picker --save`

### Mostly automatic installation

`$ react-native link react-native-ig-image-picker`

## Usage
```javascript
import {showImagePicker, libraryPicker, videoPicker} from 'react-native-ig-image-picker';

const openPicker = async () => {
 const response = await showImagePicker({})
}
```

#### Picker options
```javascript
const defaultOption = {
  compressImageMaxWidth: 780,
  compressImageMaxHeight: 780,
  library: {
    maxNumberOfItems: 10,
    defaultMultipleSelection: false,
    minNumberOfItems: 1
  },
  video: {
    recordingTimeLimit: 60.0,
    libraryTimeLimit: 60,
    minimumTimeLimit: 3,
    trimmerMaxDuration: 60,
    trimmerMinDuration: 3
  },
  showsVideoTrimmer: true,
  showsPhotoFilters: true,
  usesFrontCamera: false
};
```
