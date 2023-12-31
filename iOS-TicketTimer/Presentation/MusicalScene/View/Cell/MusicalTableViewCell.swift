//
//  MusicalTableViewCell.swift
//  iOS-TicketTimer
//
//  Created by 심현석 on 2023/10/07.
//

import UIKit
import SnapKit
import RxSwift
import Kingfisher

class MusicalTableViewCell: UITableViewCell {
    static let identifier = "MusicalTableViewCell"
    
    let cellData = PublishSubject<Musicals>()
    private var disposeBag = DisposeBag()

    let musicalImageView = UIImageView()
    let siteLabel = SiteLabel(site: .yes24)
    let titleLabel = UILabel()
    let placeLabel = UILabel()
    let dateLabel = UILabel()
    let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUI()
        setAutoLayout()
        bindData()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func bindData() {
        cellData
            .withUnretained(self)
            .bind(onNext: { (self, data) in
                self.siteLabel.site = self.stringToSiteType(string: data.siteCategory ?? "")
                self.titleLabel.text = data.title
                self.placeLabel.text = data.place
                self.dateLabel.text = data.startDate
                let url = URL(string: data.posterUrl ?? "")
                self.musicalImageView.kf.setImage(with: url)
            })
            .disposed(by: disposeBag)
    }

    private func setUI() {
        musicalImageView.layer.masksToBounds = false
        musicalImageView.layer.shadowColor = UIColor.black.cgColor
        musicalImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        musicalImageView.layer.shadowOpacity = 0.2

        titleLabel.text = "뮤지컬 <오페라의 유령>"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.gray100

        placeLabel.text = "샤롯씨어터"
        placeLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        placeLabel.textColor = UIColor.gray80

        dateLabel.text = "2000.00.00 00:00"
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = UIColor.gray80
    }

    private func setAutoLayout() {
        contentView.addSubview(container)
        container.addSubviews([musicalImageView, siteLabel, titleLabel, placeLabel, dateLabel])
        
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }

        musicalImageView.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(160)
            make.top.bottom.leading.equalToSuperview()
        }

        siteLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(musicalImageView.snp.trailing).offset(12)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(siteLabel.snp.bottom).offset(8)
            make.leading.equalTo(musicalImageView.snp.trailing).offset(12)
        }

        placeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalTo(musicalImageView.snp.trailing).offset(12)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(placeLabel.snp.bottom).offset(4)
            make.leading.equalTo(musicalImageView.snp.trailing).offset(12)
        }
    }
    
    private func stringToSiteType(string: String) -> Site {
        if string == "INTERPARK" {
            return .interpark
        } else if string == "MELON" {
            return .melon
        } else {
            return .yes24
        }
    }
}
