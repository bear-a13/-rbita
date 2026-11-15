// MARK: - Telas/UniversoViewController.swift
import UIKit

final class UniversoViewController: UIViewController {

    private let fundoImageView = UIImageView()
    private let estadoVazioLabel = UILabel()
    private var fisica: UniversoFisico?
    private let botaoNovaAtividade = BotaoNovaAtividade()
    private let lequeView = LequeView()
    private let sensor = SensorDeMovimento()
    /// Vibração curta quando um planeta bate (estilo "rígido", como pedra).
    private let vibracaoBatida = UIImpactFeedbackGenerator(style: .rigid)

    /// O gerenciador do banco (SwiftData), injetado pelo SceneDelegate.
    private let store: AtividadeStore

    /// Planetas que estão na tela agora.
    private var planetas: [PlanetaView] = []

    // MARK: - Inicializador (injeção de dependência)

    init(store: AtividadeStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não foi implementado")
    }

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        configurarFundo()
        configurarEstadoVazio()
        configurarBotao()
        configurarToqueForaDoLeque()

        // 1. Liga o motor de física
        fisica = UniversoFisico(referencia: view)

        // 2. Gravidade vem do sensor (com "Reduzir movimento" ligado, fica sempre para baixo)
        sensor.aoMudarGravidade = { [weak self] direcao in
            let gravidadeFinal = UIAccessibility.isReduceMotionEnabled ? CGVector(dx: 0, dy: 1) : direcao
            self?.fisica?.definirGravidade(gravidadeFinal)
        }

        // 3. Chacoalhar forte = empurrão aleatório em todos
        sensor.aoChacoalhar = { [weak self] in
            self?.chacoalhar()
        }

        // 4. Balançar = os planetas ficam para trás por inércia, na direção contrária da mão
        sensor.aoBalancar = { [weak self] aceleracao, intervalo in
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            self?.fisica?.balancar(aceleracao: aceleracao, intervalo: intervalo)
        }

        // 5. Vibração: quanto mais forte a batida, mais forte a vibração
        vibracaoBatida.prepare()
        fisica?.aoBater = { [weak self] intensidade in
            self?.vibracaoBatida.impactOccurred(intensity: 0.3 + 0.7 * intensidade)
            self?.vibracaoBatida.prepare()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sensor.iniciar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sensor.parar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fisica?.atualizarLimites(margens: view.safeAreaInsets,
                                 obstaculos: [botaoNovaAtividade.frame])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // A safe area só é definitiva aqui; por isso os planetas nascem agora.
        if planetas.isEmpty { carregarAtividadesDoBanco() }
    }

