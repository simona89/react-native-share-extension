package com.alinz.parkerdan.shareextension;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.content.ContentUris;
import android.os.Environment;
import java.lang.Object;
import java.io.*;
import java.net.URI;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.widget.ImageView;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

public class RealPathUtil {
 public static String getRealPathFromURI(final Context context, final Uri uri) {

     final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;

     // DocumentProvider
     if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
         // ExternalStorageProvider
         if (isExternalStorageDocument(uri)) {
             final String docId = DocumentsContract.getDocumentId(uri);
             final String[] split = docId.split(":");
             final String type = split[0];

             if ("primary".equalsIgnoreCase(type)) {
                 return Environment.getExternalStorageDirectory() + "/" + split[1];
             }

             // TODO handle non-primary volumes
         }
         // DownloadsProvider
         else if (isDownloadsDocument(uri)) {

             final String id = DocumentsContract.getDocumentId(uri);
             final Uri contentUri = ContentUris.withAppendedId(
                     Uri.parse("content://downloads/public_downloads"), Long.valueOf(id));

             return getDataColumn(context, contentUri, null, null);
         }
         // MediaProvider
         else if (isMediaDocument(uri)) {
             final String docId = DocumentsContract.getDocumentId(uri);
             final String[] split = docId.split(":");
             final String type = split[0];

             Uri contentUri = null;
             if ("image".equals(type)) {
                 contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
             } else if ("video".equals(type)) {
                 contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
             } else if ("audio".equals(type)) {
                 contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
             }

             final String selection = "_id=?";
             final String[] selectionArgs = new String[] {
                     split[1]
             };

             return getDataColumn(context, contentUri, selection, selectionArgs);
         }
     }
     // MediaStore (and general)
     else if ("content".equalsIgnoreCase(uri.getScheme())) {

         // Return the remote address
         if (isGooglePhotosUri(uri))
             return uri.getLastPathSegment();
          
         String path=getDataColumn(context, uri, null, null);     
         return copyFile(uri,context,path);
     }
     // File
     else if ("file".equalsIgnoreCase(uri.getScheme())) {
         return uri.getPath();
     }

     return null;
 }

 /**
  * Get the value of the data column for this Uri. This is useful for
  * MediaStore Uris, and other file-based ContentProviders.
  *
  * @param context The context.
  * @param uri The Uri to query.
  * @param selection (Optional) Filter used in the query.
  * @param selectionArgs (Optional) Selection arguments used in the query.
  * @return The value of the _data column, which is typically a file path.
  */
 public static String getDataColumn(Context context, Uri uri, String selection,
         String[] selectionArgs) {

     Cursor cursor = null;
     final String column = "_data";
     final String[] projection = {
             column
     };

     try {
         cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                 null);
         if (cursor != null && cursor.moveToFirst()) {
             final int index = cursor.getColumnIndexOrThrow(column);
             return cursor.getString(index);
         }
     } finally {
         if (cursor != null)
             cursor.close();
     }
     return null;
 }


 /**
  * @param uri The Uri to check.
  * @return Whether the Uri authority is ExternalStorageProvider.
  */
 public static boolean isExternalStorageDocument(Uri uri) {
     return "com.android.externalstorage.documents".equals(uri.getAuthority());
 }

 /**
  * @param uri The Uri to check.
  * @return Whether the Uri authority is DownloadsProvider.
  */
 public static boolean isDownloadsDocument(Uri uri) {
     return "com.android.providers.downloads.documents".equals(uri.getAuthority());
 }

 /**
  * @param uri The Uri to check.
  * @return Whether the Uri authority is MediaProvider.
  */
 public static boolean isMediaDocument(Uri uri) {
     return "com.android.providers.media.documents".equals(uri.getAuthority());
 }

 /**
  * @param uri The Uri to check.
  * @return Whether the Uri authority is Google Photos.
  */
 public static boolean isGooglePhotosUri(Uri uri) {
     return "com.google.android.apps.photos.content".equals(uri.getAuthority());
 }
 
 public static String copyFile(Uri uri, Context context,String path) {

    String outputPath = context.getApplicationInfo().dataDir + "/sharedTemp/";
    String inputFile = path.substring(path.lastIndexOf('/')+1);
    try {
        String data="";
        InputStream input = context.getContentResolver().openInputStream(uri);
        if ( input != null ) {
            InputStreamReader inputStreamReader = new InputStreamReader(input);
            BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
            String receiveString = "";
            StringBuilder stringBuilder = new StringBuilder();

            while ( (receiveString = bufferedReader.readLine()) != null ) {
                stringBuilder.append(receiveString);
            }
            data= stringBuilder.toString();
            input.close();
        }
        File dir = new File(outputPath);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        File file = new File(outputPath, inputFile);

        FileOutputStream stream = new FileOutputStream(file);
        try {
            stream.write(data.getBytes());
        } finally {
            stream.close();
        }
    }
    catch (FileNotFoundException e){
        throw new Error();
    }
    catch (IOException e){
        throw new Error();
    }
    catch (Error e){
        throw new Error();
    }
    return(outputPath+inputFile);
  }
}
