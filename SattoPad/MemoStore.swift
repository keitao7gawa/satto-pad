//
//  MemoStore.swift
//  SattoPad
//
//  Shared memo text state for editor and overlay.
//

import Foundation
import Combine

final class MemoStore: ObservableObject {
    @Published var text: String = ""
}
