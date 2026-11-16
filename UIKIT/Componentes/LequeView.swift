import UIKit

@MainActor
protocol LequeViewDelegate: AnyObject {
    func lequeSelecionou(prioridade: Prioridade)
}

final class LequeView: UIView {
    
    weak var delegate: LequeViewDelegate?
    
    private let stackView = UIStackView()
    
    // Botões para cada nível de prioridade
    private let botaoPequena = UIButton(type: .system)
    private let botaoMedia = UIButton(type: .system)
    private let botaoGrande = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurarVisual()
        configurarLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não foi implementado")
    }

    private func configurarVisual() {
        // O leque começa invisível e recolhido (escala zero)
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.3, y: 0.3).translatedBy(x: 0, y: 40)
        isUserInteractionEnabled = false

        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.distribution = .equalSpacing

        
        configurarBotaoPrioridade(botaoPequena, titulo: "Pequena", acao: #selector(escolherPequena))
        configurarBotaoPrioridade(botaoMedia, titulo: "Média", acao: #selector(escolherMedia))
        configurarBotaoPrioridade(botaoGrande, titulo: "Grande", acao: #selector(escolherGrande))

        addSubview(stackView)
    }

    private func configurarBotaoPrioridade(_ botao: UIButton, titulo: String, acao: Selector) {
        var config = UIButton.Configuration.filled()
        config.title = titulo
        // Define font and color for the title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            outgoing.foregroundColor = UIColor.white
            return outgoing
        }
        
        config.baseBackgroundColor = Tema.fundoControle
        config.baseForegroundColor = .white
        
        config.background.strokeColor = Tema.bordaControle
        config.background.strokeWidth = 1.5
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        
        botao.configuration = config
        botao.addTarget(self, action: acao, for: .touchUpInside)
        stackView.addArrangedSubview(botao)
    }

    private func configurarLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }


    @objc private func escolherPequena() { delegate?.lequeSelecionou(prioridade: .pequena) }
    @objc private func escolherMedia() { delegate?.lequeSelecionou(prioridade: .media) }
    @objc private func escolherGrande() { delegate?.lequeSelecionou(prioridade: .grande) }

    // animação de abrir e fechar o Leque

    func alternar(abrir: Bool) {
        isUserInteractionEnabled = abrir
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            if abrir {
                self.alpha = 1
                self.transform = .identity
            } else {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.3, y: 0.3).translatedBy(x: 0, y: 40)
            }
        }
    }
}

