//
//  MapViewController.swift
//  BasicMap
//
//  Created by Purbo Mohamad on 2017/03/29.
//  Copyright © 2017 Geocore. All rights reserved.
//

import UIKit
import MapKit

class PlaceAnnotation: MKPointAnnotation {
    
    var place: GeocorePlace
    
    init(place: GeocorePlace) {
        self.place = place
        super.init()
        
        self.coordinate = CLLocationCoordinate2DMake(Double(place.point!.latitude!), Double(place.point!.longitude!))
        self.title = place.name
    }
    
}

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var mapInitialized = false
    var userLocationInitialized = false
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var annotationsRef = [String:  PlaceAnnotation]()
    
    let defaultCenter = (35.658581, 139.745433) // Tokyo Tower
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.showsUserLocation = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - MKMapViewDelegate
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if !mapInitialized {
            mapInitialized = true
            let region = mapView.regionThatFits(
                MKCoordinateRegionMakeWithDistance(
                    CLLocationCoordinate2DMake(defaultCenter.0, defaultCenter.1),
                    1000, 1000))
            mapView.setRegion(region, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !userLocationInitialized {
            userLocationInitialized = true
            if let location = mapView.userLocation.location {
                debugPrint("user located: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let halfSpanLat = mapView.region.span.latitudeDelta/2.0
        let halfSpanLon = mapView.region.span.longitudeDelta/2.0
        
        let minLat = mapView.region.center.latitude - halfSpanLat
        let minLon = mapView.region.center.longitude - halfSpanLon
        let maxLat = mapView.region.center.latitude + halfSpanLat
        let maxLon = mapView.region.center.longitude + halfSpanLon
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        // Fetch stations within the current map bounds
        // station is tagged with "TAG-TEST-1-EKIDATA"
        GeocorePlaceQuery()
            .withRectangle(
                minimumLatitude: minLat,
                minimumLongitude: minLon,
                maximumLatitude: maxLat,
                maximumLongitude: maxLon)
            .with(tagIds: ["TAG-TEST-1-EKIDATA"])
            .withinRectangle()
            .then { places -> Void in
                
                debugPrint("[INFO] \(places.count) fetched")
                
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                // remove previous annotation if they went out of view
                var toBeRemoved = [PlaceAnnotation]()
                
                for (_, annotation) in self.annotationsRef {
                    if Double(annotation.place.point!.latitude!) < minLat || Double(annotation.place.point!.latitude!) > maxLat || Double(annotation.place.point!.longitude!) < minLon || Double(annotation.place.point!.longitude!) > maxLon {
                        toBeRemoved.append(annotation)
                    }
                }
                
                for annotation in toBeRemoved {
                    self.annotationsRef.removeValue(forKey: annotation.place.id!)
                }
                self.mapView.removeAnnotations(toBeRemoved)
                
                for place in places {
                    //debugPrint("-----> \(place.id)")
                    if self.annotationsRef[place.id!] == nil {
                        let annotation = PlaceAnnotation(place: place)
                        self.mapView.addAnnotation(annotation)
                        self.annotationsRef[place.id!] = annotation
                    }
                }
            }
            .catch { error in
                
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                print("[ERROR] Error fetching places: \(error)")
            }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let placeAnnotation = annotation as? PlaceAnnotation {
            
            if let pin = mapView.dequeueReusableAnnotationView(withIdentifier: "StationPin") {
                pin.annotation = annotation
                return pin
            } else {
                let pin = MKPinAnnotationView(annotation: placeAnnotation, reuseIdentifier: "StationPin")
                pin.isDraggable = false
                pin.canShowCallout = true
                return pin
            }
        }
        return nil
    }

}
