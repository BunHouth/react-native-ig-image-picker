package com.igimagepicker;

import com.facebook.react.bridge.PromiseImpl;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Callback;


import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.ypx.imagepicker.ImagePicker;
import com.ypx.imagepicker.bean.ImageItem;
import com.ypx.imagepicker.bean.MimeType;
import com.ypx.imagepicker.bean.PickerError;
import com.ypx.imagepicker.data.OnImagePickCompleteListener2;
import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import android.app.Activity;
import android.content.ContentResolver;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Build;
import android.webkit.MimeTypeMap;

import java.io.File;
import java.util.UUID;

public class IGImagePickerModule extends ReactContextBaseJavaModule {

    private static final String E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST";
    private static final String E_NO_IMAGE_DATA_FOUND = "E_NO_IMAGE_DATA_FOUND";
    private final ReactApplicationContext reactContext;
    private ResultCollector resultCollector = new ResultCollector();
    private RedBookPresenter redBookPresenter;
    private Compression compression = new Compression();
    private ReadableMap options;

    public IGImagePickerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.redBookPresenter = new RedBookPresenter();
    }


    @Override
    public String getName() {
        return "IGImagePicker";
    }

    private String getTmpDir(Activity activity) {
       String tmpDir = activity.getCacheDir() + "/react-native-ig-image-picker";
       new File(tmpDir).mkdir();

       return tmpDir;
   }

    private BitmapFactory.Options validateImage(String path) throws Exception {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        options.inPreferredConfig = Bitmap.Config.RGB_565;
        options.inDither = true;

        BitmapFactory.decodeFile(path, options);

        if (options.outMimeType == null || options.outWidth == 0 || options.outHeight == 0) {
            throw new Exception("Invalid image selected");
        }

        return options;
    }

    private void setConfiguration(final ReadableMap options) {
        this.options = options;
    }

    private void redBookPick(final ReadableMap options) {
        boolean isShowCamera = options.hasKey("showCamera") && options.getBoolean("showCamera") || true;
        boolean isVideoSinglePick = options.hasKey("videoSinglePick") && options.getBoolean("videoSinglePick") || false;
        boolean isSinglePickWithAutoComplete = options.hasKey("singlePickWithAutoComplete") && options.getBoolean("singlePickWithAutoComplete") || false;
        boolean isImageOnly = options.hasKey("imageOnly") && options.getBoolean("imageOnly") || false;
        boolean isVideoOnly = options.hasKey("videoOnly") && options.hasKey("videoOnly") || false;
        int maxCount = options.hasKey("maxCount") ? options.getInt("maxCount") : 5;
        int columnCount = options.hasKey("columnCount") ? options.getInt("columnCount") : 4;
        Set<MimeType> mimeTypes = new HashSet<>();
        if(!isVideoOnly && !isImageOnly) {
            mimeTypes.add(MimeType.JPEG);
            mimeTypes.add(MimeType.PNG);
            mimeTypes.add(MimeType.MP4);
            mimeTypes.add(MimeType.MKV);
        }

        if(isImageOnly) {
            mimeTypes.add(MimeType.JPEG);
            mimeTypes.add(MimeType.PNG);
        }

        if(isVideoOnly) {
            mimeTypes.add(MimeType.MP4);
            mimeTypes.add(MimeType.MKV);
        }

        runOnUiThread(() -> {
            if (getCurrentActivity() != null) {
                ImagePicker.withCrop(redBookPresenter)
                        .setMaxCount(maxCount)
                        .showCamera(isShowCamera)
                        .setSinglePickWithAutoComplete(isSinglePickWithAutoComplete)
                        .assignGapState(false)
                        .setColumnCount(columnCount)
                        .mimeTypes(mimeTypes)
                        .setVideoSinglePick(isVideoSinglePick)
                        .setMaxVideoDuration(120000L)
                        .setMinVideoDuration(5000L)
                        .pick(getCurrentActivity(), new OnImagePickCompleteListener2() {
                            @Override
                            public void onPickFailed(PickerError error) {
                                resultCollector.notifyProblem(String.valueOf(error.getCode()), error.getMessage());
                            }

                            @Override
                            public void onImagePickComplete(ArrayList<ImageItem> items) {

                                resultCollector.setWaitCount(items.size());
                                for (int i = 0; i < items.size(); i++) {
                                    ImageItem image = items.get(i);
                                    String uri = image.getCropUrl();
                                    if(image.getCropUrl() == null) {
                                        uri = image.getPath();
                                    }
                                    try {
                                        getAsyncSelection(getCurrentActivity(), uri, false);
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                }
                            }
                        });
            }
        });

    }


    private WritableMap getImage(String path) throws Exception {
        WritableMap image = new WritableNativeMap();

        if (path.startsWith("http://") || path.startsWith("https://")) {
            throw new Exception("Cannot select remote files");
        }
        BitmapFactory.Options original = validateImage(path);

        // if compression options are provided image will be compressed. If none options is provided,
        // then original image will be returned
//        File compressedImage = compression.compressImage(options, path, original);
//        String compressedImagePath = compressedImage.getPath();
        BitmapFactory.Options options = validateImage(path);
        long modificationDate = new File(path).lastModified();

        image.putString("path", "file://" + path);
        image.putInt("width", options.outWidth);
        image.putInt("height", options.outHeight);
        image.putString("mime", options.outMimeType);
        image.putInt("size", (int) new File(path).length());
        image.putString("modificationDate", String.valueOf(modificationDate));

        return image;
    }


    private void getAsyncSelection(final Activity activity, String uri, boolean isCamera) throws Exception {
        String path = uri;
        if (path == null || path.isEmpty()) {
            resultCollector.notifyProblem(E_NO_IMAGE_DATA_FOUND, "Cannot resolve asset path.");
            return;
        }

        String mime = getMimeType(path);
        if (mime != null && mime.startsWith("video/")) {
            getVideo(activity, path, mime);
            return;
        }

        resultCollector.notifySuccess(getImage(path));
    }

    private String resolveRealPath(Activity activity, Uri uri, boolean isCamera) throws IOException {
        String path;

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            path = RealPathUtil.getRealPathFromURI(activity, uri);
        } else {

            path = RealPathUtil.getRealPathFromURI(activity, uri);
        }

        return path;
    }

    private Bitmap validateVideo(String path) throws Exception {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        retriever.setDataSource(path);
        Bitmap bmp = retriever.getFrameAtTime();

        if (bmp == null) {
            throw new Exception("Cannot retrieve video data");
        }

        return bmp;
    }

    private void getVideo(final Activity activity, final String path, final String mime) throws Exception {
        validateVideo(path);
        final String compressedVideoPath = getTmpDir(activity) + "/" + UUID.randomUUID().toString() + ".mp4";

        new Thread(() -> compression.compressVideo(activity, options, path, compressedVideoPath, new PromiseImpl(new Callback() {
            @Override
            public void invoke(Object... args) {
                String videoPath = (String) args[0];

                try {
                    Bitmap bmp = validateVideo(videoPath);
                    long modificationDate = new File(videoPath).lastModified();

                    WritableMap video = new WritableNativeMap();
                    video.putInt("width", bmp.getWidth());
                    video.putInt("height", bmp.getHeight());
                    video.putString("mime", mime);
                    video.putInt("size", (int) new File(videoPath).length());
                    video.putString("path", "file://" + videoPath);
                    video.putString("modificationDate", String.valueOf(modificationDate));

                    resultCollector.notifySuccess(video);
                } catch (Exception e) {
                    resultCollector.notifyProblem(E_NO_IMAGE_DATA_FOUND, e);
                }
            }
        }, args -> {
            WritableNativeMap ex = (WritableNativeMap) args[0];
            resultCollector.notifyProblem(ex.getString("code"), ex.getString("message"));
        }))).run();
    }

    private String getMimeType(String url) {
        String mimeType = null;
        Uri uri = Uri.fromFile(new File(url));
        if (uri.getScheme().equals(ContentResolver.SCHEME_CONTENT)) {
            ContentResolver cr = this.reactContext.getContentResolver();
            mimeType = cr.getType(uri);
        } else {
            String fileExtension = MimeTypeMap.getFileExtensionFromUrl(uri
                    .toString());
            if (fileExtension != null) {
                mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileExtension.toLowerCase());
            }
        }
        return mimeType;
    }


    @ReactMethod
    public void openPicker(final ReadableMap options, final Promise promise) {
        final Activity activity = getCurrentActivity();

        if (activity == null) {
            promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist");
            return;
        }
        resultCollector.setup(promise, true);
        setConfiguration(options);
        redBookPick(options);
    }
}
