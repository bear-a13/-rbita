//
//  SensorDeMovimento.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

// MARK: - Movimento/SensorDeMovimento.swift
import CoreMotion
import UIKit

/// Lê o acelerômetro e o giroscópio do iPhone usando o CoreMotion.
/// Não sabe que existem planetas: só entrega um vetor de gravidade e um aviso de chacoalhar.
@MainActor
final class SensorDeMovimento {
    private let gerenciador = CMMotionManager()
    private var ultimoChacoalho = Date.distantPast

    // Closures (callbacks) para avisar o UniversoViewController quando algo mudar
    var aoMudarGravidade: ((CGVector) -> Void)?
    var aoChacoalhar: (() -> Void)?
    /// Movimento da mão (sem a gravidade), em g, já no sistema da tela. Chamado 60×/s.
    var aoBalancar: ((CGVector, TimeInterval) -> Void)?

    /// Retorna falso se estiver rodando no Simulador (já que ele não tem sensores físicos de movimento).
    var temSensor: Bool {
        return gerenciador.isDeviceMotionAvailable
    }
    
    func iniciar() {
            // Se estivermos no Simulador do Mac, o sensor não existe.
            guard temSensor else {
                // "Modo simulador": definimos uma gravidade fixa apontando reto para baixo.
                aoMudarGravidade?(CGVector(dx: 0, dy: 1))
                return
            }

            // Quantas vezes por segundo o sensor vai atualizar (60 vezes por segundo = fluidez perfeita)
            gerenciador.deviceMotionUpdateInterval = 1.0 / 60.0
            
            // Começa a escutar o movimento na thread principal (.main)
            gerenciador.startDeviceMotionUpdates(to: .main) { [weak self] movimento, _ in
                guard let self, let movimento else { return }
                self.processar(movimento)
            }
        }

        func parar() {
            // Obrigatório ao sair da tela para economizar bateria e evitar bugs de processamento em segundo plano
            gerenciador.stopDeviceMotionUpdates()
        }
    
    private func processar(_ movimento: CMDeviceMotion) {
            // 1. Tratamento da Gravidade
            // No CoreMotion, o eixo Y do acelerômetro aponta para CIMA (como num gráfico matemático).
            // Na tela do iPhone, o eixo Y aponta para BAIXO. Por isso invertemos o sinal (-g.y).
            let g = movimento.gravity
            aoMudarGravidade?(CGVector(dx: g.x, dy: -g.y))

            // 2. Detecção de Chacoalhar (Shake)
            // Medimos a aceleração pura gerada pela mão do usuário (descontando a gravidade constante).
            let a = movimento.userAcceleration

            // Balançar: repassa o movimento da mão (ignora tremidinhas abaixo de 0.08 g).
            if hypot(a.x, a.y) > 0.08 {
                aoBalancar?(CGVector(dx: a.x, dy: -a.y), gerenciador.deviceMotionUpdateInterval)
            }
            let intensidade = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            
            // Se a intensidade for alta (> 2.0g) e já passou meio segundo desde o último chacoalho...
            if intensidade > 2.0, Date.now.timeIntervalSince(ultimoChacoalho) > 0.5 {
                ultimoChacoalho = .now
                aoChacoalhar?() // Dispara o chacoalhão nos planetas!
            }
        }
    }
