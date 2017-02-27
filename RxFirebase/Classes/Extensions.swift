//
//  RxFirebase.swift
//  Pods
//
//  Created by Krunoslav Zaher on 12/7/16.
//
//

import Foundation
import RxSwift

public struct UnknownFirebaseError: Error {

}

func parseFirebaseResponse<T>(_ observer: AnyObserver<T>) -> (T?, Error?) -> () {
    return { value, error in
        if let value = value {
            observer.on(.next(value))
            observer.on(.completed)
        }
        else if let error = error {
            observer.on(.error(error))
        }
        else {
            observer.on(.error(UnknownFirebaseError()))
        }
    }
}

func parseFirebaseResponse<T>(_ observer: AnyObserver<StorageObservableTask<T>>) -> (T?, Error?) -> () {
    return { value, error in
        if let value = value {
            observer.on(.next(StorageObservableTask(result: value)))
            observer.on(.completed)
        }
        else if let error = error {
            observer.on(.error(error))
        }
        else {
            observer.on(.error(UnknownFirebaseError()))
        }
    }
}

func parseFirebaseResponse<T>(_ observer: AnyObserver<T>) -> (Error?, T?) -> () {
    return { error, value in
        if let value = value {
            observer.on(.next(value))
            observer.on(.completed)
        }
        else if let error = error {
            observer.on(.error(error))
        }
        else {
            observer.on(.error(UnknownFirebaseError()))
        }
    }
}

func parseFirebaseResponse<T, T2>(_ observer: AnyObserver<(T2, T)>) -> (Error?, T2, T?) -> () {
    return { error, value2, value in
        if let value = value {
            observer.on(.next((value2, value)))
            observer.on(.completed)
        }
        else if let error = error {
            observer.on(.error(error))
        }
        else {
            observer.on(.error(UnknownFirebaseError()))
        }
    }
}

func parseFirebaseResponse(_ observer: AnyObserver<()>) -> (Error?) -> () {
    return { error in
        if let error = error {
            observer.on(.error(error))
        }
        else {
            observer.on(.next())
            observer.on(.completed)
        }
    }
}
