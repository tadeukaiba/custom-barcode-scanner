package br.com.mbamobi;

import android.app.Activity;
import android.app.Application;
import android.content.res.Resources;
import android.hardware.Camera;
import android.support.annotation.NonNull;
import android.util.DisplayMetrics;

import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Button;

import com.journeyapps.barcodescanner.BarcodeView;
import com.journeyapps.barcodescanner.CaptureManager;
import com.journeyapps.barcodescanner.DecoratedBarcodeView;
import com.journeyapps.barcodescanner.Size;
import com.journeyapps.barcodescanner.camera.CameraManager;


    public class ScannerActivity extends AppCompatActivity implements
        DecoratedBarcodeView.TorchListener {

    private CaptureManager capture;
    private DecoratedBarcodeView barcodeScannerView;
    private Button switchFlashlightButton;
    private boolean isFlashLightOn = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(getResourceIdentifier("activity_scanner", "layout"));
        Toolbar toolbar = findViewById(getResourceIdentifier("toolbar", "id"));
        setSupportActionBar(toolbar);

        //Initialize barcode scanner view
        barcodeScannerView = findViewById(getResourceIdentifier("zxing_barcode_scanner", "id"));
        calculateFrameSize(barcodeScannerView);

        //set torch listener
        barcodeScannerView.setTorchListener(this);

        //switch flashlight button
        switchFlashlightButton = (Button) findViewById(getResourceIdentifier("switch_flashlight", "id"));

        // if the device does not have flashlight in its camera,
        // then remove the switch flashlight button...
        if (!hasFlash()) {
            switchFlashlightButton.setVisibility(View.GONE);
        } else {
            switchFlashlightButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    switchFlashlight();
                }
            });
        }

        //start capture
        capture = new CaptureManager(this, barcodeScannerView);
        capture.initializeFromIntent(getIntent(), savedInstanceState);
        capture.decode();
    }


    /**
     * Check if the device's camera has a Flashlight.
     *
     * @return true if there is Flashlight, otherwise false.
     */
    private boolean hasFlash() {
        return getApplicationContext().getPackageManager()
                .hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH);
    }

    public void switchFlashlight() {
        if (isFlashLightOn) {
            barcodeScannerView.setTorchOff();
            isFlashLightOn = false;
        } else {
            barcodeScannerView.setTorchOn();
            isFlashLightOn = true;
        }

    }

    @Override
    public void onTorchOn() {
        switchFlashlightButton.setText(getResourceIdentifier("turn_off_flashlight", "string"));
    }

    @Override
    public void onTorchOff() {
        switchFlashlightButton.setText(getResourceIdentifier("turn_on_flashlight", "string"));
    }

    @Override
    protected void onResume() {
        super.onResume();
        capture.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        capture.onPause();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        capture.onDestroy();
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        capture.onSaveInstanceState(outState);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        return barcodeScannerView.onKeyDown(keyCode, event) || super.onKeyDown(keyCode, event);
    }

    private int getResourceIdentifier(String name, String type) {
        Application app = getApplication();
        String package_name = app.getPackageName();
        Resources resources = app.getResources();

        return resources.getIdentifier(name, type, package_name);
    }

    private void calculateFrameSize(DecoratedBarcodeView decoratedBarcodeView) {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);

        int width = (int) (displayMetrics.widthPixels * .90);
        int height = (int) (displayMetrics.heightPixels * .85);
        Size size = new Size(width, height);

        int barcodeViewId = getResourceIdentifier("zxing_barcode_surface", "id");
        BarcodeView barcodeView = decoratedBarcodeView.findViewById(barcodeViewId);
        barcodeView.setFramingRectSize(size);
    }

}