import { Injectable } from '@angular/core';
import { Cordova, IonicNativePlugin, Plugin } from '@ionic-native/core';

@Plugin({
  pluginName: 'CustomBarcodeScanner',
  plugin: 'cordova-plugin-custom-scanner',
  pluginRef: 'CustomBarcodeScanner',
  repo: 'https://github.com/juliolemesti/custom-barcode-scanner',
  platforms: [ 'android', 'iOS' ]
})
@Injectable()
export class CustomBarcodeScanner extends IonicNativePlugin {
  
  @Cordova() scanQRcode(options: ScannerOptions): Promise<string> { return; }
  @Cordova() scanBarcode(options: ScannerOptions): Promise<any> { return; }
  
}

export interface ScannerOptions {
  torchOn: boolean;
}
