//
//  ViewController.swift
//  MapKitDemo
//
//  Created by Karthik Rajan T  on 10/09/20.
//  Copyright © 2020 Karthik Rajan T . All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var points = [CLLocationCoordinate2D]()
    var selectedRow = Set<Int>()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPress(_:)))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)
        locationManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showUserLocation() {
        mapView.showsUserLocation = !mapView.isUserLocationVisible
    }
    
    func requestUserAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    @objc func mapLongPress(_ recognizer: UIGestureRecognizer) {
        
        print("A long press has been detected.")
        
        let touchedAt = recognizer.location(in: self.mapView)
        let touchedAtCoordinate : CLLocationCoordinate2D = mapView.convert(touchedAt, toCoordinateFrom: self.mapView)
        
        let newPin = MKPointAnnotation()
        newPin.coordinate = touchedAtCoordinate
        mapView.addAnnotation(newPin)
        
        
    }
    func handleTap(gestureReconizer: UILongPressGestureRecognizer) {
        
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func localSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "location"
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                if let res = response {
                    for local in res.mapItems {
                        print(local.name ?? "")
                        self.mapView.addAnnotation(local.placemark)
                    }
                }
            }
        }
    }
    
    func centerMap() {
        
        if let location = locationManager.location {
            var region = MKCoordinateRegion()
            region.center.latitude = location.coordinate.latitude
            region.center.longitude = location.coordinate.longitude
            region.span.longitudeDelta = 0.005
            
            mapView.region = region
        }
    }
    
    func requestDirectionsTo(source : CLLocationCoordinate2D, destination : CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                if let routes = response?.routes {
                    for route in routes {
                        print(route.distance)
                        self.mapView.addOverlays([route.polyline])
                    }
                }
            }
        }
    }
    
    func mapCamera(userCoordinate: CLLocationCoordinate2D, eyeCoordinate : CLLocationCoordinate2D) {
        let mapCamera = MKMapCamera(lookingAtCenter: userCoordinate, fromEyeCoordinate: eyeCoordinate, eyeAltitude: 800.0)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = userCoordinate
        mapView.addAnnotation(annotation)
        mapView.setCamera(mapCamera, animated: true)
    }
    
    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let userLocation:CLLocation = locations[0] as CLLocation
        let myAnnotation: MKPointAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
        myAnnotation.title = "Current location"
        mapView.addAnnotation(myAnnotation)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            let position :CGPoint = touch.location(in: view)
            let coord = mapView.convert(position, toCoordinateFrom: self.view)
            points.append(coord)
            
            if selectedRow.contains(3) {
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                ann.title = "Meu Pin"
                mapView.addAnnotation(ann)
            }
            
            if selectedRow.contains(4) {
                mapView.addOverlays([MKCircle(center: coord, radius: CLLocationDistance(integerLiteral: 50))])
            }
            
            if selectedRow.contains(5) {
                if points.count == 3 {
                    let pol = MKPolygon(coordinates: points, count: 3)
                    mapView.addOverlays([pol])
                }
            }
            
            if selectedRow.contains(6) {
                if points.count == 4 {
                    let poline = MKPolyline(coordinates: points, count: 4)
                    mapView.addOverlays([poline])
                }
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.green
            circleRenderer.alpha = 0.3
            circleRenderer.strokeColor = UIColor.black
            circleRenderer.lineWidth = 2
            return circleRenderer
        }
        
        if let overlay = overlay as? MKPolygon {
            let poly = MKPolygonRenderer(overlay: overlay)
            poly.fillColor = UIColor.brown
            poly.alpha = 0.2
            return poly
        }
        
        if let overlay = overlay as? MKPolyline {
            let poly = MKPolylineRenderer(overlay: overlay)
            poly.strokeColor = getRandomColor()
            poly.lineWidth = 3
            return poly
        }
        
        if let overlay = overlay as? MKTileOverlay {
            let poly = MKTileOverlayRenderer(overlay: overlay)
            poly.alpha = 0.5
            return poly
        }
        
        return MKCircleRenderer()
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
            
            let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
            
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            let sourceAnnotation = MKPointAnnotation()
            
            if let location = sourcePlacemark.location {
                sourceAnnotation.coordinate = location.coordinate
            }
            
            let destinationAnnotation = MKPointAnnotation()
            
            if let location = destinationPlacemark.location {
                destinationAnnotation.coordinate = location.coordinate
            }
            
            self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
            
            let directionRequest = MKDirections.Request()
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            
            directions.calculate {
                (response, error) -> Void in
                
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    
                    return
                }
                
                let route = response.routes[0]
                
                self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
                
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
            
            renderer.lineWidth = 5.0
            
            return renderer
        }
        
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let ac = UIAlertController(title: "Aviso", message: "Você tocou no Pin!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    
}
