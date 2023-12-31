//
//  AlarmViewModel.swift
//  iOS-TicketTimer
//
//  Created by 심현석 on 2023/10/19.
//

import RxSwift
import RxRelay
import UserNotifications

class AlarmViewModel {
    
    private let disposeBag = DisposeBag()
    private let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    private let alarmService = AlarmService.shared
    
    var alarmId: String?
    var notice: MusicalNotice?
    var savedLocalAlarms = [LocalAlarm]()
    var savedDate: Date?
    
    let input = Input()
    let output = Output()
    
    init() {
        input.getAllAlarms
            .flatMap { _ in
                return self.alarmService.getAllAlarms()
            }
            .subscribe{ [weak self] alarms in
                let section = AlarmSection(items: alarms, header: "")
                self?.output.alarmSections.accept([section])
            }
            .disposed(by: disposeBag)
        
        //MARK: - 캘린더
        input.getCalendarAllEvent
            .flatMap { _ -> Observable<[Alarm]> in
                return self.alarmService.getAllAlarms()
            }
            .subscribe(onNext: { [weak self] alarms in
                var dates = [Date]()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmm"
                
                alarms.forEach { alarm in
                    if let openDateTimeStr = alarm.musicalNotice.openDateTime,
                       let date = dateFormatter.date(from: openDateTimeStr) {
                        dates.append(date)
                    }
                }
                self?.output.bindCalendarAllEvent.accept(dates)
            })
            .disposed(by: disposeBag)
        
        input.getCalendarAlarmSections
            .flatMap { date in
                self.alarmService.getAllAlarms()
                    .map { alarms in
                        alarms.filter { alarm in
                            if let openDateTimeStr = alarm.musicalNotice.openDateTime {
                               let alarmDate = openDateTimeStr.toDateType()
                                return Calendar.current.isDate(alarmDate, inSameDayAs: date)
                            } else {
                                return false
                            }
                        }
                    }
            }
            .subscribe(onNext: { [weak self] alarms in
                var sections: [AlarmSection] = []
                
                let sortedAlarms = alarms.sorted {
                    $0.musicalNotice.openDateTime ?? "" < $1.musicalNotice.openDateTime ?? ""
                }
                let section = AlarmSection(items: sortedAlarms, header: "")
                sections.append(section)
                
                self?.output.bindCalendarAlarmSections.accept(sections)
            })
            .disposed(by: disposeBag)
        
        //MARK: - 알람 리스트
        
        input.getAlarmSections
            .flatMap { _ in
                return self.alarmService.getAllAlarms()
            }
            .subscribe{ [weak self] alarms in
                var sections: [AlarmSection] = []
                var groupedAlarms = [String: [Alarm]]()
                let sortedAlarms = alarms.sorted {
                    $0.musicalNotice.openDateTime ?? "" < $1.musicalNotice.openDateTime ?? ""
                }
                sortedAlarms.forEach { alarm in
                    let header = String(alarm.musicalNotice.openDateTime?.prefix(8) ?? "")
                    if groupedAlarms[header] == nil {
                        groupedAlarms[header] = [alarm]
                    } else {
                        groupedAlarms[header]?.append(alarm)
                    }
                }

                for (header, alarms) in groupedAlarms {
                    let section = AlarmSection(items: alarms, header: header)
                    sections.append(section)
                }
                let sortedSections = sections.sorted {
                    $0.header < $1.header
                }
                
                self?.output.alarmSections.accept(sortedSections)
            }
            .disposed(by: disposeBag)
        
        //MARK: - 알람 세팅
        
        input.getLocalAlarms
            .observe(on: MainScheduler.instance)
            .flatMap { notice -> Observable<[LocalAlarm]> in
                return self.alarmService.getLocalAlarms(notice: notice)
            }
            .subscribe{ [weak self] alarms in
                self?.output.localAlarms.accept(alarms)
                
                self?.savedLocalAlarms = alarms
                if !alarms.isEmpty {
                    self?.alarmId = alarms[0].alarmId
                }
            }
            .disposed(by: disposeBag)
        
        input.setCustomTime
            .subscribe { [weak self] min in
                self?.output.customTime.accept(min)
            }
            .disposed(by: disposeBag)
        
        input.postLocalAlarms
            .observe(on: backgroundScheduler)
            .subscribe { [weak self] times in
                guard let notice = self?.notice else { return }
                self?.alarmService.postNoticeAlarms(notice: notice, alarmTimes: times) {
                    self?.input.getAlarmSections.onNext(())
                }
            }
            .disposed(by: disposeBag)
        
        input.upateLocalAlarms
            .observe(on: backgroundScheduler)
            .subscribe { [weak self] newTimes in
                guard let self = self else { return }
                guard let notice = self.notice else { return }
                self.alarmService.updateNoticeAlarms(savedLocalAlarms: self.savedLocalAlarms, notice: notice, newAlarmTimes: newTimes) {
                    self.input.getAlarmSections.onNext(())
                    self.input.getCalendarAlarmSections.onNext(self.savedDate ?? Date())
                    self.input.getCalendarAllEvent.onNext(())
                }
            }
            .disposed(by: disposeBag)
    }
}

extension AlarmViewModel {
    struct Input {
        var getAllAlarms = PublishSubject<Void>()
        // 캘린더
        var getCalendarAllEvent = PublishSubject<Void>()
        var getCalendarAlarmSections = PublishSubject<Date>()
        // 알람 리스트
        var getAlarmSections = PublishSubject<Void>()
        // 알람 세팅
        var getLocalAlarms = PublishSubject<MusicalNotice>()
        var setCustomTime = PublishSubject<Int>()
        var upateLocalAlarms = PublishSubject<[Int]>()
        var postLocalAlarms = PublishSubject<[Int]>()
    }
    struct Output {
        var alarms = PublishRelay<[Alarm]>()
        // 캘린더
        var bindCalendarAllEvent = PublishRelay<[Date]>()
        var bindCalendarAlarmSections = PublishRelay<[AlarmSection]>()
        // 알람 리스트
        var alarmSections = PublishRelay<[AlarmSection]>()
        // 알람 세팅
        var localAlarms = PublishRelay<[LocalAlarm]>()
        var customTime = BehaviorRelay<Int>(value: 0)
    }
}
