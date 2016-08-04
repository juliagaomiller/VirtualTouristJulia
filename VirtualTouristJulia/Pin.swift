import UIKit
import CoreData

@objc(Pin)
class Pin: NSManagedObject {
    
    @NSManaged var latitude:Double
    @NSManaged var longitude:Double
    @NSManaged var title:String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(lat: Double, long: Double, locName: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = lat
        self.longitude = long
        self.title = locName
        
    }
    
}
