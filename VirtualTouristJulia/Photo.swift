import UIKit
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var url: String
    @NSManaged var imageData: NSData
    @NSManaged var pin: Pin
    
    convenience init(urlString: String, context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.url = urlString
    }
    
    func getImageData() -> NSData {
        let imageNSURL = NSURL(string: url)
        self.imageData = NSData(contentsOfURL: imageNSURL!)!
        
        return imageData
    }
}