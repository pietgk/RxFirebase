//
//  RxFirebaseStorage.swift
//  Pods
//
//  Created by David Wong on 19/05/2016.
//
//

import FirebaseStorage
import RxSwift

public enum StorageObservableTask<Result> {
    case result(Result)
    case inProgress(Observable<FIRStorageTaskSnapshot>)
}

public protocol StorageObservableTaskConvertible {
    associatedtype ResultType

    var storageObservableTask: StorageObservableTask<ResultType> {
        get
    }
}

public extension Reactive where Base: FIRStorageReference {
    // MARK: UPLOAD
    
    /**
     Asynchronously uploads data to the currently specified FIRStorageReference.
     This is not recommended for large files, and one should instead upload a file from disk.
     
     @param uploadData The NSData to upload.
     @param metadata FIRStorageMetaData containing additional information (MIME type, etc.) about the object being uploaded.
     
    */
    func put(data: Data, metaData: FIRStorageMetadata? = nil) -> Observable<StorageObservableTask<FIRStorageMetadata>> {
        return Observable.create { observer in
            let task = self.base.put(data, metadata: metaData, completion: parseFirebaseResponse(observer))
            observer.onNext(StorageObservableTask(task: task))
            return Disposables.create {
                task.cancel()
            }
        }
    }

    /**
     Asynchronously uploads a file to the currently specified FIRStorageReference.
     
     @param fileURL A URL representing the system file path of the object to be uploaded.
     @param metadata FIRStorageMetadata containing additional information (MIME type, etc.) about the object being uploaded.
    */
    func put(fileAtPath: URL, metadata: FIRStorageMetadata? = nil) -> Observable<StorageObservableTask<FIRStorageMetadata>> {
        return Observable.create { observer in
            let task = self.base.putFile(fileAtPath, metadata: metadata, completion: parseFirebaseResponse(observer))
            observer.onNext(StorageObservableTask(task: task))
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    // MARK: DOWNLOAD
    
    /**
     Asynchronously downloads the object at the FIRStorageReference to an NSData Object in memory.
     An NSData of the provided max size will be allocated, so ensure that the device has enough free
     memory to complete the download. For downloading large files, writeToFile may be a better option.
     
     @param size The maximum size in bytes to download.  If the download exceeds this size the task will be cancelled and an error will be returned.
    */
    func data(maxSize: Int64 = .max) -> Observable<StorageObservableTask<Data>> {
        return Observable.create { observer in
            let task = self.base.data(withMaxSize: maxSize, completion: parseFirebaseResponse(observer))
            observer.onNext(StorageObservableTask(task: task))
            return Disposables.create {
                task.cancel()
            }
        }
    }

    /**
     Asynchronously downloads the object at the current path to a specified system filepath.
     
     @param fileURL A file system URL representing the path the object should be downloaded to.
    */
    func write(fileAtPath: URL) -> Observable<StorageObservableTask<URL>> {
        return Observable.create { observer in
            let task = self.base.write(toFile: fileAtPath, completion: parseFirebaseResponse(observer))
            observer.on(.next(StorageObservableTask(task: task)))
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    /**
     Asynchronously retrieves a long lived download URL with a revokable token.
     This can be used to share the file with others, but can be revoked by a developer
     in the Firebase Console if desired.
    */
    func downloadURL() -> Observable<URL> {
        return Observable.create { observer in
            self.base.downloadURL(completion: parseFirebaseResponse(observer))
            return Disposables.create()
        }
    }
    
    // MARK: DELETE
    /**
     Deletes the object at the current path.
    */
    func delete() -> Observable<()> {
        return Observable.create { observer in
            self.base.delete(completion: parseFirebaseResponse(observer))
            return Disposables.create()
        }
    }
    
    // MARK: METADATA
    /**
     Retrieves metadata associated with an object at the current path.
    */
    func metadata() -> Observable<FIRStorageMetadata> {
        return Observable.create { observer in
            self.base.metadata(completion: parseFirebaseResponse(observer))
            return Disposables.create()
        }
    }
    
    /**
     Updates the metadata associated with an object at the current path.
     
     @param metadata An FIRStorageMetadata object with the metadata to update.
    */
    func update(metadata: FIRStorageMetadata) -> Observable<FIRStorageMetadata> {
        return Observable.create { observer in
            self.base.update(metadata, completion: parseFirebaseResponse(observer))
            return Disposables.create()
        }
    }
}

extension ObservableType where E: StorageObservableTaskConvertible {
    public func finalResult() -> Observable<E.ResultType> {
        return self.flatMapLatest { task -> Observable<E.ResultType> in
            guard let result = task.storageObservableTask.result else {
                return Observable.empty()
            }
            return Observable.just(result)
        }
    }
}

protocol StorageObservableTaskCompatible {

    func observe(_ status: FIRStorageTaskStatus, handler: @escaping (FIRStorageTaskSnapshot) -> Swift.Void) -> String

    func removeObserver(withHandle handle: String)
}

extension FIRStorageUploadTask: StorageObservableTaskCompatible {

}

extension FIRStorageDownloadTask: StorageObservableTaskCompatible {

}

extension StorageObservableTaskCompatible {
    func status(_ status: FIRStorageTaskStatus) -> Observable<FIRStorageTaskSnapshot> {
        return Observable.create { observer in
            let observeStatus = self.observe(status, handler: { (snapshot: FIRStorageTaskSnapshot) in
                if let error = snapshot.error {
                    observer.onError(error)
                } else {
                    observer.onNext(snapshot)
                    if status == .success {
                        observer.onCompleted()
                    }
                }
            })
            return Disposables.create {
                self.removeObserver(withHandle: observeStatus)
            }
        }
    }
}

extension StorageObservableTask {
    public var result: Result? {
        switch self {
        case let .result(result):
            return result
        default:
            return nil
        }
    }
}

extension StorageObservableTask {
    init(task: StorageObservableTaskCompatible) {
        let progressStatus = task.status(.progress)
        let successStatus = task.status(.success)
        let failureStatus = task.status(.failure)

        let allStatuses = Observable.of(progressStatus, successStatus, failureStatus).merge()

        self = .inProgress(allStatuses)
    }

    init(result: Result) {
        self = .result(result)
    }
}

extension StorageObservableTask: StorageObservableTaskConvertible {
    public typealias ResultType = Result
    public var storageObservableTask: StorageObservableTask<Result> {
        return self
    }
}
