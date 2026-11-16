//
//  SensorDeMovimento.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

import CoreMotion
import UIKit

// le o acelerômetro e o giroscópio do iPhone usando o CoreMotion
@MainActor
final class SensorDeMovimento {
    private let gerenciador = CMMotionManager()
    private var ultimoChacoalho = Date.distantPast

    var aoMudarGravidade: ((CGVector) -> Void)?
    var aoChacoalhar: (() -> Void)?
    var aoBalancar: ((CGVector, TimeInterval) -> Void)?

    var temSensor: Bool {
        return gerenciador.isDeviceMotionAvailable
    }
    
    func iniciar() {
            guard temSensor else {
                aoMudarGravidade?(CGVector(dx: 0, dy: 1))
                return
            }

        // roda o sensor a 60 frames por segundo
            gerenciador.deviceMotionUpdateInterval = 1.0 / 60.0
            
            gerenciador.startDeviceMotionUpdates(to: .main) { [weak self] movimento, _ in
                guard let self, let movimento else { return }
                self.processar(movimento)
            }
        }

        func parar() {
            gerenciador.stopDeviceMotionUpdates()
        }
    
    private func processar(_ movimento: CMDeviceMotion) {
            // Tratamento da Gravidade
            // No CoreMotion, o eixo Y do acelerômetro aponta para CIMA
            // inverter o y é fundamental para uma boa finamica
            let g = movimento.gravity
            aoMudarGravidade?(CGVector(dx: g.x, dy: -g.y))

            // Detecção de Chacoalhar (Shake)
            // Medimos a aceleração pura gerada pela mão do usuário (descontando a gravidade constante).
            let a = movimento.userAcceleration

            // balançar repassa o movimento da mão
            if hypot(a.x, a.y) > 0.08 {
                aoBalancar?(CGVector(dx: a.x, dy: -a.y), gerenciador.deviceMotionUpdateInterval)
            }
            let intensidade = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            
            // Se a intensidade for alta
            if intensidade > 2.0, Date.now.timeIntervalSince(ultimoChacoalho) > 0.5 {
                ultimoChacoalho = .now
                // Dispara o chacoalhão nos planetas
                aoChacoalhar?()
            }
        }
    }
