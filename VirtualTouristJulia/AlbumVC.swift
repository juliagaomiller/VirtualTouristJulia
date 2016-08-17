//  AlbumVC.swift
//  VirtualTouristJulia
//  Created by Julia Miller on 7/19/16.
//  Copyright © 2016 Julia Miller. All rights reserved.

//PTD - add to the NSFetchedResultsControllerDelegate; look @ other projects and replicate what they did. You went too adrift in your own explorations.

import Foundation
import UIKit
import CoreData
import MapKit

class AlbumVC: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadingLabel: UILabel!
    @IBOutlet weak var toolbarBtn: UIBarButtonItem!
    
    let newCollection = "New Collection"
    let removeSelected = "Remove Selected Pictures"
    
    var pin: Pin!
    
    var selectedIndexPaths = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
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
    
    @IBAction func toolbar(sender: AnyObject) {
        if sender.title == removeSelected {
            deleteSelectedPhotos()
            updateToolbarButton()
        }
        else {
            deleteAllAndDownloadTwelveNewImages()
        } //RemoveAllPhotos() and DownloadTwelveNewPhotos
    }
    
    func deleteSelectedPhotos(){
        for index in selectedIndexPaths {
            let photo = frc.objectAtIndexPath(index) as! Photo
            print("deleted: ", photo.url)
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager().sharedInstance().saveContext()
        fetchSavedPhotos()
        selectedIndexPaths = [NSIndexPath]()
        updateToolbarButton()
    }
    
    func deleteAllAndDownloadTwelveNewImages(){
        toolbarBtn.enabled = false
        collectionView.hidden = true
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
                
                self.collectionView.hidden = false
                self.downloadingLabel.hidden = true
                self.activityIndicator.hidden = true
                self.activityIndicator.stopAnimating()
                self.toolbarBtn.enabled = true
                
                print("Activity indicator and label should now be hidden")
                
                self.collectionView.reloadData()
            }
        }
    }
    
    func updateToolbarButton(){
        if selectedIndexPaths.count > 0 {
            toolbarBtn.title = removeSelected
        } else {toolbarBtn.title = newCollection}
    }
}

extension AlbumVC: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controllerWillChangeContent")
        insertedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("ControllerDidChangeContent")
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        print("controller, didChangeObject")
    }
    
}


extension AlbumVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        if let index = selectedIndexPaths.indexOf(indexPath) {
            selectedIndexPaths.removeAtIndex(index)
            updateToolbarButton()
            selectedCell.alpha = 1
        } else {
            selectedIndexPaths.append(indexPath)
            updateToolbarButton()
            selectedCell.alpha = 0.5
        }
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let x = (self.view.frame.width/2 - 10)
        return CGSize(width: x, height: x)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let x: CGFloat = 5
        return UIEdgeInsets(top: x, left: x, bottom: x, right: x)
    }
}
