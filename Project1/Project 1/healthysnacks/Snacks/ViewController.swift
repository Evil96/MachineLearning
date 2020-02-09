import UIKit
//To work with Vision we need to import this:
import CoreML
import Vision

class ViewController: UIViewController {
  
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var cameraButton: UIButton!
  @IBOutlet var photoLibraryButton: UIButton!
  @IBOutlet var resultsView: UIView!
  @IBOutlet var resultsLabel: UILabel!
  @IBOutlet var resultsConstraint: NSLayoutConstraint!

    //Page 60; Creating the request
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            //1
            let healthySnacks = HealthySnacks()
            //2
            let visionModel = try VNCoreMLModel(for: healthySnacks.model)
            //3
            let request = VNCoreMLRequest(model: visionModel, completionHandler: {
              [weak self] request, error in
                //print("Request is finished!", request.results)
                //Instead of just printing the results on console, lets see it
                //on the app itself:
                self?.processObservations(for: request, error: error)
            })
            //4
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }()
    
  var firstTime = true

  override func viewDidLoad() {
    super.viewDidLoad()
    cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    resultsView.alpha = 0
    resultsLabel.text = "choose or take a photo"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Show the "choose or take a photo" hint when the app is opened.
    if firstTime {
      showResultsView(delay: 0.5)
      firstTime = false
    }
  }
  
  @IBAction func takePicture() {
    presentPhotoPicker(sourceType: .camera)
  }

  @IBAction func choosePhoto() {
    presentPhotoPicker(sourceType: .photoLibrary)
  }

  func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    present(picker, animated: true)
    hideResultsView()
  }

  func showResultsView(delay: TimeInterval = 0.1) {
    resultsConstraint.constant = 100
    view.layoutIfNeeded()

    UIView.animate(withDuration: 0.5,
                   delay: delay,
                   usingSpringWithDamping: 0.6,
                   initialSpringVelocity: 0.6,
                   options: .beginFromCurrentState,
                   animations: {
      self.resultsView.alpha = 1
      self.resultsConstraint.constant = -10
      self.view.layoutIfNeeded()
    },
    completion: nil)
  }

  func hideResultsView() {
    UIView.animate(withDuration: 0.3) {
      self.resultsView.alpha = 0
    }
  }

  //Page 63; performing the request
  func classify(image: UIImage) {
    //1
    guard let ciImage = CIImage(image: image) else {
        print("Unable to create CIImage")
        return
    }
    //2
    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    //3
    //it is best to perform the request on a background queue, so as not to block the main thread
    DispatchQueue.global(qos: .userInitiated).async {
        //4
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        
        do{
            try handler.perform([self.classificationRequest])
        } catch {
            print("Failed to perform classification: \(error)")
        }
    }
  }
    
    func processObservations(for request: VNRequest, error: Error?){
        //1
        DispatchQueue.main.async {
            //2
            if let results = request.results as? [VNClassificationObservation]{
                //3
                if results.isEmpty{
                    self.resultsLabel.text = "nothing found"
                }else if results[0].confidence < 0.8{
                    self.resultsLabel.text = "Not Sure..."
                }else{
                    self.resultsLabel.text = String(format: "%@ %.1f%%", results[0].identifier, results[0].confidence * 100)
                }
                //4
            }else if let error = error{
                self.resultsLabel.text = "error: \(error.localizedDescription)"
            }else{
                self.resultsLabel.text = "???"
            }
            //5
            self.showResultsView()
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

	let image = info[.originalImage] as! UIImage
    imageView.image = image

    classify(image: image)
  }
}
