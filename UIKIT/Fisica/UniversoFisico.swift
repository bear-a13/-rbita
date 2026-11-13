//
//  UniversoFisico.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//

// MARK: - Fisica/UniversoFisico.swift
import UIKit

/// Dono do UIDynamicAnimator. Não sabe o que é uma Atividade:
/// só recebe views e números (densidade, elasticidade).
@MainActor
final class UniversoFisico: NSObject {
    private let animator: UIDynamicAnimator
    
    // Os três "behaviors" principais do UIKit Dynamics
    private let gravidade = UIGravityBehavior()
    private let colisao = UICollisionBehavior()
    
    /// Guarda as propriedades de peso/borracha de cada planeta separado,
    /// porque densidade e elasticidade valem para TODOS os itens de um mesmo behavior.
    private var propriedades: [ObjectIdentifier: UIDynamicItemBehavior] = [:]

    private var arrasto: UIAttachmentBehavior?
    private weak var itemArrastado: UIView?

    /// Avisa quem estiver ouvindo que um planeta BATEU com força (0...1).
    /// A física não vibra o celular: quem decide isso é a tela.
    var aoBater: ((CGFloat) -> Void)?
    /// Última batida de cada planeta, para não vibrar 60 vezes por segundo quando ele "assenta".
    private var ultimaBatida: [ObjectIdentifier: Date] = [:]

    // Recebe a view principal da tela (o "universo") para calcular o espaço físico
    init(referencia: UIView) {
        animator = UIDynamicAnimator(referenceView: referencia)
        super.init()
        colisao.collisionDelegate = self
        
        // Define a gravidade padrão apontando para baixo (eixo Y positivo)
        gravidade.gravityDirection = CGVector(dx: 0, dy: 1)
        
        // Liga a gravidade e a colisão no motor
        animator.addBehavior(gravidade)
        animator.addBehavior(colisao)
    }
    // MARK: - Planetas

        func adicionar(_ item: UIView, densidade: CGFloat, elasticidade: CGFloat) {
            gravidade.addItem(item)
            colisao.addItem(item)

            let comportamento = UIDynamicItemBehavior(items: [item])
            comportamento.density = densidade
            comportamento.elasticity = elasticidade
            comportamento.friction = 0.2
            comportamento.resistance = 0.4        // freio "do ar": evita que voem sem parar
            comportamento.allowsRotation = false  // Regra do Órbita: o texto nunca fica de cabeça para baixo
            
            animator.addBehavior(comportamento)
            propriedades[ObjectIdentifier(item)] = comportamento
        }

        /// Tire o planeta de TODOS os behaviors antes de animar o sumiço dele.
        func remover(_ item: UIView) {
            if itemArrastado === item { terminarArrasto(velocidade: .zero) }
            gravidade.removeItem(item)
            colisao.removeItem(item)
            ultimaBatida[ObjectIdentifier(item)] = nil
            if let comportamento = propriedades.removeValue(forKey: ObjectIdentifier(item)) {
                animator.removeBehavior(comportamento)
            }
        }

        // MARK: - Mundo

        /// Chame sempre que o layout mudar (viewDidLayoutSubviews).
        /// As colisões devem respeitar as margens seguras (sem o planeta sumir embaixo do notch/ilha).
        func atualizarLimites(margens: UIEdgeInsets, obstaculos: [CGRect]) {
            colisao.setTranslatesReferenceBoundsIntoBoundary(with: margens)
            colisao.removeAllBoundaries()
            for (indice, retangulo) in obstaculos.enumerated() {
                colisao.addBoundary(withIdentifier: "obstaculo-\(indice)" as NSString,
                                    for: UIBezierPath(ovalIn: retangulo))
            }
        }
    

    /// Muda a direção da gravidade. Vetor de tamanho 1 = gravidade "normal" (1000 pt/s²).
    /// Ex.: (0, 1) = para baixo; (1, 0) = para a direita. Na Etapa 7 o CoreMotion manda esse vetor.
    func definirGravidade(_ direcao: CGVector) {
        gravidade.gravityDirection = direcao
    }

