//
//  HomeViewController.swift
//  iOS-TicketTimer
//
//  Created by 김지현 on 2023/10/03.
//

import RxSwift
import RxDataSources
import SnapKit
import FSCalendar

class HomeViewController: UIViewController {
    
    private let bag = DisposeBag()
    private var homeViewModel = HomeViewModel()
    private lazy var input = HomeViewModel.Input(getDeadlineMusicalNotices: .create(bufferSize: 1),
                                                 getLatestMusicals: .create(bufferSize: 1),
												 loadMoreMusicals: .create(bufferSize: 1),
												 loadMoreMusicalNotices: .create(bufferSize: 1))
    private lazy var output = homeViewModel.transform(input: input)
	private var musicalViewModel = MusicalViewModel()
	
	// 상단 노치 값 구하기
	let scenes = UIApplication.shared.connectedScenes
	lazy var windowScene = self.scenes.first as? UIWindowScene
	lazy var topSafeAreaInsets: CGFloat = self.windowScene?.windows.first?.safeAreaInsets.top ?? 0.0
    
	// UI
	private let scrollView = UIScrollView()
	private let contentView = UIView()
	private lazy var topBgView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 86 + self.topSafeAreaInsets))
    private let logoImageView = UIImageView()
    private let calendarView = UIView()
    private lazy var calendar = FSCalendar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 48, height: self.view.frame.width - 46))
	private let markIconImageView = UIImageView()
	private let ticketLabel = UILabel()
	private let tableView = UITableView()
	private let shadowView = UIView()
	private let showOpenLabel = UILabel()
    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
	
	// datasource
	private let deadlineMusicalNoticesDataSource = RxTableViewSectionedReloadDataSource<MusicalNoticeSection>(configureCell: { dataSource, tableView, indexPath, item in
		guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.identifier,
															for: indexPath) as? HomeTableViewCell else { fatalError("unable to dequeue cell") }
		cell.cellData.onNext(item)
		return cell
	})
	
    private let latestMusicalsDataSource = RxCollectionViewSectionedReloadDataSource<MusicalsSection>(configureCell: { dataSource, collectionView, indexPath, item in
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.identifier,
                                                            for: indexPath) as? HomeCollectionViewCell else { fatalError("unable to dequeue cell") }
        cell.cellData.onNext(item)
        return cell
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		input.getDeadlineMusicalNotices.onNext(.trigger)
        input.getLatestMusicals.onNext(.trigger)
        
        setUI()
        setAutoLayout()
        bindRx()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: false)
	}
    
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: false)
	}
	
    private func setUI() {
        self.view.backgroundColor = .white
		
		self.view.addSubview(scrollView)
		scrollView.addSubview(contentView)
		contentView.addSubviews([shadowView, showOpenLabel, collectionView])
		shadowView.addSubviews([topBgView, calendarView, markIconImageView, ticketLabel, tableView])
        topBgView.addSubview(logoImageView)
        calendarView.addSubview(calendar)
		
		shadowView.backgroundColor = .white
		shadowView.layer.cornerRadius = 16
		shadowView.layer.masksToBounds = false
		shadowView.layer.shadowColor = UIColor.black.cgColor
		shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
		shadowView.layer.shadowOpacity = 0.2
		shadowView.layer.shadowRadius = 16.0
    
        let gradient = CAGradientLayer()
        gradient.frame = topBgView.bounds
        gradient.colors = [UIColor("#00D090").cgColor, UIColor("#0AB27E").cgColor]
        topBgView.layer.insertSublayer(gradient, at: 0)
        topBgView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
        
        logoImageView.image = UIImage(named: "homeLogo")
        
        calendarView.backgroundColor = .white
        calendarView.layer.cornerRadius = 10
        calendarView.layer.masksToBounds = false
        calendarView.layer.shadowColor = UIColor.black.cgColor
        calendarView.layer.shadowOffset = CGSize(width: 0, height: 4)
        calendarView.layer.shadowOpacity = 0.2
        calendarView.layer.shadowRadius = 10.0
        
        calendar.dataSource = self
        calendar.delegate = self
		
		markIconImageView.image = UIImage(named: "markIcon")
        
		ticketLabel.text = "예매 임박"
		ticketLabel.font = .systemFont(ofSize: 17, weight: .bold)
		ticketLabel.textColor = .mainColor
		
		tableView.register(HomeTableViewCell.self, forCellReuseIdentifier: HomeTableViewCell.identifier)
		tableView.rx.setDelegate(self).disposed(by: bag)
		tableView.rowHeight = 42
		tableView.showsVerticalScrollIndicator = false
		
		showOpenLabel.text = "공연 오픈 소식"
        showOpenLabel.font = .systemFont(ofSize: 17, weight: .bold)
        showOpenLabel.textColor = .gray100
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 125, height: 165)
        flowLayout.minimumLineSpacing = 12
    
        collectionView.register(HomeCollectionViewCell.self, forCellWithReuseIdentifier: HomeCollectionViewCell.identifier)
        collectionView.rx.setDelegate(self).disposed(by: bag)
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    private func setAutoLayout() {
		scrollView.snp.makeConstraints {
			$0.edges.equalToSuperview()
		}
		
		contentView.snp.makeConstraints {
			$0.width.equalToSuperview()
			$0.centerX.bottom.equalToSuperview()
			$0.top.equalToSuperview().offset(-self.topSafeAreaInsets) // 노치 높이만큼 위로 올리기
		}
		
		shadowView.snp.makeConstraints {
			$0.top.leading.trailing.equalToSuperview()
			$0.bottom.equalTo(tableView.snp.bottom).offset(30)
		}
		
        topBgView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(130)
        }
        
        logoImageView.snp.makeConstraints {
			$0.centerY.equalToSuperview().offset(8)
			$0.centerX.equalToSuperview()
            $0.width.height.equalTo(35)
        }
        
        calendarView.snp.makeConstraints {
			$0.top.equalTo(topBgView.snp.bottom).offset(-27)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().offset(-24)
            $0.width.height.equalTo(self.view.frame.width - 48)
        }
		
		markIconImageView.snp.makeConstraints {
			$0.leading.equalToSuperview().offset(24)
			$0.top.equalTo(calendarView.snp.bottom).offset(24)
			$0.width.height.equalTo(20)
		}
		
		ticketLabel.snp.makeConstraints {
			$0.leading.equalTo(markIconImageView.snp.trailing).offset(5)
			$0.top.equalTo(calendarView.snp.bottom).offset(24)
		}
		
		tableView.snp.makeConstraints {
			$0.top.equalTo(ticketLabel.snp.bottom)
			$0.leading.equalToSuperview().offset(24)
			$0.trailing.equalToSuperview().offset(-24)
			$0.height.equalTo(42 * 2)
		}
		
		showOpenLabel.snp.makeConstraints {
			$0.top.equalTo(shadowView.snp.bottom).offset(40)
			$0.leading.equalToSuperview().offset(24)
		}
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(showOpenLabel.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(180)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func bindRx() {
		output.bindDeadlineMusicalNotices
			.observe(on: MainScheduler.asyncInstance)
			.bind(to: tableView.rx.items(dataSource: self.deadlineMusicalNoticesDataSource))
			.disposed(by: bag)
		
        output.bindLatestMusicals
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: collectionView.rx.items(dataSource: self.latestMusicalsDataSource))
            .disposed(by: bag)
		
		collectionView.rx.modelSelected(Musicals.self)
			.withUnretained(self)
			.subscribe(onNext: { (self, data) in
				self.musicalViewModel.selectedMusical = data
				self.musicalViewModel.showMusicalDetailViewController(viewController: self)
			})
			.disposed(by: bag)
    }
}

// MARK: - 캘린더
extension HomeViewController: FSCalendarDelegate, FSCalendarDataSource {
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        
        calendar.snp.updateConstraints {
            $0.height.equalTo(bounds.height)
        }
        
        self.view.layoutIfNeeded()
    }
}

// MARK: - 스크롤 이벤트 (페이징 처리)
extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.contentOffset.x != collectionView.contentSize.width &&
            (collectionView.contentOffset.x + 350) > collectionView.contentSize.width {
            input.loadMoreMusicals.onNext(.trigger)
        }
		
		if tableView.contentOffset.y != tableView.contentSize.height &&
			(tableView.contentOffset.y + 130) > tableView.contentSize.height {
			input.loadMoreMusicalNotices.onNext(.trigger)
		}
    }
}
