import Foundation
import CoreData

typealias CompletionHandler = (success: Bool, error: String) -> Void

class Flickr {
    
    static let sharedInstance = Flickr()
    
    let sharedContext = CoreDataStackManager().sharedInstance().managedObjectContext
    let session = NSURLSession.sharedSession()
    
    //Why do the other coders return "NSURLSessionDataTask?"
    func retrieveParseAndSaveTwelveFlickrImages(pin: Pin, completionHandler: CompletionHandler) {
        
        let lat = String(pin.latitude)
        let long = String(pin.longitude)
        let pageNumber = String(arc4random_uniform(10))
        var urlString = Constants.FlickrURL
        urlString = urlString.stringByReplacingOccurrencesOfString("latitude", withString: lat)
        urlString = urlString.stringByReplacingOccurrencesOfString("longitude", withString: long)
        urlString = urlString.stringByReplacingOccurrencesOfString("pageNumber", withString: pageNumber)
        
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        let task = session.dataTaskWithRequest(request) {(data, response, error) -> Void in
            
            guard (error==nil) else {
                completionHandler(success: false, error: "There was an error with the NSURLRequest. Error: \(error)")
                return
            }
            guard let data = data else {
                completionHandler(success: false, error: "No data was printed from the the NSURLRequest.")
                return
            }
            var parsedData = [String: AnyObject]()
            do {
                parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String: AnyObject]
            } catch {
                print("Error parsing JSON data")
            }
            guard
                let photosDict = parsedData["photos"] as? [String: AnyObject],
                let photos = photosDict["photo"] as? [[String: AnyObject]] else {
                    print("Error parsing JSON data (2).")
                    return
            }
            print("number of urls retrieved: ", photos.count)
            for p in photos {
                guard let url = p["url_m"] as? String else {
                    print("Could not find 'url_m' in parsed data")
                    return
                }
                let imageData = self.getImageData(url)
                let _ = Photo(urlString: url, data: imageData, selectedPin: pin, context: self.sharedContext)
                CoreDataStackManager().sharedInstance().saveContext()
            }
            completionHandler(success: true, error: "")
        }
        task.resume()
        
    }
    
    func getImageData(urlString: String) -> NSData {
        let url = NSURL(string: urlString)
        let imageData = NSData(contentsOfURL: url!)!
        
        return imageData
    }
    
//    func downloadImageData(url: String, completionHandler: (imageData: NSData!, error: String) -> Void) {
//        let task = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: url)!) {(data, response, error) in
//            guard let data = data else {
//            completionHandler(imageData: nil, error: "Error downloading Flickr image: \(error)")
//                return
//            }
//            completionHandler(imageData: data, error: "")
//        }
//        task.resume()
//    }
    
    
    
}
