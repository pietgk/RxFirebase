//
//  RxFirebaseAuth.swift
//  RxFirebase
//
//  Created by David Wong on 05/19/2016.
//  Copyright (c) 2016 David Wong. All rights reserved.
//

import FirebaseAnalytics
import FirebaseAuth
import RxSwift

public extension Reactive where Base: FIRAuth {
    /**
     Registers for an "auth state did change" observable. Invoked when:
     - Registered as a listener
     - The current user changes, or,
     - The current user's access token changes.
     */
    var user: Observable<FIRUser?> {
        get {
            return Observable.create { observer in
                let listener = self.base.addStateDidChangeListener { (auth, user) in
                    observer.onNext((auth, user))
                }
                return Disposables.create {
                    self.base.removeStateDidChangeListener(listener)
                }
            }
        }
    }
    
    /**
     Sign in with email address and password.
     @param email The user's email address.
     @param password The user's password.
    */
    func signIn(withEmail email: String, password: String) -> Observable<FIRUser> {
        return Observable.create { observer in
            
            self.base.signIn(
                withEmail: email,
                password: password,
                completion: parseFirebaseResponse(observer)
            )
            
            return Disposables.create()
        }
    }
    
    /** 
        sign in anonymously
    */
    func signInAnonymously() -> Observable<FIRUser> {
        return Observable.create { observer in
            self.base.signInAnonymously(completion: parseFirebaseResponse(observer))
            
            return Disposables.create()
        }
    }
    
    /**
     Sign in with credential.
     @param credentials An instance of FIRAuthCredential (Facebook, Twitter, Github, Google)
    */
    func signIn(with credentials: FIRAuthCredential) -> Observable<FIRUser> {
        return Observable.create { observer in
            self.base.signIn(with: credentials, completion: parseFirebaseResponse(observer))

            return Disposables.create()
        }
    }
    
    /**
     Sign in with custom token.
     @param A custom token. Please see Firebase's documentation on how to set this up.
    */
    func signIn(withCustomToken token: String) -> Observable<FIRUser> {
        return Observable.create { observer in
            self.base.signIn(withCustomToken: token, completion: parseFirebaseResponse(observer))

            return Disposables.create()
        }
    }
    
    /**
     Create and on success sign in a user with the given email address and password.
     @param email The user's email address.
     @param password The user's desired password
    */
    func createUser(withEmail email: String, password: String) -> Observable<FIRUser> {
        return Observable.create { observer in
            self.base.createUser(withEmail: email, password: password, completion: parseFirebaseResponse(observer))

            return Disposables.create()
        }
    }
    
}
