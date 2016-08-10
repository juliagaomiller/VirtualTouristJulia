//  AlbumVC.swift
//  VirtualTouristJulia
//  Created by Julia Miller on 7/19/16.
//  Copyright © 2016 Julia Miller. All rights reserved.


import Foundation
import UIKit
import CoreData
import MapKit

class AlbumVC: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin?
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager().sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fr = NSFetchRequest(entityName: "Photo")
        fr.sortDescriptors = []
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    override func viewDidLoad() {
        //PTD - Set map to stationary
    }
    
    
    
    
}