    /// Chacoalhar no SIMULADOR (menu Device > Shake). O simulador não tem CoreMotion,
    /// então o SensorDeMovimento nunca avisa por lá — este é o atalho para testar.
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { chacoalhar() }
    }

    private func chacoalhar() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        fisica?.impulsionarTodos()
    }

    // MARK: - Fundo e estado vazio

    private func configurarFundo() {
        fundoImageView.image = UIImage(named: "fundo-ceu")
        fundoImageView.contentMode = .scaleAspectFill
        fundoImageView.clipsToBounds = true
        fundoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fundoImageView)

        NSLayoutConstraint.activate([
            fundoImageView.topAnchor.constraint(equalTo: view.topAnchor),
            fundoImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            fundoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fundoImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func configurarEstadoVazio() {
        estadoVazioLabel.text = "Nenhuma atividade em órbita.\nToque em + para criar a primeira."
        estadoVazioLabel.numberOfLines = 0
        estadoVazioLabel.textAlignment = .center
        estadoVazioLabel.font = .systemFont(ofSize: 15, weight: .medium)
        estadoVazioLabel.textColor = Tema.textoClaro.withAlphaComponent(0.8)
        estadoVazioLabel.alpha = 0
        estadoVazioLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(estadoVazioLabel)

        NSLayoutConstraint.activate([
            estadoVazioLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            estadoVazioLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            estadoVazioLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32)
        ])
    }

    private func atualizarEstadoVazio() {
        let vazio = planetas.isEmpty
        UIView.animate(withDuration: 0.3) { self.estadoVazioLabel.alpha = vazio ? 1 : 0 }
    }


    private func configurarBotao() {
        botaoNovaAtividade.delegate = self
        botaoNovaAtividade.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(botaoNovaAtividade)

        lequeView.delegate = self
        lequeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lequeView)

        NSLayoutConstraint.activate([
            botaoNovaAtividade.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            botaoNovaAtividade.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            botaoNovaAtividade.widthAnchor.constraint(equalToConstant: 140),
            botaoNovaAtividade.heightAnchor.constraint(equalToConstant: 90),

            lequeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lequeView.bottomAnchor.constraint(equalTo: botaoNovaAtividade.topAnchor, constant: -12)
        ])
    }

    /// Toque em qualquer lugar fora do leque fecha o leque.
    private func configurarToqueForaDoLeque() {
        let toque = UITapGestureRecognizer(target: self, action: #selector(tocouFora(_:)))
        toque.cancelsTouchesInView = false // não "rouba" o toque dos planetas e botões
        view.addGestureRecognizer(toque)
    }

    @objc private func tocouFora(_ gesto: UITapGestureRecognizer) {
        guard botaoNovaAtividade.estaAberto else { return }
        let ponto = gesto.location(in: view)
        if lequeView.frame.contains(ponto) || botaoNovaAtividade.frame.contains(ponto) { return }
        abrirLeque(false)
    }

    private func abrirLeque(_ abrir: Bool) {
        botaoNovaAtividade.alternarEstado(aberto: abrir)
        lequeView.alternar(abrir: abrir)
    }

    // MARK: - Planetas

    private func carregarAtividadesDoBanco() {
        semearExemplosNaPrimeiraVez()
        for atividade in store.pendentes() {
            criarPlaneta(para: atividade)
        }
        atualizarEstadoVazio()
    }

    /// Na PRIMEIRA abertura do app, cria alguns planetas de exemplo.
    /// Fica marcado no UserDefaults: se o usuário concluir tudo, os exemplos NÃO voltam.
    private func semearExemplosNaPrimeiraVez() {
        let chave = "jaSemeouPlanetasIniciais"
        guard !UserDefaults.standard.bool(forKey: chave) else { return }
        UserDefaults.standard.set(true, forKey: chave)
        guard store.pendentes().isEmpty else { return }

        let exemplos: [(String, Prioridade, AparenciaPlaneta)] = [
            ("Estudar cálculo", .grande, .jupiter),
            ("Entregar o projeto", .grande, .saturno),
            ("Cobrar o Rafa", .media, .terra),
            ("Pagar o boleto", .media, .marte),
            ("Falar com o Axiel", .pequena, .lua),
            ("Responder a Ana", .pequena, .tita)
        ]
        for (titulo, prioridade, aparencia) in exemplos {
            store.adicionar(titulo: titulo, descricao: "", prioridade: prioridade, aparencia: aparencia)
        }
    }

    /// ÚNICO lugar que transforma uma Atividade em planeta na tela.
    /// `centro`: onde nascer (na edição, no mesmo lugar do planeta antigo). Se nil, procura um lugar livre.
    private func criarPlaneta(para atividade: Atividade, centro: CGPoint? = nil) {
        guard let fisica else { return }
        let largura = view.bounds.width
        let prioridade = atividade.prioridade
        let aparencia = atividade.aparencia
        let diametro = prioridade.diametro(larguraDaTela: largura)

        let planeta = PlanetaView(
            atividadeID: atividade.id,
            titulo: atividade.titulo,
            nomeDoAsset: aparencia.nomeDoAsset,
            diametro: diametro,
            escalaDaImagem: aparencia.escalaDaImagem,
            corDoTitulo: UIColor(hex: aparencia.corDoTituloHex),
            tamanhoDoTitulo: prioridade.tamanhoDoTitulo(larguraDaTela: largura)
        )
        planeta.delegate = self
        planeta.center = centro ?? posicaoLivre(diametro: diametro,
                                                larguraVisivel: diametro * aparencia.escalaDaImagem.width)

        // Saturno fica por cima dos outros (os anéis passam na frente), mas abaixo do botão.
        if aparencia == .saturno {
            view.insertSubview(planeta, belowSubview: botaoNovaAtividade)
        } else {
            view.insertSubview(planeta, aboveSubview: estadoVazioLabel)
        }

        fisica.adicionar(planeta, densidade: prioridade.densidade, elasticidade: prioridade.elasticidade)
        planetas.append(planeta)
        atualizarEstadoVazio()
    }

    /// Tira o planeta da física e da lista. Com poeira = concluir; sem poeira = troca na edição.
    private func removerPlaneta(_ planeta: PlanetaView, comPoeira: Bool, corDaPoeira: UIColor = .white) {
        fisica?.remover(planeta)
        planetas.removeAll { $0 === planeta }
        atualizarEstadoVazio()

        guard comPoeira else {
            planeta.removeFromSuperview()
            return
        }
        EfeitoPoeira.explodir(em: planeta.center,
                              diametro: planeta.bounds.width,
                              cor: corDaPoeira,
                              dentroDe: view)
        UIView.animate(withDuration: 0.25, animations: {
            planeta.alpha = 0
            planeta.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }, completion: { _ in
            planeta.removeFromSuperview()
        })
    }

    /// Procura um ponto onde o planeta não nasça em cima de outro nem do botão "+".
    private func posicaoLivre(diametro: CGFloat, larguraVisivel: CGFloat) -> CGPoint {
        let area = view.bounds.inset(by: view.safeAreaInsets)
        let raio = diametro / 2
        let margemX = min(larguraVisivel / 2 + 8, area.width / 2)
        let faixaY = (area.minY + raio + 8)...max(area.minY + raio + 8, area.maxY - raio - 8)

        // O botão entra na conta como se fosse mais um "vizinho" redondo.
        let botao = botaoNovaAtividade.frame
        var vizinhos = planetas.map { ($0.center, $0.bounds.width / 2) }
        vizinhos.append((CGPoint(x: botao.midX, y: botao.midY), max(botao.width, botao.height) / 2))

        var melhor = CGPoint(x: area.midX, y: faixaY.lowerBound)
        var maiorFolga = -CGFloat.infinity

        for _ in 0..<60 {
            let candidato = CGPoint(x: .random(in: (area.minX + margemX)...(area.maxX - margemX)),
                                    y: .random(in: faixaY))
            let folga = vizinhos.map { centro, raioVizinho in
                hypot(centro.x - candidato.x, centro.y - candidato.y) - raio - raioVizinho
            }.min() ?? .infinity

            if folga > 8 { return candidato }
            if folga > maiorFolga { maiorFolga = folga; melhor = candidato }
        }
        return melhor
    }

    private func abrirFormulario(_ modo: FormularioAtividadeViewController.Modo) {
        let formulario = FormularioAtividadeViewController(modo: modo)
        formulario.delegate = self
        if let sheet = formulario.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
        }
        present(formulario, animated: true)
    }
}

