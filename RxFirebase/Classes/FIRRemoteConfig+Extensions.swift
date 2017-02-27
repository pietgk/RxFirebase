//
//  RxFirebaseRemoteConfig.swift
//  Pods
//
//  Created by David Wong on 20/05/2016.
//
//

import FirebaseRemoteConfig
import RxSwift

public enum RemoteConfigError: Error {
    case failedToActivateFetched
}

public extension Reactive where Base: FIRRemoteConfig {
    /**
     Fetches Remote Config data and sets a duration that specifies how long config data lasts.
     
     @param expirationDuration  Duration that defines how long fetched config data is available, in seconds. When the config data expires, a new fetch is required.
     
    */
    func fetch(expirationDuration: TimeInterval) -> Observable<FIRRemoteConfigFetchStatus> {
        return Observable.create { observer in
            self.base.fetch(withExpirationDuration: expirationDuration, completionHandler: parseFirebaseResponse(observer))

            return Disposables.create()
        }
    }

    /**
     Fetches Remote Config data and sets a duration that specifies how long config data lasts.
     
     After remote config is fetched, attempt is made `activateFetched`.

     @param expirationDuration  Duration that defines how long fetched config data is available, in seconds. When the config data expires, a new fetch is required.
     */
    func fetchAndActivate(expirationDuration: TimeInterval) -> Observable<()> {
        return self.fetch(expirationDuration: expirationDuration)
            .do(onNext: { status in
                if (status == FIRRemoteConfigFetchStatus.success) {
                    if !self.base.activateFetched() {
                        throw RemoteConfigError.failedToActivateFetched
                    }
                }
            })
            .map { _ in () }
    }

}
