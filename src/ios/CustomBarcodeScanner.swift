import AVFoundation

@objc(CustomBarcodeScanner)
class CustomBarcodeScanner : CDVPlugin, AVCaptureMetadataOutputObjectsDelegate, URLSessionDelegate {

    var callbackId: String?
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var isBinaryContent: Bool?
    var cancelButton: UIButton?
    var flashButton: UIButton?
    var switchCameraButton: UIButton?
    var actionButton: UIButton?
    var subTitle: UILabel?
    var navbar : UINavigationBar?
    var jumpButton: UIButton?
    var selectButton: UIButton?

    var currentCamera: Int = 0;
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?

    var options: NSDictionary?
    var usingFrontCamera: Bool = false;

    var flashImage: UIImage?
    var flashOffImage: UIImage?

    var previewLayer: AVCaptureVideoPreviewLayer!

    @objc(scan:)
    func scanBarcode(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId;
        self.doScan(options: command.argument(at: 0) as! NSDictionary);
    }

    func doScan(options: NSDictionary){
        self.options = options
        let view: UIView = self.webView.superview!

        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if (status == AVAuthorizationStatus.restricted) {
            self.sendResultFailure(error: nil)
            return
        } else if status == AVAuthorizationStatus.denied {
            self.sendResultFailure(error: nil)
            return
        }

        let availableVideoDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in availableVideoDevices {
            if (device as AnyObject).position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if (device as AnyObject).position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        // older iPods have no back camera
        if(backCamera == nil){
            currentCamera = 1
        }

        do {

            captureSession = AVCaptureSession()

            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input: AVCaptureDeviceInput
            input = try self.createCaptureDeviceInput()

            // Set the input device on the capture session.
            self.captureSession!.addInput(input)

            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession!.addOutput(captureMetadataOutput)

            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            let formats: NSArray = options.object(forKey: "formats") as! NSArray
            let format: NSString = formats.object(at: 0) as! NSString
            let captureObjectType = format == "QR_CODE" ? AVMetadataObject.ObjectType.qr : AVMetadataObject.ObjectType.interleaved2of5
            captureMetadataOutput.metadataObjectTypes = [captureObjectType]
            
            //GetParams
            let title:String = options.object(forKey: "title") as! String
            let prompt:String = options.object(forKey: "prompt") as! String
            let isJumpButton:Bool = options.object(forKey: "jumpButton") as! Bool
            let isNextButton:Bool = options.object(forKey: "nextButton") as! Bool
            let isSelectButton:Bool = options.object(forKey: "selectButton") as! Bool

            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer!.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)

            // Start video capture.
            captureSession!.startRunning()
            
            //Navbar
            addNavigationBar(title: title)
            
            //Subtitle
            subTitle = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 21))
            subTitle?.center = CGPoint(x: view.frame.size.width / 2, y: 85)
            subTitle?.textAlignment = .center
            subTitle?.text = prompt
            subTitle?.textColor = UIColor.white
            view.addSubview(subTitle!)

            let bundleUrl = Bundle.main.url(forResource: "CustomBarcodeScanner", withExtension: "bundle")
            let bundle = Bundle.init(url: bundleUrl!)

            let flashImagePath = bundle?.path(forResource: "lightbulb_on", ofType: "png")
            flashImage = UIImage.init(contentsOfFile: flashImagePath!)

            let flashOffImagePath = bundle?.path(forResource: "lightbulb_off", ofType: "png")
            flashOffImage = UIImage.init(contentsOfFile: flashOffImagePath!)

