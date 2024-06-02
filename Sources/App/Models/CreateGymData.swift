//
//  CreateGymData.swift
//
//
//  Created by Szabolcs Toth on 11.12.2023.
//

import Vapor

struct CreateGymData: Content {
    let name: String
    let coordinates: Coordinates
    let city: String
    let country: String
}