    /// Chacoalhão: um empurrão instantâneo em direção aleatória para cada planeta.
    func impulsionarTodos(forca: CGFloat = 2) {
        for item in colisao.items {
            let empurrao = UIPushBehavior(items: [item], mode: .instantaneous)
            empurrao.angle = .random(in: 0..<(2 * .pi))
            empurrao.magnitude = forca
            // Um push instantâneo só age uma vez; depois disso tiramos ele do motor.
            empurrao.action = { [weak animator, weak empurrao] in
                guard let empurrao, !empurrao.active else { return }
                animator?.removeBehavior(empurrao)
            }
            animator.addBehavior(empurrao)
        }
    }

    /// Balançar o celular: cada planeta "fica para trás" por inércia.
    /// `aceleracao` vem em g (1 = gravidade da Terra) já no sistema da tela; `intervalo` em segundos.
    func balancar(aceleracao: CGVector, intervalo: TimeInterval, forca: CGFloat = 2.5) {
        // 1 g no UIKit Dynamics ≈ 1000 pt/s². Inércia = velocidade no sentido CONTRÁRIO.
        let ganho = 1000 * forca * CGFloat(intervalo)
        let delta = CGPoint(x: -aceleracao.dx * ganho, y: -aceleracao.dy * ganho)
        for comportamento in propriedades.values {
            for item in comportamento.items where item !== itemArrastado {
                comportamento.addLinearVelocity(delta, for: item)
            }
        }
    }

    // MARK: - Batidas (para a vibração)

    private func registrarBatida(_ item: UIDynamicItem) {
        guard let comportamento = propriedades[ObjectIdentifier(item)] else { return }
        let v = comportamento.linearVelocity(for: item)
        let velocidade = hypot(v.x, v.y)
        guard velocidade > 180 else { return } // encostar devagar não vibra

        let id = ObjectIdentifier(item)
        if let ultima = ultimaBatida[id], Date.now.timeIntervalSince(ultima) < 0.12 { return }
        ultimaBatida[id] = .now
        aoBater?(min(1, velocidade / 1500))
    }

    // MARK: - Arrastar e arremessar

    /// Prende o planeta ao dedo com uma "corda" de tamanho zero.
    func comecarArrasto(_ item: UIView, ponto: CGPoint) {
        terminarArrasto(velocidade: .zero)
        let deslocamento = UIOffset(horizontal: ponto.x - item.center.x,
                                    vertical: ponto.y - item.center.y)
        let ligacao = UIAttachmentBehavior(item: item,
                                           offsetFromCenter: deslocamento,
                                           attachedToAnchor: ponto)
        ligacao.length = 0
        animator.addBehavior(ligacao)
        arrasto = ligacao
        itemArrastado = item
    }

    /// O dedo andou: move a ponta da corda, e a física puxa o planeta junto.
    func moverArrasto(para ponto: CGPoint) {
        arrasto?.anchorPoint = ponto
    }

    /// Soltou o dedo: corta a corda e arremessa com a velocidade do gesto.
    func terminarArrasto(velocidade: CGPoint) {
        guard let ligacao = arrasto else { return }
        animator.removeBehavior(ligacao)
        arrasto = nil
        if let item = itemArrastado, let comportamento = propriedades[ObjectIdentifier(item)] {
            comportamento.addLinearVelocity(velocidade, for: item)
        }
        itemArrastado = nil
    }
}

// MARK: - UICollisionBehaviorDelegate

extension UniversoFisico: UICollisionBehaviorDelegate {
    /// Planeta bateu numa parede (bordas da tela ou botão "+").
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        registrarBatida(item)
    }

    /// Planeta bateu em outro planeta: conta o mais rápido dos dois.
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: UIDynamicItem,
                           with item2: UIDynamicItem, at p: CGPoint) {
        registrarBatida(item1)
        registrarBatida(item2)
    }
}
