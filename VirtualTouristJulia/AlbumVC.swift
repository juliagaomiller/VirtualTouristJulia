//  AlbumVC.swift
//  VirtualTouristJulia
//  Created by Julia Miller on 7/19/16.
//  Copyright © 2016 Julia Miller. All rights reserved.

import Foundation
import UIKit
import CoreData
import MapKit

class AlbumVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager().sharedInstance().managedObjectContext
    }()
    
    lazy var frc: NSFetchedResultsController = {
        let fr = NSFetchRequest(entityName: "Photo")
        fr.sortDescriptors = []
        fr.predicate = NSPredicate(format: "pin == %@", self.pin)
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        setupMap(pin.coordinate, span: 0.5)
        fetchSavedPhotos()
    }
    
    func setupMap(coordinate: CLLocationCoordinate2D, span: CLLocationDegrees){
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(span, span))
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.setRegion(region, animated: false)
        map.addAnnotation(annotation)
        map.userInteractionEnabled = false
    }
    func fetchSavedPhotos() {
        do {
            try frc.performFetch()
        }
        catch {
            abort()
        }
    }
    
    //NOT SURE WHAT THESE TWO DO
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return (frc.sections?.count)!
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = frc.sections![section]
        return section.numberOfObjects
    }

    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! PhotoCell
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: PhotoCell, indexPath: NSIndexPath){
        let photo = frc.objectAtIndexPath(indexPath) as! Photo
        guard let data = photo.imageData else {
            print("Photo has no saved imageData.")
            return
        }
        cell.imageView.image = UIImage(data: data)
        
    }
    
    
    
}