            flashButton = UIButton(frame: CGRect(x: view.frame.size.width - 40, y: 75, width: 25, height: 25))
            flashButton?.setImage(flashOffImage, for: .normal)
            flashButton?.addTarget(self, action: #selector(flashButtonAction), for: .touchUpInside)
            view.addSubview(flashButton!)

            switchCameraButton = UIButton(frame: CGRect(x: 20, y: 75, width: 25, height: 25))
            let switchImagePath = bundle?.path(forResource: "switch_camera", ofType: "png")
            let switchImage = UIImage.init(contentsOfFile: switchImagePath!)
            switchCameraButton?.setImage(switchImage, for: .normal)
            switchCameraButton?.addTarget(self, action: #selector(switchCameraButtonAction), for: .touchUpInside)
            view.addSubview(switchCameraButton!)
            
            //jumpButton
            if(isJumpButton) {
                jumpButton = UIButton(type: .custom)
                if(isSelectButton) {
                    jumpButton?.frame = CGRect(x: view.frame.size.width - 180, y: view.frame.size.height - 50, width: 230, height: 40)
                } else {
                   jumpButton?.frame = CGRect(x: (view.frame.size.width / 2) - 115, y: view.frame.size.height - 50, width: 230, height: 40)
                }
                let yourAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.white,
                    .underlineStyle: NSUnderlineStyle.single.rawValue]
                let attributeString = NSMutableAttributedString(string: "Pular passo", attributes: yourAttributes)
                jumpButton?.setAttributedTitle(attributeString, for: .normal)
                jumpButton?.addTarget(self, action: #selector(jumpButtonAction), for: .touchUpInside)
                view.addSubview(jumpButton!)
            }
            
            //SelectButton
            if(isSelectButton) {
                selectButton = UIButton(type: .custom)
                selectButton?.frame = CGRect(x: 5, y: view.frame.size.height - 50, width: 200, height: 40)
                let selectImagePath = bundle?.path(forResource: "select_list", ofType: "png")
                let selectImage = UIImage.init(contentsOfFile: selectImagePath!)
                selectButton?.setImage(selectImage, for: .normal)
                selectButton?.setTitle("Selecionar na lista", for: .normal)
                selectButton?.titleLabel!.font = UIFont(name: (selectButton?.titleLabel?.font.fontName)!, size: 14)
                selectButton?.imageEdgeInsets = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 20)
                selectButton?.addTarget(self, action: #selector(selectButtonAction), for: .touchUpInside)
                view.addSubview(selectButton!)
            }
            
            //NextButton
            if(isNextButton) {
                actionButton = UIButton(type: .custom)
                actionButton?.frame = CGRect(x: view.frame.size.width - 80, y: view.frame.size.height - 55, width: 50, height: 50)
                actionButton?.backgroundColor = #colorLiteral(red: 0.1725490196, green: 0.4, blue: 0.2, alpha: 1)
                let actWidth = actionButton?.bounds.size.width
                actionButton?.layer.cornerRadius = 0.5 * actWidth!
                actionButton?.clipsToBounds = true
                let nextImagePath = bundle?.path(forResource: "next_arrow", ofType: "png")
                let nextImage = UIImage.init(contentsOfFile: nextImagePath!)
                actionButton?.setImage(nextImage, for: .normal)
                actionButton?.imageEdgeInsets = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
                actionButton?.addTarget(self, action: #selector(nextButtonAction), for: .touchUpInside)
                view.addSubview(actionButton!)
            }
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            qrCodeFrameView?.layer.borderColor = #colorLiteral(red: 0.1725490196, green: 0.4, blue: 0.2, alpha: 1)
            qrCodeFrameView?.layer.borderWidth = 2
            qrCodeFrameView?.frame = CGRect(x: 30, y: 110, width: view.frame.size.width - 60, height: view.frame.size.height - 170)
            view.addSubview(qrCodeFrameView!)
            view.bringSubviewToFront(qrCodeFrameView!)

            let torchOn:Bool = options.object(forKey: "torchOn") as! Bool
            if (torchOn) {
                self.turnFlashOn()
            }

        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            self.sendResultFailure(error: error)
            return
        }
    }
    
    @objc func done() {
        
    }
    
    private func addNavigationBar(title:String){
        let view: UIView = self.webView.superview!
        let height: CGFloat = 40
        let statusBarHeight = UIApplication.shared.statusBarFrame.height;
        navbar = UINavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: UIScreen.main.bounds.width, height: height))
        navbar?.backgroundColor = #colorLiteral(red: 0.1725490196, green: 0.4, blue: 0.2, alpha: 1)
        navbar?.barTintColor = #colorLiteral(red: 0.1725490196, green: 0.4, blue: 0.2, alpha: 1)
        navbar?.isTranslucent = false;
        navbar?.delegate = self as? UINavigationBarDelegate
        
        let bundleUrl = Bundle.main.url(forResource: "CustomBarcodeScanner", withExtension: "bundle")
        let bundle = Bundle.init(url: bundleUrl!)
        
        let closeCameraButton = UIButton(type: .custom)
        let closeCameraPath = bundle?.path(forResource: "close_camera", ofType: "png")
        let closeCamera = UIImage.init(contentsOfFile: closeCameraPath!)
        closeCameraButton.frame = CGRect(x: 0.0, y: 0.0, width: 25, height: 25)
        closeCameraButton.setImage(closeCamera, for: .normal)
        closeCameraButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        let closeCameraButtonNav = UIBarButtonItem(customView: closeCameraButton)
        let currWidth = closeCameraButtonNav.customView?.widthAnchor.constraint(equalToConstant: 25)
        currWidth?.isActive = true
        let currHeight = closeCameraButtonNav.customView?.heightAnchor.constraint(equalToConstant: 25)
        currHeight?.isActive = true
        
        
        let navItem = UINavigationItem(title: title)
        navbar?.setItems([navItem], animated: false)
        navbar?.titleTextAttributes = [.foregroundColor: UIColor.white]
        navItem.leftBarButtonItem = closeCameraButtonNav
        view.addSubview(navbar!)
        
