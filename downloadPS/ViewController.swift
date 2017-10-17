//
//  ViewController.swift
//  downloadPS
//
//  Created by Do Thanh Cong on 10/17/17.
//  Copyright © 2017 Do Thanh Cong. All rights reserved.
//

import Cocoa
import Alamofire
class ViewController: NSViewController {

    let gamesDbsLink = "https://docs.google.com/spreadsheets/d/18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs/export?format=tsv&id=18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs&gid=1180017671"
    
    let dlcsDbsLink = "https://docs.google.com/spreadsheets/d/18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs/export?format=tsv&id=18PTwQP7mlwZH1smpycHsxbEwpJnT8IwFP7YZWQT7ZSs&gid=743196745"
    
    var gameDb = [GameModel]()
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var downloadDBProgress: NSProgressIndicator!
    
    @IBOutlet weak var notice: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        if let item = getModelFromFile() {
//            gameDb = item
//            outlineView.reloadData()
//        }
        self.getModelFromInternet { (result, items) in
            if result {
                self.notice.isHidden = true
                self.downloadDBProgress.isHidden = true
                self.gameDb = items!
                self.outlineView.reloadData()
            }else{
                self.notice.stringValue = "Got errors when downloading. Please press command + R to reload"
            }
        }
        
    }
    
    func getModelFromInternet( completion: @escaping( (Bool, [GameModel]?) ->()) ) {
        Alamofire.request(gamesDbsLink,  method: .get)
            .downloadProgress { progress in
                self.downloadDBProgress.doubleValue = progress.fractionCompleted
            }
            .responseData { response in
                
                switch response.result {
                case .success:
                    if let data = response.result.value {
                        let dataString = String.init(data: data, encoding: .utf8)!
                        let myStrings = dataString.components(separatedBy: .newlines)
                        var models = [GameModel]()
                        for line in myStrings {
                            let myComponent = line.components(separatedBy: "\t")
                            for item in myComponent {
                                if item.caseInsensitiveCompare("missing") != ComparisonResult.orderedSame && item.lowercased().contains("http://") {
                                    let gameModel = GameModel()
                                    gameModel.name = "\(myComponent[0]) \(myComponent[1]) \(myComponent[2])"
                                    gameModel.url = myComponent[3]
                                    models.append(gameModel)
                                    break
                                }
                            }
                        }
                        completion(true, models)
                    }else{
                        completion(false, nil)
                    }
                    
                    break
                case .failure(let error):
                    print(error)
                    completion(false, nil)
                    break
                }
                
                
        }
    }
    func getModelFromFile() -> [GameModel]? {
        
        if let path = Bundle.main.path(forResource: "DatabaseGAMES", ofType: "tsv") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let myStrings = data.components(separatedBy: .newlines)
                var i = 1
                var models = [GameModel]()
                for line in myStrings {
                    //                    print("line \(i): \(line)")
                    i += 1
                    let myComponent = line.components(separatedBy: "\t")
                    //                    print("component: \(myComponent)")
                    for item in myComponent {
                        if item.caseInsensitiveCompare("missing") != ComparisonResult.orderedSame && item.lowercased().contains("http://") {
                            let gameModel = GameModel()
                            gameModel.name = "\(myComponent[0]) \(myComponent[1]) \(myComponent[2])"
                            gameModel.url = myComponent[3]
                            models.append(gameModel)
                            break
                        }
                    }
                }
                return models
            } catch {
                print(error)
                return nil
            }
        }else{
            return nil
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}


extension ViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return gameDb.count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return gameDb[index]
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}
extension ViewController:NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: cellGame?
        if let game = item as? GameModel {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CELLGAME"), owner: self) as? cellGame
            
            if let title = view?.cellTitle {
                title.stringValue = game.name
            }
            view?.cellLink = game.url
            
            
            
        }
        return view
    }
}
class cellGame: NSTableCellView {
    @IBOutlet weak var cellTitle: NSTextField!
    
    @IBAction func download(_ sender: Any) {
        print("Download link: \(cellLink)")
        let destination = DownloadRequest.suggestedDownloadDestination(for: .downloadsDirectory)

        Alamofire.download(cellLink, to: destination)
            .downloadProgress { progress in
                print("Download Progress: \(progress.fractionCompleted)")
                self.downloadProgress.doubleValue = progress.fractionCompleted
        }
    }
    @IBOutlet weak var downloadProgress: NSProgressIndicator!
    var cellLink: String = ""
}
