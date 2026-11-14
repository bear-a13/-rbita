// MARK: - Componentes/LequeView.swift
import UIKit

@MainActor
protocol LequeViewDelegate: AnyObject {
    func lequeSelecionou(prioridade: Prioridade)
}

/// O leque de opções que se abre acima do botão 3D quando o usuário quer criar uma nova atividade.
final class LequeView: UIView {
    
    weak var delegate: LequeViewDelegate?
    
    // Contêiner que agrupa os botões de prioridade
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

        // Configuração dos botões com o padrão visual exato do Figma:
        // Fundo interno: #1A2142 | Stroke (Borda): #3A4475 | Texto: Branco
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
        
        // Cores exatas fornecidas por você
        config.baseBackgroundColor = Tema.fundoControle // Parte interna
        config.baseForegroundColor = .white                 // Texto claro
        
        // Stroke (Borda) elegante ao redor do botão
        config.background.strokeColor = Tema.bordaControle
        config.background.strokeWidth = 1.5
        
        // Espaçamento interno (padding) para o texto respirar dentro da pílula
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

    // MARK: - Ações de Seleção

    @objc private func escolherPequena() { delegate?.lequeSelecionou(prioridade: .pequena) }
    @objc private func escolherMedia() { delegate?.lequeSelecionou(prioridade: .media) }
    @objc private func escolherGrande() { delegate?.lequeSelecionou(prioridade: .grande) }

    // MARK: - Animação de Abrir e Fechar o Leque

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

