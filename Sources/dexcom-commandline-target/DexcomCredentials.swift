//
//  DexcomCredentials.swift
//  
//
//  Created by Bill Gestrich on 11/7/20.
//

import Foundation

struct DexcomCredentials: Codable {
    let username: String
    let password: String
    let slackURL: URL
}
