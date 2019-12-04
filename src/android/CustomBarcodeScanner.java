package br.com.mbamobi;

import android.content.Intent;
import android.util.Log;

import com.google.zxing.integration.android.IntentIntegrator;
import com.google.zxing.integration.android.IntentResult;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class CustomBarcodeScanner extends CordovaPlugin {

    private CallbackContext callbackContext;

    private static final String TAG = "CustomBarcodeScanner";
    static String FORMATS = "formats";

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        Log.d(TAG, "Initializing CustomBarcodeScanner");
    }

    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        JSONObject options = args.optJSONObject(0);
        if (action.equals("scan")) {
            this.scanCode(options);
        }

        return true;
    }

    private void scanCode(JSONObject options) throws JSONException {

        this.cordova.setActivityResultCallback(this);

        List<String> formats = Collections.singletonList(IntentIntegrator.QR_CODE);

        if (options.has(FORMATS)) {
            JSONArray jsonArray = options.optJSONArray(FORMATS);
            formats = new ArrayList<String>();
            for (int i = 0; i < jsonArray.length(); i++) {
                formats.add(jsonArray.getString(i));
            }
        }

        IntentIntegrator integrator = new IntentIntegrator(this.cordova.getActivity());
        integrator.setDesiredBarcodeFormats(formats);
        integrator.setBeepEnabled(false);
        integrator.setCaptureActivity(ScannerActivity.class);
        integrator.setOrientationLocked(false);
        integrator.setPrompt(options.optString(ScannerActivity.PROMPT));
        integrator.addExtra(ScannerActivity.TORCH_ON, options.optBoolean(ScannerActivity.TORCH_ON, false));
        integrator.addExtra(ScannerActivity.TITLE, options.optString(ScannerActivity.TITLE, null));
        integrator.addExtra(ScannerActivity.JUMP_BUTTON, options.optBoolean(ScannerActivity.JUMP_BUTTON, false));
        integrator.addExtra(ScannerActivity.NEXT_BUTTON, options.optBoolean(ScannerActivity.NEXT_BUTTON, false));
        integrator.addExtra(ScannerActivity.SELECT_BUTTON, options.optBoolean(ScannerActivity.SELECT_BUTTON, false));
        integrator.addExtra(ScannerActivity.CUSTOM_BUTTON, options.optBoolean(ScannerActivity.CUSTOM_BUTTON, false));
        integrator.addExtra(ScannerActivity.CUSTOM_BUTTON_LABEL, options.optString(ScannerActivity.CUSTOM_BUTTON_LABEL, null));

        integrator.initiateScan();

    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (intent != null) {
            IntentResult result = IntentIntegrator.parseActivityResult(requestCode, resultCode, intent);

            if (result != null) {
                try {
                    callbackContext.success(result.getContents());
                } catch (Exception e) {
                    this.sendParseDataError();
                }
            } else {
                callbackContext.success("");
            }

        } else {
            if (ScannerActivity.JUMP_RESULT == resultCode) {
                callbackContext.success("jump");
            } else if (ScannerActivity.NEXT_RESULT == resultCode) {
                callbackContext.success("next");
            } else if (ScannerActivity.SELECT_RESULT == resultCode) {
                callbackContext.success("select");
            } else if (ScannerActivity.EXIT_RESULT == resultCode) {
                callbackContext.success("cancel");
            } else if (ScannerActivity.CUSTOM_RESULT == resultCode) {
                callbackContext.success("custom_result");
            }

            callbackContext.success("");
        }
    }

    private void sendParseDataError() {
        this.sendError("ZXing IntentIntegrator parse error");
    }

    private void sendError(String msg) {
        callbackContext.error(msg);
    }

    public void onBackPressed() {
        callbackContext.success("cancel");
    }

}
