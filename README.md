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

#### Picker IOS options
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

#### Picker Android options
```javascript
const defaultOption = {
  showCamera: true,
  videoSinglePick: false,
  singlePickWithAutoComplete: false,
  imageOnly: false,
  videoOnly: false,
  maxCount: 5,
  columnCount: 4
};
```

## RoadMap

- [x] IOS like instagram
- [x] Android like instagram 
- [ ] Moving android libary to [InsGallery](https://github.com/JessYanCoding/InsGallery)
- [ ] Demo repository
- [ ] Usage Documentation
