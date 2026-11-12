//
//  AparenciaPlaneta.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

import Foundation
import CoreGraphics

nonisolated enum AparenciaPlaneta: String, Codable, CaseIterable {
    case lua, terra, jupiter, marte, tita, saturno

    var nomeDoAsset: String { "planeta-\(rawValue)" }

    
    var escalaDaImagem: CGSize {
        switch self {
        case .saturno: return CGSize(width: 353.49 / 200, height: 269.77 / 200)
        default: return CGSize(width: 1, height: 1)
        }
    }

    
    /// Cor predominante do planeta (usada na poeira ao concluir).
    var corPrincipalHex: UInt32 {
        switch self {
        case .lua: return 0xC9CCD6
        case .terra: return 0x4A90D9
        case .jupiter: return 0xD9A066
        case .marte: return 0xD9573B
        case .tita: return 0x5FB3A1
        case .saturno: return 0xE8C27A
        }
    }

    var corDoTituloHex: UInt32 {
        switch self {
        case .lua: return 0x1E2236
        case .terra: return 0x061A30
        case .jupiter, .saturno: return 0x3A1E0C
        case .marte: return 0xFFFFFF
        case .tita: return 0x05221F
        }
    }
}
