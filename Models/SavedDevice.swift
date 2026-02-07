//
//  SavedDevice.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

struct SavedDevice: Codable, Identifiable, Equatable {
  let id: UUID
  let name: String
  let ipAddress: String

  init(id: UUID = UUID(), name: String, ipAddress: String) {
    self.id = id
    self.name = name
    self.ipAddress = ipAddress
  }
}
