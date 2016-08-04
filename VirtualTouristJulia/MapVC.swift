//
//  MapVC.swift
//  VirtualTouristJulia
//
//  Created by Julia Miller on 7/19/16.
//  Copyright © 2016 Julia Miller. All rights reserved.

//PTD NEXT TIME: CREATE THE PIN.SWIFT FILE AND HAVE SO THAT THE ARRAY OF PIN[] IS SAVED IN CORE DATA 
//EVERY TIME A PIN IS PLACED, YOU SEND A REQUEST TO SAVE 9 IMAGES FROM FLICKR
//REREAD REQUIREMENTS
//TRY TO DUPLICATE CODE FROM OTHER PROJECTS AND EXPLAIN WHY IT WORKS. 
//SAVE PIN IN CORE DATA.
//RELOOK AT NOTES.
//IF THERE IS ANYTHING YOU DON'T UNDERSTAND IN THE OTHER PROJECT'S CODE, IT MEANS THAT YOUR FOUNDATIONAL KNOWLEDGE IS NOT STRONG ENOUGH. ALWAYS COMPARE 2 OTHER PROJECTS TO SEE SIMILARITIES AND LEARN THIS COMMON TRAITS.
//FILE OPEN RECENT.

//***********//
//SAVE PIN TITLE AND LAT AND LONG INTO CORE DATA INSTEAD OF NSUSERDEFAULTS, THEN CREATE THE FLICKR SEARCH

//PTD LEARNING - LEARN MORE ABOUT SHARED INSTANCES

import Foundation
import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    
    var doneBtn: UIBarButtonItem!
    var deleteMode = false
    
    override func viewDidLoad() {
        doneBtn = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "disableDelete")
        map.delegate = self

        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            abort()
        }
        
        disablePinDelete()
        retrieveAndPlaceSavedPins()
        addLongPressRecognizer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        //PTD - Save map state function.
    }
    
    func addLongPressRecognizer(){
        let longPress = UILongPressGestureRecognizer(target: self, action: "dropAndSavePin:")
        longPress.minimumPressDuration = 1
        map.addGestureRecognizer(longPress)
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager().sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fr = NSFetchRequest(entityName: "Pin")
        fr.sortDescriptors = []
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    func retrieveAndPlaceSavedPins() {
        
        let pins = fetchedResultsController.fetchedObjects as! [Pin]
        
        for pin in pins {
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(lat, long)
            annotation.title = pin.title
            self.map.addAnnotation(annotation)
        }
    }
    
    func dropAndSavePin(touch: UIGestureRecognizer){
        if (!deleteMode){
            if touch.state == UIGestureRecognizerState.Began {
                let point = touch.locationInView(map)
                let coordinate = map.convertPoint(point, toCoordinateFromView: map)
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
                
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemark, error) -> Void in
                    if error != nil {
                        print("MapVC59: Reverse Geocoder Error")
                        return
                    }
                    if placemark!.count > 0 {
                        let pm = placemark![0] as CLPlacemark
                        if pm.administrativeArea != nil && pm.locality != nil {
                            annotation.title = "\(pm.locality!), \(pm.administrativeArea!)"
                        } else {
                            annotation.title = "Unknown Location"
                            print("MapVC68: Pin is outside of U.S.")
                            //PTD - print pm and check where ocean is located
                            //PTD - check pm and check how to write city and country of foreign country
                        }
                        let pin = Pin(lat: Double(coordinate.latitude), long: Double(coordinate.longitude), locName: annotation.title!, context: self.sharedContext)
                        CoreDataStackManager().sharedInstance().saveContext()
                        
                    }
                })
                self.map.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func enableDelete(sender: AnyObject) {
        deleteMode = true
        deleteLabel.hidden = false
        deleteView.hidden = false
        self.navigationItem.rightBarButtonItem = doneBtn
    }
    
    func disablePinDelete() {
        deleteMode = false
        deleteLabel.hidden = true
        deleteView.hidden = true
        self.navigationItem.rightBarButtonItem = editBtn
        //print("MapVC105: The right bar button item is: ", self.navigationItem.rightBarButtonItem?.title)
        //PTD - Figure out why the edit button isn't showing back up again when you press Done.
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        if (!deleteMode){
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else { annotationView.canShowCallout = false }
        return annotationView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (!deleteMode){
            print("Segue into AlbumVC and pass view.title")
        }
    }
    
    //CURRENTLY THE APP WILL CRASH BECAUSE I DON'T HAVE THE CODE BELOW FIGURED OUT. AM TRYING OT FIGURE OUT HOW TO GET THE INDEX OF DICTIONARY
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if (deleteMode) {
            guard let selectedTitle = view.annotation!.title!
                else {
                    print("MapVC126-Error.")
                    return
                }
//            for (index, _) in locationArray.enumerate() {
//                let title = locationArray[index]["LocName"]
//                if selectedTitle == title!{
//                    print("Index: ", index)
//                    print(title)
//                    locationArray.removeAtIndex(index)
//                    NSUserDefaults.standardUserDefaults().setObject(locationArray, forKey: "locationArray")
//                    NSUserDefaults().synchronize()
//                    self.map.removeAnnotation(view.annotation!)
                    //PTD - CHANGE THIS TO CORE DATA. AND MAKE SURE IS REMOVED.
//                    return
//                }
//            }
        }
    }

}

    


