// MARK: - Persistencia/AtividadeStore.swift
import Foundation
import SwiftData

/// Único lugar do app que fala com o SwiftData.
/// Telas pedem as coisas ao store; nunca usam ModelContext diretamente.
@MainActor
final class AtividadeStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: Leitura

    /// Atividades ainda não concluídas, da mais antiga para a mais nova.
    func pendentes() -> [Atividade] {
        let descritor = FetchDescriptor<Atividade>(
            predicate: #Predicate { $0.concluidaEm == nil },
            sortBy: [SortDescriptor(\.criadaEm)]
        )
        do {
            return try modelContext.fetch(descritor)
        } catch {
            print("❌ Erro ao carregar atividades: \(error)")
            return []
        }
    }

    /// Busca UMA atividade pelo id (usado quando o planeta é tocado).
    func buscar(id: UUID) -> Atividade? {
        var descritor = FetchDescriptor<Atividade>(predicate: #Predicate { $0.id == id })
        descritor.fetchLimit = 1
        return try? modelContext.fetch(descritor).first
    }

    // MARK: Escrita

    /// Quem cria a Atividade é o store: a tela só manda os dados.
    @discardableResult
    func adicionar(titulo: String, descricao: String, prioridade: Prioridade,
                   aparencia: AparenciaPlaneta? = nil) -> Atividade {
        let nova = Atividade(titulo: titulo, descricao: descricao,
                             prioridade: prioridade, aparencia: aparencia)
        modelContext.insert(nova)
        salvar()
        return nova
    }

    func atualizar(_ atividade: Atividade, titulo: String, descricao: String, prioridade: Prioridade) {
        atividade.titulo = titulo
        atividade.descricao = descricao
        if atividade.prioridade != prioridade {
            atividade.prioridade = prioridade
            // A pele precisa combinar com o novo tamanho (ex.: Lua não pode virar "Grande").
            atividade.aparencia = prioridade.sortearAparencia()
        }
        salvar()
    }

    /// Concluir NÃO apaga: só preenche a data.
    func concluir(_ atividade: Atividade) {
        atividade.concluidaEm = .now
        salvar()
    }

    private func salvar() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Erro ao salvar: \(error)")
        }
    }
}
