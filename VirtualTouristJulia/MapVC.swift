//
//  MapVC.swift
//  VirtualTouristJulia
//
//  Created by Julia Miller on 7/19/16.
//  Copyright © 2016 Julia Miller. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    @IBOutlet weak var editBtn: UIBarButtonItem!
    //var editBtn: UIBarButtonItem!
    var doneBtn: UIBarButtonItem!
    var locationArray = [[String: Double]]()
    var deleteMode = false
    
    override func viewDidLoad() {
        map.delegate = self
        
        disableDelete()
        
        if NSUserDefaults.standardUserDefaults().objectForKey("LocationArray") != nil {
            locationArray = NSUserDefaults.standardUserDefaults().objectForKey("LocationArray") as! [[String:Double]]
            for dictionary in locationArray {
                addAnnotation(dictionary["Latitude"]!, long: dictionary["Longitude"]!)
            }
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "getTouchCoord:")
        longPress.minimumPressDuration = 1.5
        map.addGestureRecognizer(longPress)
        
        //editBtn = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "enableDelete")
        doneBtn = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "disableDelete")
        
        //LOAD UP MAP LOCATION FROM NSUSERDEFAULTS
    }
    
    func getTouchCoord(touch: UIGestureRecognizer){
        if touch.state == UIGestureRecognizerState.Began {
            let point = touch.locationInView(map)
            let coordinate = map.convertPoint(point, toCoordinateFromView: map)
            
            let locationDictionary = ["Latitude" : coordinate.latitude, "Longitude" : coordinate.longitude]
            
            locationArray.append(locationDictionary)
            
            NSUserDefaults.standardUserDefaults().setObject(locationArray, forKey: "LocationArray")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            addAnnotation(coordinate.latitude, long: coordinate.longitude)
        }
    }
    
    func addAnnotation(lat: CLLocationDegrees, long: CLLocationDegrees){
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: long), completionHandler: { (placemark, error) -> Void in
            if error != nil {
                print("Reverse Geocoder Error")
                return
            }
            if placemark!.count > 0 {
                let pm = placemark![0] as CLPlacemark
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(lat, long)
                annotation.title = "\(pm.locality!), \(pm.administrativeArea!)"

                self.map.addAnnotation(annotation)
                
            }
        })
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
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        if (!deleteMode){
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        return annotationView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (!deleteMode){
            print("Segue into AlbumVC and pass view.title")
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if (deleteMode) {
            
            let lat = view.annotation!.coordinate.latitude
            let long = view.annotation!.coordinate.longitude
            
            print("Before delete: ", locationArray)
            
            for annotationDic in locationArray {
                var i = 0
                if lat == annotationDic["Latitude"]{
                    if long == annotationDic["Longitude"]{
                        print("index: ", i)
                        print(locationArray[i])
                        locationArray.removeAtIndex(i)
                        NSUserDefaults.standardUserDefaults().setObject(locationArray, forKey: "LocationArray")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    self.map.removeAnnotation(view.annotation!)
                        print("After delete: ", locationArray)
                        print("NSUserdefault: ", NSUserDefaults.standardUserDefaults().objectForKey("LocationArray"))
                        return
                    }
                }
                i++
            }
            
            
        }
//        for annotationDic in locationArray {
//            
//        }
    }

    
}

