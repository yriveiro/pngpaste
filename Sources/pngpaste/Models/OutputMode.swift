enum OutputMode: Sendable, Equatable {
    case file(path: String)
    case stdout
    case base64
}
