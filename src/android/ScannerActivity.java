package br.com.mbamobi;

import android.app.Application;
import android.content.res.Resources;
import android.util.DisplayMetrics;

import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;

import com.journeyapps.barcodescanner.BarcodeView;
import com.journeyapps.barcodescanner.CaptureManager;
import com.journeyapps.barcodescanner.DecoratedBarcodeView;
import com.journeyapps.barcodescanner.Size;
import com.journeyapps.barcodescanner.camera.CameraManager;


public class ScannerActivity extends AppCompatActivity implements
    DecoratedBarcodeView.TorchListener {

    static String TORCH_ON = "torchOn";
    static String FORMATS = "formats";
    static String TITLE = "title";
    static String PROMPT = "prompt";
    static String JUMP_BUTTON = "jumpButton";
    static String NEXT_BUTTON = "nextButton";
    static String SELECT_BUTTON = "selectButton";
    static String CUSTOM_BUTTON = "customButton";
    static String CUSTOM_BUTTON_LABEL = "customButtonLabel";

    static int JUMP_RESULT = 77777;
    static int NEXT_RESULT = 88888;
    static int SELECT_RESULT = 99999;
    static int EXIT_RESULT = 66666;
    static int CUSTOM_RESULT = 12345;

    private DecoratedBarcodeView barcodeScannerView;
    private CaptureManager capture;

    private boolean isTorchOn = false;
    private Button switchFlashlightButton;
    private Button switchCameraButton;
    private Button jumpButton;
    private Button customButton;
    private Button selectButton;
    private ImageView nextButton;

    private boolean isJumpButton = false;
    private boolean isNextButton = false;
    private boolean isSelectButton = false;
    private boolean isCustomButton = false;
    private boolean haveButtons = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(getResourceIdentifier("activity_scanner", "layout"));
        Toolbar toolbar = findViewById(getResourceIdentifier("toolbar", "id"));
        setSupportActionBar(toolbar);
        String title = getIntent().getStringExtra(TITLE);
        getSupportActionBar().setTitle(title);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        toolbar.setNavigationIcon(getResourceIdentifier("close_camera","drawable"));
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                setResult(EXIT_RESULT);
                finish();
            }
        });


        //Initialize barcode scanner view
        barcodeScannerView = findViewById(getResourceIdentifier("zxing_barcode_scanner", "id"));
        calculateFrameSize(barcodeScannerView);

        getOptionProperties();
        setTorchButton();
        setSwitchCameraButton();
        setJumpButton();
        setSelectButton();
        setNextButton();
        setCustomButton();

        //start capture
        capture = new CaptureManager(this, barcodeScannerView);
        capture.initializeFromIntent(getIntent(), savedInstanceState);
        capture.decode();
    }

    private void getOptionProperties() {
        this.isJumpButton = getIntent().getBooleanExtra(JUMP_BUTTON, false);
        this.isNextButton = getIntent().getBooleanExtra(NEXT_BUTTON, false);
        this.isSelectButton = getIntent().getBooleanExtra(SELECT_BUTTON, false);
        this.isCustomButton = getIntent().getBooleanExtra(CUSTOM_BUTTON, false);
        this.haveButtons = this.isJumpButton && this.isNextButton && this.isSelectButton;
    }

    private void setJumpButton() {
        this.jumpButton = findViewById(getResourceIdentifier("jump_button", "id"));
        if(this.isJumpButton) {
            this.jumpButton.setVisibility(View.VISIBLE);
        }
    }

    private void setNextButton() {
        this.nextButton = findViewById(getResourceIdentifier("next_button", "id"));
        if(this.isNextButton) {
            this.nextButton.setVisibility(View.VISIBLE);
            this.jumpButton.setVisibility(View.INVISIBLE);
        }
    }

    private void setSelectButton() {
        this.selectButton = findViewById(getResourceIdentifier("select_button", "id"));
        if(this.isSelectButton) {
            this.selectButton.setVisibility(View.VISIBLE);

            if(this.isJumpButton) {
                Button jumpRightButton = findViewById(getResourceIdentifier("jump_right_button", "id"));
                this.jumpButton.setVisibility(View.INVISIBLE);
                jumpRightButton.setVisibility(View.VISIBLE);
            }
        }

    }

    private void setCustomButton() {
        this.customButton = findViewById(getResourceIdentifier("custom_button", "id"));
        String label = getIntent().getStringExtra(CUSTOM_BUTTON_LABEL);
        this.customButton.setText(label);
        if(this.isCustomButton) {
            this.customButton.setVisibility(View.VISIBLE);
        }
    }

    private void setTorchButton() {
        barcodeScannerView.setTorchListener(this);
        this.switchFlashlightButton = findViewById(getResourceIdentifier("switch_flashlight", "id"));
        if (hasFlash()){
            if (getIntent().getBooleanExtra(TORCH_ON, false)) {
                barcodeScannerView.setTorchOn();
            }
        } else {
            switchFlashlightButton.setVisibility(View.GONE);
        }
    }

    private void setSwitchCameraButton() {
        switchCameraButton = findViewById(getResourceIdentifier("switch_camera", "id"));
        if (!hasFrontalCamera()) switchCameraButton.setVisibility(View.GONE);
    }

    public void switchCamera(View view){
        int reqCamId = getIntent().getIntExtra("SCAN_CAMERA_ID", -1);
        getIntent().putExtra("SCAN_CAMERA_ID", reqCamId == 1 ? 0 : 1);
        recreate();
    }

    private boolean hasFlash() {
        return getApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH);
    }

    private boolean hasFrontalCamera() {
        return getApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH);
    }

    public void switchFlashlight(View view) {
        if (isTorchOn) barcodeScannerView.setTorchOff();
        else barcodeScannerView.setTorchOn();
    }

    public void jumpButtonClick(View view) {
        setResult(JUMP_RESULT);
        finish();
    }

    public void nextButtonClick(View view) {
        setResult(NEXT_RESULT);
        finish();
    }

    public void selectButtonClick(View view) {
        setResult(SELECT_RESULT);
        finish();
    }

    public void customButtonClick(View view) {
        setResult(CUSTOM_RESULT);
        finish();
    }

    @Override
    public void onTorchOn() {
        isTorchOn = true;
        switchFlashlightButton.setBackgroundResource(getResourceIdentifier("lightbulb_on", "drawable"));
    }

    @Override
    public void onTorchOff() {
        isTorchOn = false;
        switchFlashlightButton.setBackgroundResource(getResourceIdentifier("lightbulb_off", "drawable"));
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
        int height = (int) (displayMetrics.heightPixels * .80);
        Size size = new Size(width, height);

        int barcodeViewId = getResourceIdentifier("zxing_barcode_surface", "id");
        BarcodeView barcodeView = decoratedBarcodeView.findViewById(barcodeViewId);
        barcodeView.setFramingRectSize(size);
    }

}