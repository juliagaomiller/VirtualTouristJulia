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
    @IBOutlet weak var navigationBtn: UIBarButtonItem!
    
    var deleteMode = false
    var allPhotosDownloaded = true
    
    let lat = "latitude"
    let long = "longitude"
    let latDelta = "latDelta"
    let longDelta = "longDelta"
    let savedMapRegion = "savedMapRegion"
    let activateDelete = "Edit"
    let deleteModeOn = "Done"
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager().sharedInstance().managedObjectContext
        }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fr = NSFetchRequest(entityName: "Pin")
        fr.sortDescriptors = []
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
        }()
    
    override func viewDidLoad() {
        map.delegate = self
        navigationBtn.title = activateDelete
        deleteView.hidden = true
        deleteLabel.hidden = true
        
        fetchResultsFromCoreData()
        loadMapRegion()
        retrieveAndPlaceSavedPins()
        addLongPressRecognizer()
    }
    
    @IBAction func rightNavigationBtn(sender: AnyObject) {
        if sender.title == activateDelete {
            navigationBtn.title = deleteModeOn
            deleteView.hidden = false
            deleteLabel.hidden = false
            deleteMode = true
        }
        else {
            navigationBtn.title = activateDelete
            deleteView.hidden = true
            deleteLabel.hidden = true
            deleteMode = false
            
        }
    }
    
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
                        } else if let country = pm.country {
                            annotation.title = String(country)
                            //PTD - print pm and check where ocean is located
                            //PTD - check pm and check how to write city and country of foreign country
                        } else if let ocean = pm.ocean {
                            annotation.title = String(ocean)
                        }
                        else {
                            annotation.title = "Unknown region."
                        }
                        let pin = Pin(lat: Double(coordinate.latitude), long: Double(coordinate.longitude), locName: annotation.title!, context: self.sharedContext)
                        Flickr.sharedInstance.retrieveParseAndSaveTwelveFlickrImages(pin, completionHandler: { (success, error) -> Void in
                            
                            if (!success) {
                                print("MapVC: ", error)
                                if error == Constants.noUrlsRetrieved {
                                    pin.error = error
                                }
                            } else {
                                print("MapVC: 12 photos have been downloaded and saved into Core Data")
                                self.allPhotosDownloaded = true
                            }
                        })
                        CoreDataStackManager().sharedInstance().saveContext()
                    }
                })
                self.map.addAnnotation(annotation)
            }
        }
    }
    
    func showAlertViewController(error: String) {
        let alert = UIAlertController(title: nil, message: error, preferredStyle: .Alert)
        if error == Constants.noUrlsRetrieved {
            let OKAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
            })
            alert.addAction(OKAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        if error == Constants.photosNotDoneDownloading {
            self.presentViewController(alert, animated: true, completion: nil)
            let delay = 1.0 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue(), {
                alert.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    func loadMapRegion(){
        guard let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey(savedMapRegion) as? [String:Double]
            else {
                print("MapVC: First time app launching.")
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
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        return annotationView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let pinTitle = view.annotation?.title!
        let pin: Pin? = searchAndFindSavedPinFromTitle(pinTitle!)
        if (allPhotosDownloaded){
            let albumVC = storyboard?.instantiateViewControllerWithIdentifier("AlbumVC") as! AlbumVC
            albumVC.pin = pin
            navigationController!.pushViewController(albumVC, animated: true)
        } else if (pin?.error != nil) {
            print("MapVC: The error variable in pin is not empty")
            showAlertViewController((pin?.error)!)
        } else {
            showAlertViewController(Constants.photosNotDoneDownloading)
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
            return pin
        }
        for x in fetchedPins {
            if title == x.title {
                pin = x
            }
        }
        return pin
    }
}

    


