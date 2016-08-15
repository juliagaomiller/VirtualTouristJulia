//
//  MapVC.swift
//  VirtualTouristJulia
//
//  Created by Julia Miller on 7/19/16.
//  Copyright © 2016 Julia Miller. All rights reserved.

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
    var allPhotosDownloaded = true
    
    let lat = "latitude"
    let long = "longitude"
    let latDelta = "latDelta"
    let longDelta = "longDelta"
    let savedMapRegion = "savedMapRegion"
    
    override func viewDidLoad() {
        doneBtn = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "disablePinDelete")
        map.delegate = self
        
        fetchResultsFromCoreData()
        loadMapRegion()
        disablePinDelete()
        retrieveAndPlaceSavedPins()
        addLongPressRecognizer()
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
    
    func fetchResultsFromCoreData(){
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            abort()
        }
    }
    
    
    func addLongPressRecognizer(){
        let longPress = UILongPressGestureRecognizer(target: self, action: "dropAndSavePin:")
        longPress.minimumPressDuration = 1
        map.addGestureRecognizer(longPress)
    }
    
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
        self.allPhotosDownloaded = false
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
                        Flickr.sharedInstance.retrieveParseAndSaveTwelveFlickrImages(pin, completionHandler: { (success, error) -> Void in
                            
                            if (error != "") {
                                //print the error
                            }
                            else if (success) {
                                print("12 photos have been downloaded and saved into Core Data")
                                self.allPhotosDownloaded = true
                                //send to album vc that 'busy activity indicator' doesn't need to be activated and that all the images can be directly loaded.
                            }
                        })
                        
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
    
    func loadMapRegion(){
        guard let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey(savedMapRegion) as? [String:Double]
            else {
                print("First time app launching.")
                return
        }
        let region = MKCoordinateRegion(
            center:CLLocationCoordinate2DMake(savedRegion[lat]!, savedRegion[long]!),
            span: MKCoordinateSpan(latitudeDelta: savedRegion[latDelta]!, longitudeDelta: savedRegion[longDelta]!)
        )
        self.map.setRegion(region, animated: false)
    }
    
    func saveMapRegion(){
        let region = self.map.region
        NSUserDefaults.standardUserDefaults().setObject([
            lat : region.center.latitude,
            long : region.center.longitude,
            latDelta : region.span.latitudeDelta,
            longDelta : region.span.longitudeDelta
            ], forKey: savedMapRegion)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        if (!deleteMode){
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else { annotationView.canShowCallout = false }    //TACTIC DOESN'T WORK. canShowCallout doesn't disable the annotation view when delete mode is on.
        return annotationView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (allPhotosDownloaded){
            let albumVC = storyboard?.instantiateViewControllerWithIdentifier("AlbumVC") as! AlbumVC
            let pinTitle = view.annotation?.title!
            //print(pinTitle)
            albumVC.pin = searchAndFindSavedPinFromTitle(pinTitle!)
            //print(albumVC.pin.title)
            navigationController!.pushViewController(albumVC, animated: true)
        } else {
            print("photos haven't finished downloading yet!")
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if (deleteMode) {
            let selectedTitle = view.annotation?.title!
            let pin = searchAndFindSavedPinFromTitle(selectedTitle!)
            sharedContext.deleteObject(pin!)
            CoreDataStackManager().sharedInstance().saveContext()
            map.removeAnnotation(view.annotation!)
        }
    }
    
    func searchAndFindSavedPinFromTitle(title: String) -> Pin? {
        var pin: Pin?
        fetchResultsFromCoreData()
        guard let fetchedPins = fetchedResultsController.fetchedObjects as? [Pin] else {
            print("Fetched objects is still empty")
            return pin
        }
        for x in fetchedPins {
            if title == x.title {
                print (x.title)
                pin = x
            }
        }
        return pin
    }
}

    


