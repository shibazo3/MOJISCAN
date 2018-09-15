//
//  ViewController.swift
//  ocr
//
//  Created by tsubasa shibata on 2017/11/25.
//  Copyright © 2017年 tsubasa shibata. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextViewDelegate,UITextFieldDelegate {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var kurukuru: UIActivityIndicatorView!
    
    var googleApiKey = "AIzaSyBnMMg7gyCYH1xD8_gva606_locuaXRP3o"
    
    var list: [[String: Any]] = [
        ["title":"あいう",
         "text":"えおか",
         "image":Data()]
    ]
    
    let userDefText:String = "textdata"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Activity Indicator(ロード中のくるくる)
        kurukuru.isHidden = true
        
        
    }

    //フォトライブラリー
    @IBAction func selectImage(_ sender: Any) {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
                // 前回検出したテキストをクリアする
                text.text = ""
                // 写真を選ぶ
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                //トリミング
                picker.allowsEditing = true
                // カメラロールを表示
                picker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
                present(picker, animated: true, completion: nil)
            }
        }
    
    // カメラ起動
    @IBAction func cameraImage(_ sender: Any) {
        let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.camera
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            
            text.text = ""
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = .camera
            
            cameraPicker.delegate = self
            cameraPicker.allowsEditing = true
            
            present(cameraPicker, animated: true, completion: nil)
    }
}
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selected = info[UIImagePickerControllerEditedImage] as! UIImage
        // 選択した画像をUIImageViewに表示する際にアスペクト比を維持する
        image.contentMode = .scaleAspectFit
        image.image = selected
        //処理中表示にする
        text.text = "(文字を検出しています)"
        //カメラロール非表示にする
        dismiss(animated: true, completion: nil)
        //Vision APIを使う
        detectText()
        //kurukuru表示
        kurukuru.isHidden = false
        kurukuru.startAnimating()
    }
    
    enum DetectionMethod: String {
        case GOOGLE
    }
    var method = DetectionMethod.GOOGLE
    
    func detectText() {
        DetectionMethod.GOOGLE;
            png()
            jpeg()
        }
    
    func png() {
        // 画像はbase64する
        // PNG
        if let base64image = UIImagePNGRepresentation(image.image!)?.base64EncodedString() {
            // リクエストの作成
            // 文字検出をしたいのでtypeにはTEXT_DETECTIONを指定する
            
            let request: Parameters = [
                "requests": [
                    "image": [
                        "content": base64image
                    ],
                    "features": [
                        [
                            "type": "TEXT_DETECTION",
                            "maxResults": 1
                        ]
                    ]
                ]
            ]
          // Google Cloud PlatformのAPI Managerでキーを制限している場合、リクエストヘッダのX-Ios-Bundle-Identifierに指定した値を入れる
            let httpHeader: HTTPHeaders = [
                "Content-Type": "application/json",
                "X-Ios-Bundle-Identifier": Bundle.main.bundleIdentifier ?? "com.tsubasa.ocr"
            ]
            
            // googleApiKeyにGoogle Cloud PlatformのAPI Managerで取得したAPIキーを入れる
            Alamofire.request("https://vision.googleapis.com/v1/images:annotate?key=\(googleApiKey)", method: .post, parameters: request, encoding: JSONEncoding.default, headers: httpHeader).validate(statusCode: 200..<300).responseJSON { response in
                // レスポンスの処理
                self.googleResult(response: response)
            }
        }
        
    }
    func jpeg() {
        // 画像はbase64する
        //jpeg
        
        if let base64image = UIImageJPEGRepresentation(image.image!, CGFloat(100) )?.base64EncodedString(){
            // リクエストの作成
            // 文字検出をしたいのでtypeにはTEXT_DETECTIONを指定する
            
            let request: Parameters = [
                "requests": [
                    "image": [
                        "content": base64image
                    ],
                    "features": [
                        [
                            "type": "TEXT_DETECTION",
                            "maxResults": 1
                        ]
                    ]
                ]
            ]
            // Google Cloud PlatformのAPI Managerでキーを制限している場合、リクエストヘッダのX-Ios-Bundle-Identifierに指定した値を入れる
            let httpHeader: HTTPHeaders = [
                "Content-Type": "application/json",
                "X-Ios-Bundle-Identifier": Bundle.main.bundleIdentifier ?? "com.tsubasa.ocr"
            ]
            
            // googleApiKeyにGoogle Cloud PlatformのAPI Managerで取得したAPIキーを入れる
            Alamofire.request("https://vision.googleapis.com/v1/images:annotate?key=\(googleApiKey)", method: .post, parameters: request, encoding: JSONEncoding.default, headers: httpHeader).validate(statusCode: 200..<300).responseJSON { response in
                // レスポンスの処理
                self.googleResult(response: response)
            }
        }
        
    }
    
    func googleResult(response: DataResponse<Any>) {
        guard let result = response.result.value else {
            // レスポンスが空っぽだったりしたら終了
            return
        }
        let json = JSON(result)
        let annotations: JSON = json["responses"][0]["textAnnotations"]
        var detectedText: String = ""
        kurukuru.stopAnimating()
        kurukuru.isHidden = true
        // 結果からdescriptionを取り出して一つの文字列にする
        annotations.forEach { (_, annotation) in
            detectedText += annotation["description"].string!
        }
        // 結果を表示する
        text.text = detectedText
    }
    
    //キーボード閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //シェアボタン
    @IBAction func share(_ sender: Any) {
        //各種シェアのアラートを出す
        // 共有する項目
        let shareText = text.text
        let shareWebsite = NSURL(string: "")
        let shareImage = UIImage(named: "")
        
        let activityItems = [shareText, shareWebsite, shareImage] as [Any]
        
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        let excludedActivityTypes = [
            UIActivityType.postToFacebook,
            UIActivityType.postToTwitter,
            UIActivityType.message,
            UIActivityType.saveToCameraRoll,
            UIActivityType.print
        ]
        
        //activityVC.excludedActivityTypes = excludedActivityTypes
        
        // UIActivityViewControllerを表示
        self.present(activityVC, animated: true, completion: nil)
    }
    
    //保存ボタン
    @IBAction func save(_ sender: Any) {
        
// アラートの作成
        let alert = UIAlertController(title: "新規ファイル", message: "保存するテキストのタイトルを入力してください", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "保存", style: .default, handler: { (action: UIAlertAction) -> Void in
            //保存
            let textField = alert.textFields![0] as UITextField
        self.save()
        }))
        // 保存タイトルを入力するtextField
        alert.addTextField(configurationHandler: { (textField: UITextField) in
            textField.placeholder = "タイトル"
        })
        // アラートの表示
        present(alert, animated: true, completion: nil)
    }
    func save() {
    let userDefault = UserDefaults.standard
    userDefault.set(list, forKey: userDefText)
    
    }
    
}

