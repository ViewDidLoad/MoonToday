//
//  CalendarViewController.swift
//  moonday
//
//  Created by viewdidload on 2017. 10. 6..
//  Copyright © 2017년 ViewDidLoad. All rights reserved.
//

import UIKit
import AVFoundation

class CalendarViewController: UIViewController  {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var configButton: UIButton!
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var calendarButton: UIButton!
    @IBOutlet weak var dayButton: UIButton!
    @IBOutlet weak var animationButton: UIButton!
    @IBOutlet weak var menuViewTopMargin: NSLayoutConstraint!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var yearMonthLabel: UILabel!
    @IBOutlet weak var nextMonth: UIButton!
    @IBOutlet weak var prevMonth: UIButton!
    
    var touchPlayer:AVAudioPlayer?
    var selectDate:Date?
    let todayDay = Calendar.current.component(.day, from: Date())
    let dateFormat = DateFormatter()
    let textColor = UIColor(displayP3Red: 207/255, green: 217/255, blue: 226/255, alpha: 1.0)
    let darkBuleGray = UIColor(displayP3Red: 11/255, green: 12/255, blue: 30/255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("viewDidLoad")
        // zposition config
        topView.layer.zPosition = 1.02
        menuView.layer.zPosition = 1.01
        // 년월 표시
        dateFormat.dateFormat = "YYYY MMM"
        dateFormat.locale = Locale.current
        yearMonthLabel.text = dateFormat.string(from: selectDate!)
        yearMonthLabel.textColor = textColor
        // swipe gesture
        let directions:[UISwipeGestureRecognizerDirection] = [.down, .up, .left, .right]
        for direct in directions {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipeGesture.direction = direct
            self.contentView.addGestureRecognizer(swipeGesture)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*/ 화면크기 여기서 코드로 조정할 것, autolayout 사용하니까 아이패드랑 큰화면에서 전부 깨짐
        let delta:CGFloat = 8.0
        // topView
        let topViewHeight = UIScreen.main.bounds.size.height * 0.1
        topView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: topViewHeight)
        // titleButton
        titleButton.center = topView.center
        let configButtonWidth = topViewHeight - delta
        configButton.frame = CGRect(x: UIScreen.main.bounds.size.width - configButtonWidth, y: delta, width: configButtonWidth, height: configButtonWidth)
        // menuView
        menuView.frame.size.width = UIScreen.main.bounds.size.width
        dayButton.frame.origin.x = (UIScreen.main.bounds.size.width / 2) - (dayButton.frame.size.width / 2)
        calendarButton.frame.origin.x = dayButton.frame.origin.x - (delta * 3) - calendarButton.frame.size.width
        animationButton.frame.origin.x = dayButton.frame.origin.x + dayButton.frame.size.width + (delta * 3)
        // contentView
        let contentViewHeight = UIScreen.main.bounds.size.height * 0.9
        contentView.frame = CGRect(x: 0, y: topViewHeight, width: UIScreen.main.bounds.size.width, height: contentViewHeight)
        // */
        
        if isBeingPresented || isMovingToParentViewController // 제목 표시 근데 왜 두번 실행될까? 이 조건을 넣으면 한번만 실행된다.
        {
            //print("viewDidAppear : \(todayDay)")
            showCalendar()
        }
    }
    
