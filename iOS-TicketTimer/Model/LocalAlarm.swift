//
//  Alarm.swift
//  iOS-TicketTimer
//
//  Created by 심현석 on 2023/10/19.
//

import Foundation

struct LocalAlarm: Codable {
    var noticeId: String
    var id: String = UUID().uuidString
    var title: String
    var body: String
    var date: Date
    var type: LocalAlarmType
    
    init(noticeId: String, noticeTitle body: String, noticeOpenDate date: Date, type: LocalAlarmType) {
        self.noticeId = noticeId
        self.title = type.title
        self.body = body
        //let newDate = Calendar.current.date(byAdding: .minute, value: type.value, to: date)!
        let newDate = Calendar.current.date(byAdding: .second, value: type.value, to: date)!
        self.date = newDate
        self.type = type
    }
}

enum LocalAlarmType: Codable {
    case five
    case ten
    case twenty
    case thirty
    
    var title: String {
        switch self {
        case .five:
            return "예매 5분 전입니다."
        case .ten:
            return "예매 10분 전입니다."
        case .twenty:
            return "예매 20분 전입니다."
        case .thirty:
            return "예매 30분 전입니다."
        }
    }
    
//    var value: Int {
//        switch self {
//        case .five:
//            return -5
//        case .ten:
//            return -10
//        case .twenty:
//            return -20
//        case .thirty:
//            return -30
//        }
//    }
    var value: Int {
        switch self {
        case .five:
            return 3
        case .ten:
            return 6
        case .twenty:
            return 9
        case .thirty:
            return 12
        }
    }
}
