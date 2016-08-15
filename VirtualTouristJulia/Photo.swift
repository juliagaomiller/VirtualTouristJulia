import UIKit
import CoreData

@objc(Photo)
class Photo: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var imageData: NSData?
    @NSManaged var pin: Pin
    
    convenience init(urlString: String?, data: NSData?, selectedPin: Pin, context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.url = urlString
        self.imageData = data
        self.pin = selectedPin
    }
}