// MARK: - Efeitos/EfeitoPoeira.swift
import UIKit

/// Explosão de poeira quando uma atividade é concluída.
/// Usa CAEmitterLayer (nativo do iOS): um "canhão" que solta muitas partículas pequenas.
@MainActor
enum EfeitoPoeira {

    /// Solta a poeira no centro do planeta, dentro de `container`, e se remove sozinha.
    static func explodir(em centro: CGPoint, diametro: CGFloat, cor: UIColor, dentroDe container: UIView) {
        let emissor = CAEmitterLayer()
        emissor.emitterPosition = centro
        emissor.emitterShape = .circle                // nasce do contorno de um círculo...
        emissor.emitterMode = .surface                // ...preenchendo a área toda
        emissor.emitterSize = CGSize(width: diametro, height: diametro)
        emissor.renderMode = .additive                // partículas sobrepostas brilham mais

        let particula = CAEmitterCell()
        particula.contents = imagemDaParticula().cgImage
        particula.birthRate = Float(diametro) * 4     // planeta maior = mais poeira
        particula.lifetime = 0.9
        particula.lifetimeRange = 0.3
        particula.velocity = diametro * 0.9
        particula.velocityRange = diametro * 0.5
        particula.emissionRange = .pi * 2             // para todos os lados
        particula.scale = 0.5
        particula.scaleRange = 0.3
        particula.scaleSpeed = -0.4                   // vai encolhendo
        particula.alphaSpeed = -1.1                   // vai sumindo
        particula.color = cor.cgColor

        emissor.emitterCells = [particula]
        container.layer.addSublayer(emissor)

        // Solta só uma rajada: depois de 0.12 s para de nascer partícula...
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            emissor.birthRate = 0
        }
        // ...e quando as últimas morrem, remove o emissor.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            emissor.removeFromSuperlayer()
        }
    }

    /// Um pontinho redondo desenhado em código (não precisa de asset).
    private static func imagemDaParticula() -> UIImage {
        let tamanho = CGSize(width: 10, height: 10)
        return UIGraphicsImageRenderer(size: tamanho).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: tamanho)).fill()
        }
    }
}
