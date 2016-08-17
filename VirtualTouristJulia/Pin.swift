import UIKit
import CoreData
import MapKit

//@objc(Pin)
class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude:NSNumber
    @NSManaged var longitude:NSNumber
    @NSManaged var title:String?
    @NSManaged var error:String?
    
    convenience init(lat: Double, long: Double, locName: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = NSNumber(double: lat)
        self.longitude = NSNumber(double: long)
        self.title = locName
        
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        
    }
    
}
