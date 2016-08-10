import Foundation
import CoreData

typealias CompletionHandler = (success: Bool, error: String) -> Void

class Flickr {
    
    static let sharedInstance = Flickr()
    let session = NSURLSession.sharedSession()
    
    //Why do the other coders return "NSURLSessionDataTask?"
    func retrieveParseAndSaveFlickrImageData(pin: Pin, completionHandler: CompletionHandler) {
        
        let lat = String(pin.latitude)
        let long = String(pin.longitude)
        let pageNumber = String(arc4random_uniform(100))
        var urlString = Constants.FlickrURL
        urlString = urlString.stringByReplacingOccurrencesOfString("latitude", withString: lat)
        urlString = urlString.stringByReplacingOccurrencesOfString("longitude", withString: long)
        urlString = urlString.stringByReplacingOccurrencesOfString("pageNumber", withString: pageNumber)
        
        var JSONData: NSData!
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
            JSONData = data
            print("Data: ", data)
            print("Response: ", response)
            print("Error: ", error)
        }
        task.resume()
        
        var parsedData = [String: AnyObject]()
        do {
            //fatal error: unexpectedly found nil while unwrapping an Optional value
            parsedData = try NSJSONSerialization.JSONObjectWithData(JSONData, options: .AllowFragments) as! [String: AnyObject]
        } catch {
            print("Error parsing JSON data")
        }
        
        print("ParsedData: ", parsedData)
    }
    
    
    
}
