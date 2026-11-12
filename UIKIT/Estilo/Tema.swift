// MARK: - Estilo/Tema.swift
import UIKit

/// Todas as cores do app num lugar só. Telas e componentes nunca escrevem cor solta.
enum Tema {
    // Botão "+" e destaques
    static let amareloPrincipal = UIColor(red: 1.00, green: 0.80, blue: 0.35, alpha: 1.0) // ~#FFCC59
    static let amareloSombra = UIColor(red: 0.75, green: 0.50, blue: 0.12, alpha: 1.0)    // base 3D do botão
    static let textoClaro = UIColor(red: 1.00, green: 0.90, blue: 0.66, alpha: 1.0)       // ~#FFE6A8

    // Sheet Nova/Editar (valores do Figma)
    static let fundoSheet = UIColor(hex: 0x946719)
    static let fundoCampo = UIColor(hex: 0x6E4C12)            // caixas de texto e fundo do x
    static let textoPlaceholder = UIColor(hex: 0xE3C68A)
    static let iconeFechar = UIColor(hex: 0xFFE19A)
    static let marromEscuro = UIColor(hex: 0x3A1E0C)          // ícone do check
    static let segmentoPadrao = UIColor(hex: 0x7E5815)
    static let segmentoSelecionado = UIColor(hex: 0x5E410F)
    static let textoSegmento = UIColor(hex: 0xF7E3B5)
    static let bordaSelecionada = UIColor(hex: 0xFFCC59)

    // Leque (azul-escuro)
    static let fundoControle = UIColor(hex: 0x1A2142)
    static let bordaControle = UIColor(hex: 0x3A4475)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