    fileprivate func showCalendar() {
        //기존에 추가 되어 있는 것은 삭제하여 초기화 한다. 년월 라벨(11), 다음달(12), 이전달(13) 제외한다.
        contentView.subviews
            .filter { $0.tag == 0 }
            .forEach { $0.removeFromSuperview() }
        // 제목 연월 표시
        yearMonthLabel.text = dateFormat.string(from: selectDate!)
        yearMonthLabel.frame = CGRect(x: contentView.bounds.size.width/2 - yearMonthLabel.bounds.size.width/2, y: 8, width: yearMonthLabel.bounds.size.width, height: yearMonthLabel.bounds.size.height)
        // 이전 및 다음 달 위치 조정
        let button_y = (prevMonth.bounds.size.height - (yearMonthLabel.bounds.size.height + 8)) / 2
        prevMonth.frame = CGRect(x: yearMonthLabel.frame.origin.x - prevMonth.bounds.size.width - 8, y: button_y, width: prevMonth.bounds.size.width, height: prevMonth.bounds.size.height)
        nextMonth.frame = CGRect(x: yearMonthLabel.frame.origin.x + yearMonthLabel.bounds.size.width + 8, y: button_y, width: nextMonth.bounds.size.width, height: nextMonth.bounds.size.height)
        // 변수 위치 조정
        let delta:CGFloat = 8.0
        let labelHeight:CGFloat = 18.0
        let start_y = yearMonthLabel.frame.origin.y + yearMonthLabel.frame.size.height + delta // 첫 시작 위치
        let width = (UIScreen.main.bounds.size.width - delta - delta)  / 7
        //print("width -> \(width)")
        let week = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
        week.enumerated().forEach {
            let frame = CGRect(x: CGFloat($0.0) * width + delta, y: start_y, width: width, height: labelHeight)
            let weekLabel = UILabel(frame: frame)
            weekLabel.text = $0.1
            weekLabel.textColor = textColor
            weekLabel.textAlignment = .center
            weekLabel.font = UIFont.systemFont(ofSize: 14.0)
            weekLabel.alpha = 0.3
            contentView.addSubview(weekLabel)
            UIView.animate(withDuration: 0.7, delay: 0.1, options: [.curveLinear], animations: {
                weekLabel.alpha = 1.0
            }, completion: nil)
        }
        // 1일 요일, 이번달이 며칠까지 있는지?
        var dateComp = Calendar.current.dateComponents([.year, .month, .day, .weekday], from: selectDate!)
        dateComp.day = 1
        let firstDate = Calendar.current.date(from: dateComp)
        let weekDay = Calendar.current.component(.weekday, from: firstDate!)
        //print("weekDay -> \(weekDay)")
        let dayCount = Calendar.current.range(of: .day, in: .month, for: firstDate!)?.count ?? 0
        //print("dayCount -> \(dayCount)")
        // weekDay = 1 이면 일요일이므로 무조건 1을 빼줘야 함.
        let weekCount = ceil(CGFloat(weekDay + dayCount - 1) / 7)
        let viewHeight:CGFloat = (contentView.frame.size.height - (start_y + labelHeight + delta + delta)) / weekCount
        //print("viewHeight -> \(viewHeight)")
        // 날짜 표시 변수 초기화
        var day = 1
        for i in 0..<Int(weekCount) {
            for j in 0...6 {
                // 날짜 표시된 부분만
                if ((i * 7 + j + 1) >= weekDay) && (day <= dayCount) {
                    // view 추가
                    let viewX:CGFloat = width * CGFloat(j) + delta
                    let viewY:CGFloat = start_y + labelHeight + delta + (viewHeight * CGFloat(i))
                    let viewFrame = CGRect(x: viewX, y: viewY, width: width, height: viewHeight)
                    let dayView = UIView(frame: viewFrame)
                    // 배경 색상
                    dayView.backgroundColor = UIColor.clear
                    if todayDay == day {
                        let todayImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: viewHeight))
                        todayImageView.image = UIImage(named: "today")
                        dayView.addSubview(todayImageView)
                    }
                    // moon image
                    dateComp.day = day
                    let moonDate = Calendar.current.date(from: dateComp)
                    let phase = nCalc.moonPhase(date: moonDate!).phase
                    let lunarDay = nCalc.phaseTolunarday(phase: phase)
                    let moonImage = UIImage(named: "s_moon_\(lunarDay)")
                    let moonDelta = delta / 2
                    let imageFrame = CGRect(x: moonDelta, y: delta + moonDelta, width: width - delta, height: width - delta)
                    let imageView = UIImageView(frame: imageFrame)
                    imageView.image = moonImage
                    dayView.addSubview(imageView)
                    // day , 높이 신경 안써도 됨, 5개 일때는 104 - 53 - 18 남고 6개일 때 83 - 53 - 18 이어서 남는다.
                    let dayLabelFrameY = delta + imageFrame.size.height + delta
                    let dayLabelFrame = CGRect(x: 0, y: dayLabelFrameY, width: width, height: labelHeight)
                    let dayLabel = UILabel(frame: dayLabelFrame)
                    dayLabel.text = "\(day)"
                    dayLabel.textAlignment = .center
                    dayLabel.textColor = textColor
                    dayView.addSubview(dayLabel)
                    contentView.addSubview(dayView)
                    day += 1
                }
            }
        }
    }
    
    @IBAction func titleButtonTouch(_ sender: UIButton) {
        touchPlaySound()
        // 오늘 날짜로 변경
        selectDate = Date()
        showCalendar()
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 5, options: [.curveLinear], animations: {
            sender.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { finished in
            sender.transform = CGAffineTransform.identity
        })
    }
    
    @IBAction func configButtonTouch(_ sender: UIButton) {
        touchPlaySound()
        print("menuViewTopMargin \(menuViewTopMargin.constant), \(topView.bounds.height)")
        menuView.isHidden = !menuView.isHidden
        menuViewTopMargin.constant = menuView.isHidden ? 0 : -topView.bounds.height
        UIView.animate(withDuration: 0.3) {
            self.loadViewIfNeeded()
        }
    }
    
    @IBAction func monthChangeTouch(_ sender: UIButton) {
        //print("touch -> \(sender.tag)")
        touchPlaySound()
        var dateComp = Calendar.current.dateComponents([.year, .month], from: selectDate!)
        dateComp.month = sender.tag == 12 ? dateComp.month! + 1 : dateComp.month! - 1
        selectDate = Calendar.current.date(from: dateComp)
        // 년월 표시
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "YYYY MMM"
        dateFormat.locale = Locale.current
        yearMonthLabel.text = dateFormat.string(from: selectDate!)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, delay: 0.1, usingSpringWithDamping: 0.1, initialSpringVelocity: 5, options: [.curveLinear], animations: {
                self.yearMonthLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: { (finished) in
                self.yearMonthLabel.transform = CGAffineTransform.identity
            })
        }
        // 달력 표시
        showCalendar()
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        print(sender.direction)
        touchPlaySound()
        var dateComp = DateComponents()
        switch sender.direction {
        case [.left]:
            dateComp.month = 1
        case [.right]:
            dateComp.month = -1
        case [.up]:
            dateComp.year = 1
        case [.down]:
            dateComp.year = -1
        default:
            print("no select error")
        }
        selectDate = Calendar.current.date(byAdding: dateComp, to: selectDate!)! // 날짜 계산
        showCalendar()
    }
    
    func touchPlaySound() {
        guard let url = Bundle.main.url(forResource: "touch", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            touchPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = touchPlayer else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goCalendarToDaySegue" {
            touchPlaySound()
            let dest = segue.destination as! ViewController
            dest.selectDate = selectDate! // 기존 마지막 값을 사용하는게 더 낫지 않을까?
        } else if segue.identifier == "goCalendarToAnimationSegue" {
            touchPlaySound()
            let dest = segue.destination as! AnimationViewController
            dest.selectDate = selectDate!
        }
    }
    
}

