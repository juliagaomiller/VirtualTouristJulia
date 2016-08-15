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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadingLabel: UILabel!
    @IBOutlet weak var newCollectionBtn: UIBarButtonItem!
    
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
        activityIndicator.hidden = true
        downloadingLabel.hidden = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupMap(pin.coordinate, span: 0.5)
        fetchSavedPhotos()
    }
    
    @IBAction func downloadTwelveNewPhotos(sender: AnyObject) {
        newCollectionBtn.enabled = false
//        collectionView.hidden = true
        downloadingLabel.hidden = false
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        for photo in frc.fetchedObjects! as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager().sharedInstance().saveContext()
        Flickr.sharedInstance.retrieveParseAndSaveTwelveFlickrImages(pin) { (success, error) -> Void in
            if error != "" {
                print("AlbumVC: Error retrieving twelve new photos.")
                return
            }
            else {
                print("AlbumVC: 12 new photos have been downloaded successfully")
                
                //then there is this looong pause before the collection view reappears an d
                //when i run through the code, it shows that
                
//                self.collectionView.hidden = false
                self.downloadingLabel.hidden = true
                self.activityIndicator.hidden = true
                self.activityIndicator.stopAnimating()
                self.newCollectionBtn.enabled = true
                
                print("Activity indicator and label should now be hidden")
                
                //why is there this loong pause before the statements above show on the simulator
                
                self.collectionView.reloadData()
                
                //the compiler runs throught the code but there is a looong pause before the simulator shows the collectionView is no longer hidden
                
                //collectionView.reloadData() works, but takes waay longer than it should.
                //On the other hand, if I segue back into the mapVC and then reload the AlbumVC, the new photos load up immediately.
                //Am brain stuck.
                
                //PTD USE THE NSFETCHEDRESULTSCONTROLLERDELEGATE instead; look at Mikael's project
            }
        }
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("AlbumVC: Clicked an image.")
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        selectedCell.imageView.image = nil
        selectedCell.activityIndicator.hidden = false
        selectedCell.activityIndicator.startAnimating()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //print("number of sections: ", (frc.sections?.count)!)
        return (frc.sections?.count)!
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfFrcObjects = frc.sections![section].numberOfObjects
        //print("number of items in section: ", section.numberOfObjects)
        return numberOfFrcObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AlbumVCCell", forIndexPath: indexPath) as! PhotoCell
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
        cell.activityIndicator.hidden = true
    }
}

extension AlbumVC: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let x = (self.view.frame.width/2 - 10)
        return CGSize(width: x, height: x)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let x: CGFloat = 5
        return UIEdgeInsets(top: x, left: x, bottom: x, right: x)
    }
}