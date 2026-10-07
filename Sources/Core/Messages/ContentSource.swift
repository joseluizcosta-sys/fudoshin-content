import Foundation

/// De onde ler a pasta `Content`. Permite injetar um bundle (app/widget) ou um diretório (testes).
struct ContentSource {
    private let locate: (String, String, String) -> URL?

    init(locate: @escaping (String, String, String) -> URL?) {
        self.locate = locate
    }

    /// `subdirectory` é relativo a `Content` ("messages", ou "" para a raiz de Content).
    func url(name: String, ext: String, subdirectory: String) -> URL? {
        locate(name, ext, subdirectory)
    }

    /// Bundle do app ou do widget: a pasta `Content` é incluída como folder reference.
    static func bundle(_ bundle: Bundle) -> ContentSource {
        ContentSource { name, ext, subdirectory in
            let directory = subdirectory.isEmpty ? "Content" : "Content/" + subdirectory
            return bundle.url(forResource: name, withExtension: ext, subdirectory: directory)
        }
    }

    /// Diretório qualquer que tenha a mesma estrutura de `Content`.
    static func directory(_ root: URL) -> ContentSource {
        ContentSource { name, ext, subdirectory in
            var url = root
            if !subdirectory.isEmpty {
                url = url.appendingPathComponent(subdirectory, isDirectory: true)
            }
            url = url.appendingPathComponent(name + "." + ext)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
    }

    /// Conteúdo remoto: mensagens de `remoteRoot/messages/`, imagens sempre do bundle.
    static func hybrid(remoteRoot: URL, imageBundle: Bundle) -> ContentSource {
        let dirSource = Self.directory(remoteRoot)
        let bundleSource = Self.bundle(imageBundle)
        return ContentSource { name, ext, subdirectory in
            subdirectory.isEmpty
                ? bundleSource.url(name: name, ext: ext, subdirectory: subdirectory)
                : dirSource.url(name: name, ext: ext, subdirectory: subdirectory)
        }
    }
}