        let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        let statusBarColor = #colorLiteral(red: 0.1725490196, green: 0.4, blue: 0.2, alpha: 1)
        statusBarView.backgroundColor = statusBarColor
        view.addSubview(statusBarView)
    }

    func createCaptureDeviceInput() throws -> AVCaptureDeviceInput {
        var captureDevice: AVCaptureDevice
        if(currentCamera == 0){
            if(backCamera != nil){
                captureDevice = backCamera!
            } else {
                throw CaptureError.backCameraUnavailable
            }
        } else {
            if(frontCamera != nil){
                captureDevice = frontCamera!
            } else {
                throw CaptureError.frontCameraUnavailable
            }
        }
        let captureDeviceInput: AVCaptureDeviceInput
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            throw CaptureError.couldNotCaptureInput(error: error)
        }
        return captureDeviceInput
    }

    func getFrontCamera() -> AVCaptureDevice?{
        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)

        for device in videoDevices{
            if device.position == AVCaptureDevice.Position.front {
                return device
            }
        }
        return nil
    }

    func getBackCamera() -> AVCaptureDevice?{
        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)

        for device in videoDevices{
            if device.position == AVCaptureDevice.Position.back {
                return device
            }
        }
        return nil
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObject.ObjectType.qr || metadataObj.type == AVMetadataObject.ObjectType.interleaved2of5 {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            sendResultSuccess(msg: metadataObj.stringValue ?? "")
            self.stopCapture();

            return;
        }

        self.sendResultFailure(error: nil);
    }

    @objc(cancelButtonAction:)
      func cancelButtonAction(sender: UIButton!) {
        self.stopCapture()
        self.sendResultSuccess(msg: "cancel")
    }
    
    @objc(jumpButtonAction:)
    func jumpButtonAction(sender: UIButton!) {
        self.stopCapture()
        self.sendResultSuccess(msg: "jump")
    }
    
    @objc(selectButtonAction:)
    func selectButtonAction(sender: UIButton!) {
        self.stopCapture()
        self.sendResultSuccess(msg: "select")
    }
    
    @objc(nextButtonAction:)
    func nextButtonAction(sender: UIButton!) {
        self.stopCapture()
        self.sendResultSuccess(msg: "next")
    }

    @objc(flashButtonAction:)
    func flashButtonAction(sender: UIButton!) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
                flashButton?.setImage(flashOffImage, for: .normal)
            } else {
                self.turnFlashOn()
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }

    @objc(switchCameraButtonAction:)
    func switchCameraButtonAction(sender: UIButton!) {
        usingFrontCamera = !usingFrontCamera
        do{
            captureSession!.removeInput(captureSession!.inputs.first!)

            if(usingFrontCamera){
                let captureDevice = getFrontCamera()
                let captureDeviceInput1 = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession!.addInput(captureDeviceInput1)
            }else{
                let captureDevice = getBackCamera()
                let captureDeviceInput1 = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession!.addInput(captureDeviceInput1)
            }
        }catch{
            print(error.localizedDescription)
        }
    }

    func turnFlashOn(){
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: 1.0)
            flashButton?.setImage(flashImage, for: .normal)
        } catch {
            print(error)
        }
    }

    func stopCapture(){
        if(captureSession != nil) {captureSession!.stopRunning()}
        if(videoPreviewLayer != nil) {videoPreviewLayer!.removeFromSuperlayer()}
        if(cancelButton != nil) {cancelButton!.removeFromSuperview()}
        if(flashButton != nil) {flashButton!.removeFromSuperview()}
        if(switchCameraButton != nil) {switchCameraButton!.removeFromSuperview()}
        if(navbar != nil) {navbar!.removeFromSuperview()}
        if(actionButton != nil) {actionButton!.removeFromSuperview()}
        if(subTitle != nil) {subTitle!.removeFromSuperview()}
        if(jumpButton != nil) {jumpButton!.removeFromSuperview()}
        if(selectButton != nil) {selectButton!.removeFromSuperview()}

        captureSession = nil
        videoPreviewLayer = nil
        cancelButton = nil
        flashButton = nil
        switchCameraButton = nil
        navbar = nil
        actionButton = nil
        subTitle = nil
        jumpButton = nil
        selectButton = nil
    }

    func sendResultFailure(error: Error? = nil, msg: String = ""){
        var message: String
        if (error != nil){
            message = error.debugDescription
        } else {
            message = msg
        }

        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: message
        )

        sendResult(result: pluginResult!)
    }

    func sendResultSuccess(msg: String?){
        let message = msg ?? "Sucesso";
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: message
        )

        sendResult(result: pluginResult!)
    }

    func sendResultObject(data: Dictionary<String, Any>){
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: data
        )

        sendResult(result: pluginResult!)
    }

    func sendResult(result: CDVPluginResult){
        self.commandDelegate!.send(result, callbackId: self.callbackId!)
        dismiss()
    }

    func dismiss(){
        captureSession?.stopRunning()

        videoPreviewLayer?.removeFromSuperlayer()
        videoPreviewLayer = nil

        qrCodeFrameView?.removeFromSuperview()
        qrCodeFrameView = nil

        captureSession = nil
        currentCamera = 0
        frontCamera = nil
        backCamera = nil
    }

    enum CaptureError: Error {
        case backCameraUnavailable
        case frontCameraUnavailable
        case couldNotCaptureInput(error: NSError)
    }

}
