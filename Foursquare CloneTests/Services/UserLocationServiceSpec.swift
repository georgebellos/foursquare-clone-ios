//
//  UserLocationServiceSpec.swift
//  Foursquare CloneTests
//
//  Created by Fabio Hiroki on 11/10/17.
//  Copyright © 2017 Fabio Hiroki. All rights reserved.
//

import XCTest
import Swinject
import RxSwift
import CoreLocation

class UserLocationServiceSpec: XCTestCase {

    private var container: Container!
    private var locationManager: LocationManagerMock!
    private var userLocationService: UserLocationService!
    private let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()

        container = Container()
        container.register(LocationManager.self) { _ in LocationManagerMock() }
            .inObjectScope(.container)
        container.register(UserLocationService.self) { resolver in
            UserLocationService.init(locationManager: resolver.resolve(LocationManager.self)!)
        }

        locationManager = container.resolve(LocationManager.self)! as? LocationManagerMock
        userLocationService = container.resolve(UserLocationService.self)!
    }

    func testDependencyDelegateShouldBeWrapperClass() {
        XCTAssertTrue(locationManager.delegate === userLocationService)
    }

    func testShouldRequestUserPermission() {
        XCTAssertFalse(locationManager.calledRequestWhenInUseAuthorization)
        _ = userLocationService.getUserLocation()
        XCTAssertTrue(locationManager.calledRequestWhenInUseAuthorization)
    }

    func testShouldRequestLocation() {
        XCTAssertFalse(locationManager.calledRequestLocation)
        _ = userLocationService.getUserLocation()
        XCTAssertTrue(locationManager.calledRequestLocation)
    }

    func testShouldProvideLocation() {
        let mockLocation = CLLocation.init(latitude: -23.5666151, longitude: -46.6463977)
        let locationStream = userLocationService.getUserLocation()

        locationStream.subscribe(onNext: { (location) in
            XCTAssertEqual(mockLocation, location)
        }, onError: { (_) in
            XCTFail("Should not return error")
        }).disposed(by: disposeBag)

        locationManager.delegate?.locationManager!(CLLocationManager(), didUpdateLocations: [mockLocation])
    }

    func testShouldReturnErrorIfLocationManagerFail() {
        let mockError = NSError(domain: "Mock error", code: 42, userInfo: nil )
        let locationStream = userLocationService.getUserLocation()

        locationStream.subscribe(onNext: { (_) in
            XCTFail("Should return error")
        }, onError: { (error) in            
            if let err = error as? NSError {
                XCTAssertEqual(mockError, err)
            } else {
                XCTFail("error should be a NSError instance")
            }
        }).disposed(by: disposeBag)

        locationManager.delegate?.locationManager!(CLLocationManager(), didFailWithError: mockError)
    }
}
