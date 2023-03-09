import Foundation
import RxSwift
import RxRelay
import Alamofire
import HsToolKit

class FileDataStorage {
    private let queue: DispatchQueue = DispatchQueue(label: "io.horizontalsystems.unstoppable.file_storage.data", qos: .background)

    func read(directoryUrl: URL, filename: String) -> Single<Data> {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        return Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    print("=> FDStorage =>: Start reading file : \(fileUrl.path)")
                    let data = try FileManager.default.contentsOfFile(coordinatingAccessAt: fileUrl)
                    observer(.success(data))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    func write(directoryUrl: URL, filename: String, data: Data) -> Single<()> {
        let fileUrl = directoryUrl.appendingPathComponent(filename)

        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(coordinatingAccessAt: directoryUrl, withIntermediateDirectories: false)
            } catch {
                return .error(StorageError.cantCreateFile)
            }
        }


        let writeSingle = Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    try FileManager.default.write(data, coordinatingAccessTo: fileUrl)
                    try print("=> FDStorage LOGS =>: After wrote", FileManager.default.contentsOfDirectory(atPath: directoryUrl.path))
                    observer(.success(()))
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }

        return writeSingle
//        return deleteFile(url: fileUrl).flatMap { writeSingle }
    }

    func deleteFile(url: URL?) -> Single<()> {
        print("=> FDStorage =>: Try to delete file")
        guard let url,
              (try? FileManager.default.fileExists(coordinatingAccessAt: url).exists) ?? false else {

            print("=> FDStorage =>: Can't find file! no need to remove")
            return .just(())
        }

        return Single.create { [weak self] observer in
            self?.queue.async {
                do {
                    try FileManager.default.removeItem(coordinatingAccessAt: url)
                    print("=> FDStorage =>: File deleted!")
                    observer(.success(()))
                } catch {
                    print("=> FDStorage =>: throw error: \(error)")
                    observer(.error(error))
                }
            }

            return Disposables.create()
        }
    }

}

extension FileDataStorage {

    enum StorageError: Error {
        case cantCreateFile
        case cantDeleteFile
    }

}
