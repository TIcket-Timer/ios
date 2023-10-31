//
//  AppDelegate.swift
//  iOS-TicketTimer
//
//  Created by Jinhyung Park on 2023/08/01.
//

import UIKit
import UserNotifications
import RxKakaoSDKCommon
import RxKakaoSDKAuth
import KakaoSDKAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //MARK: - 로컬 알림 설정
        requestNotificationAuthorization()
        UNUserNotificationCenter.current().delegate = self
        
        //MARK: - 카카오 SDK 초기화
        RxKakaoSDK.initSDK(appKey: Keys.kakao.rawValue)
        
        //MARK: - 스플래쉬 시간 설정
        sleep(1)
        
        //MARK: - 로그인 상태 확인
        LoginService.shared.checkLogin { isLogin in
            print("[로그인 상태: \(isLogin)]")
            if isLogin {
                UserDefaults.standard.set(true, forKey: "isLogin")
            } else {
                UserDefaults.standard.set(false, forKey: "isLogin")
            }
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.rx.handleOpenUrl(url: url)
        }
        
        return false
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 알람 허용 설정
    func requestNotificationAuthorization() {
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print(error)
            }
        }
    }
    
    // 앱이 실행 중 일때 알람
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}
