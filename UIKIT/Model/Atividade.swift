//
//  Atividade.swift
//  UIKIT
//
//  Created by Bernardo on 14/11/26.
//

// MARK: - Model/Atividade.swift
import Foundation
import SwiftData

@Model
final class Atividade {
    @Attribute(.unique) var id: UUID
    var titulo: String
    var descricao: String
    var prioridade: Prioridade
    var aparencia: AparenciaPlaneta
    var criadaEm: Date
    
    /// nil = pendente. Concluir NÃO apaga a atividade, só preenche esta data.
    var concluidaEm: Date?

    init(titulo: String,
         descricao: String = "",
         prioridade: Prioridade,
         aparencia: AparenciaPlaneta? = nil) {
        self.id = UUID()
        self.titulo = titulo
        self.descricao = descricao
        self.prioridade = prioridade
        // Se nenhuma aparência for passada, sorteia uma pele compatível com o tamanho (ex: Júpiter ou Saturno para Grande)
        self.aparencia = aparencia ?? prioridade.sortearAparencia()
        self.criadaEm = .now
        self.concluidaEm = nil
    }
}
