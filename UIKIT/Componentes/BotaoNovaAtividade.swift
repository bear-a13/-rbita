import UIKit

@MainActor
protocol BotaoNovaAtividadeDelegate: AnyObject {
    func botaoFoiTocado()
}

// parte principal do botão

final class BotaoNovaAtividade: UIView {
    
    weak var delegate: BotaoNovaAtividadeDelegate?
    
    // a base escura fica deslocada 6 pixels para baixo
    private let baseView = UIView()
    
    //o botao de cima
    private let botaoTampa = UIButton(type: .system)
    
    // o texto
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
        baseView.backgroundColor = Tema.amareloSombra
        baseView.layer.cornerRadius = 32
        addSubview(baseView)

        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus")

        // configuração do botão de +
        let simboloConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold) // Mude o pointSize para o tamanho que preferir
        config.preferredSymbolConfigurationForImage = simboloConfig
        config.cornerStyle = .capsule
        config.baseBackgroundColor = Tema.amareloPrincipal
        config.baseForegroundColor = .black
        botaoTampa.configuration = config
        
        // estado de presão para criar o botão 3D
        botaoTampa.addTarget(self, action: #selector(toqueDown), for: [.touchDown, .touchDragEnter])
        botaoTampa.addTarget(self, action: #selector(toqueUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
        botaoTampa.addTarget(self, action: #selector(botaoApertado), for: .touchUpInside)

        botaoTampa.accessibilityLabel = "Nova atividade"
        addSubview(botaoTampa)

        // texto abaixo do botão
        rotulo.text = "Nova atividade"
        rotulo.font = .systemFont(ofSize: 12, weight: .medium)
        rotulo.textColor = Tema.textoClaro
        rotulo.textAlignment = .center
        rotulo.isAccessibilityElement = false
        addSubview(rotulo)
    }

    private func configurarLayout() {
        baseView.translatesAutoresizingMaskIntoConstraints = false
        botaoTampa.translatesAutoresizingMaskIntoConstraints = false
        rotulo.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            //configura a altura do botão de baixo
            baseView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            baseView.centerXAnchor.constraint(equalTo: centerXAnchor),
            baseView.widthAnchor.constraint(equalToConstant: 64),
            baseView.heightAnchor.constraint(equalToConstant: 64),

            // a tampa amarela fica no y0
            botaoTampa.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            botaoTampa.centerXAnchor.constraint(equalTo: centerXAnchor),
            botaoTampa.widthAnchor.constraint(equalToConstant: 64),
            botaoTampa.heightAnchor.constraint(equalToConstant: 64),

            // O rotulo fica logo abaixo da base escura
            rotulo.topAnchor.constraint(equalTo: baseView.bottomAnchor, constant: 6),
            rotulo.centerXAnchor.constraint(equalTo: centerXAnchor),
            rotulo.bottomAnchor.constraint(equalTo: bottomAnchor),
            rotulo.leadingAnchor.constraint(equalTo: leadingAnchor),
            rotulo.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }


    @objc private func toqueDown() {
        isPressed = true //
    }

    @objc private func toqueUp() {
        isPressed = false
    }

    @objc private func botaoApertado() {
        delegate?.botaoFoiTocado()
    }

    // alternar entre + e ×
    
    func alternarEstado(aberto: Bool) {
        estaAberto = aberto
        rotulo.text = aberto ? "Fechar" : "Nova atividade"
        botaoTampa.accessibilityLabel = aberto ? "Fechar opções" : "Nova atividade"
        atualizarTransform(comMola: true)
    }

    private func atualizarTransform(comMola: Bool = false) {
        let duracao = comMola ? 0.3 : 0.1
        
        let animations = {
            var transform = CGAffineTransform.identity
            
            if self.estaAberto {
                // Gira 45° para virar ×
                transform = transform.rotated(by: .pi / 4)
            }
            if self.isPressed {
                transform = transform.translatedBy(x: 0, y: 6) 
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
