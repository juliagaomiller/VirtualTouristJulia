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
    
    var editBtn: UIBarButtonItem!
    var doneBtn: UIBarButtonItem!
    var deleteMode = false
    
    override func viewDidLoad() {
        enableLongPress()
        editBtn = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "enableDelete")
        doneBtn = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "disableDelete")
        disableDelete()
    }
    
    func enableLongPress(){
        let longPress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPress.minimumPressDuration = 2.0
        map.addGestureRecognizer(longPress)
    }
    
    func addAnnotation(touch: UIGestureRecognizer){
        if touch.state == UIGestureRecognizerState.Began {
            let point = touch.locationInView(map)
            print("addAnnotation:", point)
            let coordinate = map.convertPoint(point, toCoordinateFromView: map)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.map.addAnnotation(annotation)
        }
    }
    
    func enableDelete(){
        deleteMode = true
        deleteLabel.hidden = false
        deleteView.hidden = false
        self.navigationItem.rightBarButtonItem = doneBtn
    }
    
    func disableDelete(){
        deleteMode = false
        deleteLabel.hidden = true
        deleteView.hidden = true
        self.navigationItem.rightBarButtonItem = editBtn
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Tapped the pin!")
        if (deleteMode) {
            self.map.removeAnnotation(view.annotation!)
        }
    }
    
}

