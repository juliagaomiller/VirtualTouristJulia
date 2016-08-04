import UIKit
import CoreData

//@objc(Pin)
class Pin: NSManagedObject {
    
    @NSManaged var latitude:NSNumber
    @NSManaged var longitude:NSNumber
    @NSManaged var title:String
    
    convenience init(lat: Double, long: Double, locName: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = NSNumber(double: lat)
        self.longitude = NSNumber(double: long)
        self.title = locName
        
    }
    
}
