//
//  animationViewController.swift
//  moonday
//
//  Created by viewdidload on 2017. 10. 9..
//  Copyright © 2017년 ViewDidLoad. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation

class AnimationViewController: UIViewController, CLLocationManagerDelegate  {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var configButton: UIButton!
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var dayButton: UIButton!
    @IBOutlet weak var animationButton: UIButton!
    @IBOutlet weak var menuViewTopMargin: NSLayoutConstraint!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var universeImageView: UIImageView!
    
    @IBOutlet weak var sunImageView: UIImageView!    
    @IBOutlet weak var earthView: UIView!
    @IBOutlet weak var earthImageView: UIImageView!
    @IBOutlet weak var moonView: UIView!
    @IBOutlet weak var moonImageView: UIImageView!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var dateBottomMargin: NSLayoutConstraint!
    
    @IBOutlet weak var selectDatePicker: UIDatePicker!
    @IBOutlet weak var datePickerTopMargin: NSLayoutConstraint!
    
    var touchPlayer:AVAudioPlayer?
    var timerPlayer:AVAudioPlayer?
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    var selectDate = Date()
    var animating = false
    var locationManager = CLLocationManager()
    var currentLocation = CLLocation(latitude: 37.3652536607626, longitude: 127.114830182195) // 기본 값을 한국
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // zposition config
        topView.layer.zPosition = 1.02
        menuView.layer.zPosition = 1.01
        // 위경도 좌표 값 가져오기 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // 항상 실행되었을 때만 위치 좌표를 가져옴
        locationManager.startUpdatingLocation()
        // 날짜 표시
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy.MM.dd"
        dateButton.setTitle(dateFormatter.string(from: selectDate), for: .normal)
        // 시간 포함 2017.08.28 AM 05:38
        timeFormatter.locale = Locale.current
        timeFormatter.dateFormat = "yyyy.MM.dd a hh:mm"
        //print("currentLocation latitude -> \(currentLocation.coordinate.latitude) longitude -> \(currentLocation.coordinate.longitude)")
        // DatePicker 설정
        selectDatePicker.isHidden = true
        selectDatePicker.backgroundColor = UIColor(displayP3Red: 5/255, green: 28/255, blue: 46/255, alpha: 1.0)
        selectDatePicker.setValue(UIColor.green, forKey: "textColor")
        selectDatePicker.date = selectDate
        selectDatePicker.calendar = Calendar.current
        selectDatePicker.layer.zPosition = 4
        // swipe gesture
        let directions:[UISwipeGestureRecognizer.Direction] = [.down, .up, .left, .right]
        for direct in directions {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipeGesture.direction = direct
            self.contentView.addGestureRecognizer(swipeGesture)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isBeingPresented || isMovingToParent // 제목 표시 근데 왜 두번 실행될까? 이 조건을 넣으면 한번만 실행된다.
        {
            print("viewDidAppear : \(String(describing: selectDate))")
            // 백그라운드 서클 생성
            let width = UIScreen.main.bounds.size.width
            let circleView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: width))
            circleView.layer.zPosition = contentView.layer.zPosition + 0.01
            contentView.addSubview(circleView)
            let radius_1 = (width / 2) - moonImageView.frame.size.height // 가장 외곽 달이 회전하는 점선
            let circle_path_1 = UIBezierPath(arcCenter: circleView.center, radius: radius_1, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
            let circleLayer_1 = CAShapeLayer()
            circleLayer_1.path = circle_path_1.cgPath
            circleLayer_1.fillColor = UIColor.clear.cgColor
            circleLayer_1.strokeColor = UIColor.gray.cgColor
            circleLayer_1.lineWidth = 1.0
            circleLayer_1.lineDashPattern = [0.0, 8.0]
            circleLayer_1.lineCap = CAShapeLayerLineCap.round
            circleView.layer.addSublayer(circleLayer_1)
            let radius_2 = ((width / 2) * 0.7) - (earthImageView.frame.size.height / 2) // 안쪽 지구가 회전하는 점선
            let circle_path_2 = UIBezierPath(arcCenter: circleView.center, radius: radius_2, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
            let circleLayer_2 = CAShapeLayer()
            circleLayer_2.path = circle_path_2.cgPath
            circleLayer_2.fillColor = UIColor.clear.cgColor
            circleLayer_2.strokeColor = UIColor.blue.cgColor
            circleLayer_2.lineWidth = 1.0
            circleLayer_2.lineDashPattern = [0.0, 8.0]
            circleLayer_2.lineCap = CAShapeLayerLineCap.round
            circleView.layer.addSublayer(circleLayer_2)
            // 태양을 백그라운드 서클 이미지 중앙에 배치
            sunImageView.bounds.size = CGSize(width: width * 0.184, height: width * 0.184)
            sunImageView.center = circleView.center
            earthView.frame.size.height = width * 0.7
            earthView.center = sunImageView.center
            // 지구 뷰
            earthView.layer.zPosition = circleView.layer.zPosition + 0.01
            // 지구 이미지
            earthImageView.bounds.size = CGSize(width: width * 0.085, height: width * 0.085)
            earthImageView.layer.zPosition = earthView.layer.zPosition + 0.01
            // 태양과 지구 사이 라인
            let sunLinePath = UIBezierPath()
            sunLinePath.move(to: CGPoint(x: earthView.bounds.size.width / 2, y: earthImageView.bounds.size.height / 2))
            sunLinePath.addLine(to: CGPoint(x: earthView.bounds.size.width / 2, y: earthView.bounds.size.height / 2 - sunImageView.bounds.size.height/2))
            let sunLineLayer = CAShapeLayer()
            sunLineLayer.path = sunLinePath.cgPath
            sunLineLayer.strokeColor = UIColor.yellow.cgColor
            sunLineLayer.lineWidth = 1.0
            sunLineLayer.lineDashPattern = [0.0, 8.0]
            sunLineLayer.lineCap = CAShapeLayerLineCap.square
            earthView.layer.addSublayer(sunLineLayer)
            // 지구 주위를 도는 달
            moonView.frame.size.height = width * 0.3
            moonView.center = earthImageView.center
            // 달 뷰
            moonView.layer.zPosition = earthImageView.layer.zPosition + 0.01
            // 달 이미지
            moonImageView.bounds.size = CGSize(width: width * 0.074, height: width * 0.074)
            moonImageView.layer.zPosition = moonView.layer.zPosition + 0.01
            // 지구와 달 사이 라인
            let earthLinePath = UIBezierPath()
            earthLinePath.move(to: CGPoint(x: moonView.bounds.size.width / 2, y: moonImageView.bounds.size.height / 2))
            earthLinePath.addLine(to: CGPoint(x: moonView.bounds.size.width / 2, y: moonView.bounds.size.height / 2 - earthImageView.bounds.size.height/2))
            let earthLineLayer = CAShapeLayer()
            earthLineLayer.path = earthLinePath.cgPath
            earthLineLayer.strokeColor = UIColor.gray.cgColor
            earthLineLayer.lineWidth = 1.0
            earthLineLayer.lineDashPattern = [0.0, 8.0]
            earthLineLayer.lineCap = CAShapeLayerLineCap.square
            moonView.layer.addSublayer(earthLineLayer)
            // 태양 이미지를 가장 앞에
            sunImageView.layer.zPosition = moonImageView.layer.zPosition + 0.01
            if !animating {
                showAnimation()
            }
        }
    }
    
    
    fileprivate func showAnimation() {
        // 애니메이션 시작, 입력 이벤트 중지
        timerPlaySound()
        animating = true
        // 날짜로 태양과 달의 황경을 계산, rightAscesion 황경으로 라디안 값임.
        let days = nCalc.daysSinceJan12000(date: selectDate)
        let moonCoords = nCalc.moonCoordinates(daysSinceJan12000: days)
        let sunCoords = nCalc.sunCoordinates(daysSinceJan12000: days)
        // 회전 준비
        var sunAngle = 0.0
        var moonAngle = 0.0
        // 춘분점이 0이고 추분점이 3.14이며 이후 -3.14에서 0으로 표시된다.
        //print("\(days) --> moonCoords.rightAscension: \(moonCoords.rightAscension), sunCoords.rightAscension: \(sunCoords.rightAscension), moonPhase: \(nCalc.moonPhase(date: selectDate).phase)")
        // 추분점이 지나면 음수이므로 (음수 + 3.14) + 3.14를 더하면 차액만큼 더 나가게 된다.
        let sunBase = sunCoords.rightAscension > 0 ? sunCoords.rightAscension : (sunCoords.rightAscension + Double.pi) + Double.pi
        var moonBase = moonCoords.rightAscension > 0 ? moonCoords.rightAscension : (moonCoords.rightAscension + Double.pi) + Double.pi
        moonBase -= (sunBase - Double.pi)
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            DispatchQueue.global(qos: .userInitiated).async {
                //print("moonAngle: \(moonAngle), moonBase: \(moonBase), sunAngle: \(sunAngle), sunBase: \(sunBase)")
                if sunAngle < sunBase {
                    sunAngle += 0.01
                    //moonAngle -= 0.01
                    //moonBase -= 0.01
                    DispatchQueue.main.async {
                        self.earthView.transform = CGAffineTransform(rotationAngle: CGFloat(sunAngle))
                        //self.moonView.transform = CGAffineTransform(rotationAngle: CGFloat(moonAngle))
                    }
                } else {
                    if moonAngle < moonBase {
                        moonAngle += 0.01
                        DispatchQueue.main.async {
                            //self.earthView.transform = CGAffineTransform(rotationAngle: CGFloat(sunAngle))
                            self.moonView.transform = CGAffineTransform(rotationAngle: CGFloat(moonAngle))
                        }
                    } else {
                        timer.invalidate()
                        self.animating = false
                        self.timerStopSound()
                    }
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func titleButtonTouch(_ sender: UIButton) {
        if !animating {
            // 오늘 날짜로 변경
            touchPlaySound()
            selectDatePicker.date = Date()
            selectDatePickerChanged(selectDatePicker)
            UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 0.1, initialSpringVelocity: 5, options: [.curveLinear], animations: {
                sender.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: { finished in
                sender.transform = CGAffineTransform.identity
            })
        }
    }
    
    @IBAction func configButtonTouch(_ sender: UIButton) {
        if !animating {
            touchPlaySound()
            menuView.isHidden = !menuView.isHidden
            menuViewTopMargin.constant = menuView.isHidden ? 0 : topView.bounds.height
            UIView.animate(withDuration: 0.3) {
                self.loadViewIfNeeded()
            }
        }
    }
    
    @IBAction func selectButtonTouch(_ sender: UIButton) {
        if !animating {
            touchPlaySound()
            selectDatePicker.isHidden = !selectDatePicker.isHidden
            datePickerTopMargin.constant = selectDatePicker.isHidden ? 0 : -selectDatePicker.bounds.height
            dateBottomMargin.constant = selectDatePicker.isHidden ? 20 : selectDatePicker.bounds.height + 8
            UIView.animate(withDuration: 0.3) {
                self.loadViewIfNeeded()
            }
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        print("swipe -> \(sender.direction), animating -> \(animating)")
        touchPlaySound()
        if !animating {
            var dateComp = DateComponents()
            switch sender.direction {
            case [.left]:
                dateComp.day = 1
            case [.right]:
                dateComp.day = -1
            case [.up]:
                dateComp.month = 1
            case [.down]:
                dateComp.month = -1
            default:
                print("no select error")
            }
            selectDate = Calendar.current.date(byAdding: dateComp, to: selectDate)! // 날짜 계산
            selectDatePicker.date = selectDate // 어쩔지 모르니까 피커에 변경된 날짜 적용하기
            dateButton.setTitle(dateFormatter.string(from: selectDate), for: .normal)
            locationManager.startUpdatingLocation()
            // 변경된 날짜에 맞춰서 지구와 달 회전
            // 날짜로 태양과 달의 황경을 계산, rightAscesion 황경으로 라디안 값임.
            let days = nCalc.daysSinceJan12000(date: selectDate)
            let moonCoords = nCalc.moonCoordinates(daysSinceJan12000: days)
            let sunCoords = nCalc.sunCoordinates(daysSinceJan12000: days)
            //print("\(days) --> moonCoords.rightAscension: \(moonCoords.rightAscension), sunCoords.rightAscension: \(sunCoords.rightAscension), moonPhase: \(nCalc.moonPhase(date: selectDate).phase)")
            // 추분점이 지나면 음수이므로 (음수 + 3.14) + 3.14를 더하면 차액만큼 더 나가게 된다.
            let sunBase = sunCoords.rightAscension > 0 ? sunCoords.rightAscension : (sunCoords.rightAscension + Double.pi) + Double.pi
            var moonBase = moonCoords.rightAscension > 0 ? moonCoords.rightAscension : (moonCoords.rightAscension + Double.pi) + Double.pi
            moonBase -= (sunBase - Double.pi)
            DispatchQueue.main.async {
                self.earthView.transform = CGAffineTransform(rotationAngle: CGFloat(sunBase))
                self.moonView.transform = CGAffineTransform(rotationAngle: CGFloat(moonBase))
            }
        }
    }
    
    @IBAction func selectDatePickerChanged(_ sender: UIDatePicker) {
        selectDate = sender.date // 선택한 날짜 변수에 입력
        dateButton.setTitle(dateFormatter.string(from: selectDate), for: .normal)
        locationManager.startUpdatingLocation()
        DispatchQueue.main.async {
            // 날짜 선택 피커 아래로 감춰짐.
            UIView.animate(withDuration: 0.1, delay: 0.01, options: [.curveEaseInOut], animations: {
                self.selectDatePicker.frame.origin.y = UIScreen.main.bounds.size.height
            }, completion: { finished in
                self.selectDatePicker.isHidden = true
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last!
        if currentLocation.coordinate.longitude < 0 { // 그리니치에서 서쪽으론 음수이므로 이를 보정해줘야 정확한 값이 나온다.
            currentLocation = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: 360 - currentLocation.coordinate.longitude)
        }
        locationManager.stopUpdatingLocation() // 갱신 했으니 좌표 가져오기 중단
    }
    
    func touchPlaySound() {
        guard let url = Bundle.main.url(forResource: "touch", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
            try AVAudioSession.sharedInstance().setActive(true)
            touchPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = touchPlayer else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func timerPlaySound() {
        guard let url = Bundle.main.url(forResource: "ticking", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
            try AVAudioSession.sharedInstance().setActive(true)
            timerPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = timerPlayer else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func timerStopSound() {
        guard let url = Bundle.main.url(forResource: "ticking", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
            try AVAudioSession.sharedInstance().setActive(true)
            timerPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = timerPlayer else { return }
            player.stop()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goAnimationToCalendarSegue" {
            touchPlaySound()
            let dest = segue.destination as! CalendarViewController
            dest.selectDate = selectDate
        } else if segue.identifier == "goAnimationToDaySegue" {
            touchPlaySound()
            let dest = segue.destination as! ViewController
            dest.selectDate = selectDate
        }
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
