//
//  Atividade.swift
//  UIKIT
//
//  Created by Bernardo on 14/11/26.
//

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
    
    var concluidaEm: Date?

    init(titulo: String,
         descricao: String = "",
         prioridade: Prioridade,
         aparencia: AparenciaPlaneta? = nil) {
        self.id = UUID()
        self.titulo = titulo
        self.descricao = descricao
        self.prioridade = prioridade
        // Se nenhuma aparência for passada, sorteia uma aparencia compatível com o tamanho 
        self.aparencia = aparencia ?? prioridade.sortearAparencia()
        self.criadaEm = .now
        self.concluidaEm = nil
    }
}
