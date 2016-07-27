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

import Foundation
import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    @IBOutlet weak var editBtn: UIBarButtonItem!
    var doneBtn: UIBarButtonItem!
    var locationArray = [[String: String]]()
    var deleteMode = false
    
    override func viewDidLoad() {
        map.delegate = self
        
        disableDelete()
        
        if NSUserDefaults.standardUserDefaults().objectForKey("locationArray") != nil {
            locationArray = NSUserDefaults.standardUserDefaults().objectForKey("locationArray") as! [[String:String]]
            for dictionary in locationArray {
                let lat = Double(dictionary["Latitude"]!)
                let long = Double(dictionary["Longitude"]!)
                let title = dictionary["LocName"]
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(lat!, long!)
                annotation.title = title
                
                self.map.addAnnotation(annotation)
            }
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        longPress.minimumPressDuration = 1
        map.addGestureRecognizer(longPress)
        
        doneBtn = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "disableDelete")
        
        //PTD - Load up map location from previous time map was closed.
    }
    
    func dropPin(touch: UIGestureRecognizer){
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
                        self.savePin(String(coordinate.latitude), long: String(coordinate.longitude), title: annotation.title!)
                    }
                })
                self.map.addAnnotation(annotation)
            }
        }
    }
    
    func savePin(lat: String, long: String, title: String){
        let locationDictionary = ["Latitude" : lat, "Longitude" : long, "LocName" : title]
        self.locationArray.append(locationDictionary)
                
        NSUserDefaults.standardUserDefaults().setObject(self.locationArray, forKey: "locationArray")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func enableDelete(sender: AnyObject) {
        deleteMode = true
        deleteLabel.hidden = false
        deleteView.hidden = false
        self.navigationItem.rightBarButtonItem = doneBtn
    }
    
    func disableDelete() {
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
            for (index, _) in locationArray.enumerate() {
                let title = locationArray[index]["LocName"]
                if selectedTitle == title!{
                    print("Index: ", index)
                    print(title)
                    locationArray.removeAtIndex(index)
                    NSUserDefaults.standardUserDefaults().setObject(locationArray, forKey: "locationArray")
                    NSUserDefaults().synchronize()
                    self.map.removeAnnotation(view.annotation!)
                    return
                }
            }
        }
    }

}

    


