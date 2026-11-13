//
//  PlanetaView.swift
//  UIKIT
//
//  Created by Bernardo on 13/11/26.
//
import UIKit

@MainActor
protocol PlanetaViewDelegate: AnyObject {
    func planetaFoiTocado(_ planeta: PlanetaView)
    func planetaFoiTocadoDuasVezes(_ planeta: PlanetaView)
    func planeta(_ planeta: PlanetaView, arrastou gesto: UIPanGestureRecognizer)
}

final class PlanetaView: UIView {
    let atividadeID: UUID
    weak var delegate: PlanetaViewDelegate?

    private let imagem = UIImageView()
    private let rotulo = UILabel()
    //muito importante para a fisica determinando o foramto circular
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType { .ellipse }

    init(atividadeID: UUID, titulo: String, nomeDoAsset: String,
         diametro: CGFloat, escalaDaImagem: CGSize = CGSize(width: 1, height: 1),
         corDoTitulo: UIColor = .white, tamanhoDoTitulo: CGFloat = 15) {
        
        self.atividadeID = atividadeID
        
        // O frame inicial é SÓ a bola (o diâmetro).
        super.init(frame: CGRect(x: 0, y: 0, width: diametro, height: diametro))
        
        configurarVisual(titulo: titulo, nomeDoAsset: nomeDoAsset,
                         diametro: diametro, escalaDaImagem: escalaDaImagem,
                         corDoTitulo: corDoTitulo, tamanhoDoTitulo: tamanhoDoTitulo)
        configurarGestos()
        configurarAcessibilidade(titulo: titulo)
    }

    required init?(coder: NSCoder) { fatalError("PlanetaView é criada só por código") }
    
    private func configurarVisual(titulo: String, nomeDoAsset: String,
                                      diametro: CGFloat, escalaDaImagem: CGSize,
                                      corDoTitulo: UIColor, tamanhoDoTitulo: CGFloat) {
            
            clipsToBounds = false

            imagem.image = UIImage(named: nomeDoAsset)
            imagem.contentMode = .scaleAspectFit
            
            let tamanho = CGSize(width: diametro * escalaDaImagem.width,
                                 height: diametro * escalaDaImagem.height)
            
            imagem.frame = CGRect(x: (diametro - tamanho.width) / 2,
                                  y: (diametro - tamanho.height) / 2,
                                  width: tamanho.width, height: tamanho.height)
            addSubview(imagem)

            rotulo.text = titulo
            rotulo.numberOfLines = 2
            rotulo.textAlignment = .center
            rotulo.adjustsFontSizeToFitWidth = true
            rotulo.minimumScaleFactor = 0.6
            rotulo.textColor = corDoTitulo
            rotulo.font = .systemFont(ofSize: tamanhoDoTitulo, weight: .semibold)
            
            rotulo.layer.shadowColor = UIColor.black.cgColor
            rotulo.layer.shadowOpacity = 0.25
            rotulo.layer.shadowRadius = 2
            rotulo.layer.shadowOffset = CGSize(width: 0, height: 1)
            
            rotulo.frame = bounds.insetBy(dx: diametro * 0.14, dy: diametro * 0.3)
            rotulo.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(rotulo)
        }
    private func configurarGestos() {
            let duplo = UITapGestureRecognizer(target: self, action: #selector(tocouDuasVezes))
            duplo.numberOfTapsRequired = 2

            let simples = UITapGestureRecognizer(target: self, action: #selector(tocouUmaVez))
            // Se o usuário tentar tocar duas vezes rápido, o simples ESPERA para não disparar antes da hora.
            simples.require(toFail: duplo)

            let arrasto = UIPanGestureRecognizer(target: self, action: #selector(arrastou(_:)))

            addGestureRecognizer(duplo)
            addGestureRecognizer(simples)
            addGestureRecognizer(arrasto)
        }

        private func configurarAcessibilidade(titulo: String) {
            isAccessibilityElement = true
            accessibilityLabel = titulo
            accessibilityHint = "Toque para editar."
            
            
            // Como o toque duplo no VoiceOver ativa o item, criamos uma ação explícita para concluir.
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "Concluir") { [weak self] _ in
                    guard let self else { return false }
                    self.delegate?.planetaFoiTocadoDuasVezes(self)
                    return true
                }
            ]
        }

        /// Usado pela tela Editar quando só o título mudou (o tamanho continua o mesmo).
        func atualizarTitulo(_ titulo: String) {
            rotulo.text = titulo
            accessibilityLabel = titulo
        }

        @objc private func tocouUmaVez() { delegate?.planetaFoiTocado(self) }
        @objc private func tocouDuasVezes() { delegate?.planetaFoiTocadoDuasVezes(self) }
        @objc private func arrastou(_ gesto: UIPanGestureRecognizer) { delegate?.planeta(self, arrastou: gesto) }
    }
