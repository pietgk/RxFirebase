//
//  FirebaseUser.swift
//  Pods
//
//  Created by Krunoslav Zaher on 12/8/16.
//
//

import Foundation
import FirebaseAuth
import RxSwift

extension Reactive where Base: FIRUser {
    
    public func link(with credential: FIRAuthCredential) -> Observable<FIRUser> {
        return Observable.create { observer in
            self.base.link(with: credential, completion: parseFirebaseResponse(observer))
            return Disposables.create()
        }
    }

}