// MARK: - PlanetaViewDelegate

extension UniversoViewController: PlanetaViewDelegate {
    /// Toque simples: editar (Etapa 12).
    func planetaFoiTocado(_ planeta: PlanetaView) {
        // Se o leque estava aberto, o primeiro toque só fecha o leque.
        if botaoNovaAtividade.estaAberto { abrirLeque(false); return }
        guard let atividade = store.buscar(id: planeta.atividadeID) else { return }
        abrirFormulario(.editar(atividade))
    }

    /// Toque duplo: concluir com poeira (Etapa 13).
    func planetaFoiTocadoDuasVezes(_ planeta: PlanetaView) {
        var cor = UIColor.white
        if let atividade = store.buscar(id: planeta.atividadeID) {
            cor = UIColor(hex: atividade.aparencia.corPrincipalHex)
            store.concluir(atividade)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: "Atividade concluída")
        removerPlaneta(planeta, comPoeira: !UIAccessibility.isReduceMotionEnabled, corDaPoeira: cor)
    }

    func planeta(_ planeta: PlanetaView, arrastou gesto: UIPanGestureRecognizer) {
        let ponto = gesto.location(in: view)
        switch gesto.state {
        case .began: fisica?.comecarArrasto(planeta, ponto: ponto)
        case .changed: fisica?.moverArrasto(para: ponto)
        case .ended, .cancelled: fisica?.terminarArrasto(velocidade: gesto.velocity(in: view))
        default: break
        }
    }
}

// MARK: - BotaoNovaAtividadeDelegate

extension UniversoViewController: BotaoNovaAtividadeDelegate {
    func botaoFoiTocado() {
        abrirLeque(!botaoNovaAtividade.estaAberto)
    }
}

// MARK: - LequeViewDelegate (Etapas 10 e 11)

extension UniversoViewController: LequeViewDelegate {
    func lequeSelecionou(prioridade: Prioridade) {
        abrirLeque(false)
        abrirFormulario(.nova(prioridade))
    }
}

// MARK: - FormularioAtividadeDelegate (Etapas 11 e 12)

extension UniversoViewController: FormularioAtividadeDelegate {
    func formularioCriou(titulo: String, descricao: String, prioridade: Prioridade) {
        let atividade = store.adicionar(titulo: titulo, descricao: descricao, prioridade: prioridade)
        criarPlaneta(para: atividade)
    }

    func formularioEditou(_ atividade: Atividade, titulo: String, descricao: String, prioridade: Prioridade) {
        guard let planeta = planetas.first(where: { $0.atividadeID == atividade.id }) else { return }
        let prioridadeAntiga = atividade.prioridade

        store.atualizar(atividade, titulo: titulo, descricao: descricao, prioridade: prioridade)

        if prioridadeAntiga == prioridade {
            // Mesmo tamanho: só troca o texto, o planeta continua na física.
            planeta.atualizarTitulo(titulo)
        } else {
            // Tamanho mudou: a física não aceita mudar o tamanho de um item,
            // então trocamos o planeta por um novo no mesmo lugar.
            let centro = planeta.center
            removerPlaneta(planeta, comPoeira: false)
            criarPlaneta(para: atividade, centro: centro)
        }
    }
}
