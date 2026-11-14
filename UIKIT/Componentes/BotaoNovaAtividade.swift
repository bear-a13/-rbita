// MARK: - Componentes/BotaoNovaAtividade.swift
import UIKit

@MainActor
protocol BotaoNovaAtividadeDelegate: AnyObject {
    func botaoFoiTocado()
}

// parte principal do botão

final class BotaoNovaAtividade: UIView {
    
    weak var delegate: BotaoNovaAtividadeDelegate?
    
    // 1. A base escura (fica deslocada 6 pixels para baixo, criando o relevo 3D)
    private let baseView = UIView()
    
    // 2. A tampa móvel (o círculo amarelo principal)
    private let botaoTampa = UIButton(type: .system)
    
    // 3. O rótulo de texto abaixo do botão
    private let rotulo = UILabel()
    
    // Estados internos
    private(set) var estaAberto = false
    private var isPressed = false {
        didSet { atualizarTransform() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurarVisual()
        configurarLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não foi implementado")
    }

    private func configurarVisual() {
        // --- Configuração da Base 3D (Tom mais escuro) ---
        baseView.backgroundColor = Tema.amareloSombra
        baseView.layer.cornerRadius = 32 // Metade de 64 pt
        addSubview(baseView)

        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus")

        // Tamanho e espessura do "+"
        let simboloConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold) // Mude o pointSize para o tamanho que preferir
        config.preferredSymbolConfigurationForImage = simboloConfig
        config.cornerStyle = .capsule
        config.baseBackgroundColor = Tema.amareloPrincipal
        config.baseForegroundColor = .black
        botaoTampa.configuration = config
        
        // Interceptamos os toques para controlar o estado de pressão
        botaoTampa.addTarget(self, action: #selector(toqueDown), for: [.touchDown, .touchDragEnter])
        botaoTampa.addTarget(self, action: #selector(toqueUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
        botaoTampa.addTarget(self, action: #selector(botaoApertado), for: .touchUpInside)

        botaoTampa.accessibilityLabel = "Nova atividade"
        addSubview(botaoTampa)

        // --- Configuração do Rótulo ---
        rotulo.text = "Nova atividade"
        rotulo.font = .systemFont(ofSize: 12, weight: .medium)
        rotulo.textColor = Tema.textoClaro
        rotulo.textAlignment = .center
        rotulo.isAccessibilityElement = false // o botão já fala o texto
        addSubview(rotulo)
    }

    private func configurarLayout() {
        baseView.translatesAutoresizingMaskIntoConstraints = false
        botaoTampa.translatesAutoresizingMaskIntoConstraints = false
        rotulo.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // A base escura fica exatamente 6 pixels abaixo do topo, criando o relevo visível
            baseView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            baseView.centerXAnchor.constraint(equalTo: centerXAnchor),
            baseView.widthAnchor.constraint(equalToConstant: 64),
            baseView.heightAnchor.constraint(equalToConstant: 64),

            // A tampa amarela começa no topo absoluto (y = 0)
            botaoTampa.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            botaoTampa.centerXAnchor.constraint(equalTo: centerXAnchor),
            botaoTampa.widthAnchor.constraint(equalToConstant: 64),
            botaoTampa.heightAnchor.constraint(equalToConstant: 64),

            // O rótulo fica logo abaixo da base escura
            rotulo.topAnchor.constraint(equalTo: baseView.bottomAnchor, constant: 6),
            rotulo.centerXAnchor.constraint(equalTo: centerXAnchor),
            rotulo.bottomAnchor.constraint(equalTo: bottomAnchor),
            rotulo.leadingAnchor.constraint(equalTo: leadingAnchor),
            rotulo.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - Efeito 3D (Ações de Toque)

    @objc private func toqueDown() {
        isPressed = true // Afunda exatamente 6 pixels, cobrindo a base escura
    }

    @objc private func toqueUp() {
        isPressed = false // Retorna ao topo, revelando o relevo de 6 pixels da base
    }

    @objc private func botaoApertado() {
        delegate?.botaoFoiTocado()
    }

    // MARK: - Alternar entre + e × (Leque - Etapa 10)
    
    func alternarEstado(aberto: Bool) {
        estaAberto = aberto
        rotulo.text = aberto ? "Fechar" : "Nova atividade"
        botaoTampa.accessibilityLabel = aberto ? "Fechar opções" : "Nova atividade"
        atualizarTransform(comMola: true)
    }

    /// Combina a rotação do ícone (+ para ×) com a translação exata de afundamento de 6 pixels
    private func atualizarTransform(comMola: Bool = false) {
        let duracao = comMola ? 0.3 : 0.1
        
        let animations = {
            var transform = CGAffineTransform.identity
            
            if self.estaAberto {
                transform = transform.rotated(by: .pi / 4) // Gira 45° para virar ×
            }
            if self.isPressed {
                transform = transform.translatedBy(x: 0, y: 6) // Afunda exatamente 6 pixels para sumir com a base
            }
            
            self.botaoTampa.transform = transform
        }

        if comMola {
            UIView.animate(withDuration: duracao, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: animations)
        } else {
            UIView.animate(withDuration: duracao, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: animations)
        }
    }
}
