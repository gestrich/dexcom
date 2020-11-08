//
//  DexcomCredentials.swift
//  
//
//  Created by Bill Gestrich on 11/7/20.
//

import Foundation

public struct DexcomCredentials: Codable {
    public let username: String
    public let password: String
    public let slackURL: URL
}
