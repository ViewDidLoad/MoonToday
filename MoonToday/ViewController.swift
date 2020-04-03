//
//  ViewController.swift
//  moonday
//
//  Created by viewdidload on 2017. 9. 27..
//  Copyright © 2017년 ViewDidLoad. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import GoogleMobileAds

class ViewController: UIViewController, CLLocationManagerDelegate, GADBannerViewDelegate {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var configButton: UIButton!
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var dayButton: UIButton!
    @IBOutlet weak var animationButton: UIButton!
    @IBOutlet weak var menuViewTopMargin: NSLayoutConstraint!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var skyImageView: UIImageView!
    @IBOutlet weak var stars1ImageView: UIImageView!
    @IBOutlet weak var stars2ImageView: UIImageView!    
    @IBOutlet weak var moonImageView: UIImageView!
    @IBOutlet weak var cloud3ImageView: UIImageView!
    @IBOutlet weak var cloud2ImageView: UIImageView!
    @IBOutlet weak var cloud1ImageView: UIImageView!
    
    @IBOutlet weak var seaImageView: UIImageView!
    @IBOutlet weak var seawaveImageView: UIImageView!
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var dateBottomMargin: NSLayoutConstraint!
    
    @IBOutlet weak var selectDatePicker: UIDatePicker!
    @IBOutlet weak var datePickerTopMargin: NSLayoutConstraint!
    
    var touchPlayer:AVAudioPlayer?
    var swipePlayer:AVAudioPlayer?
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    var selectDate = Date()
    var locationManager = CLLocationManager()
    var currentLocation = CLLocation(latitude: 37.3652536607626, longitude: 127.114830182195) // 기본 값을 한국
    var stardust_x:CGFloat = 100.0
    var stardust_duration:TimeInterval = 1.5
    let textColor = UIColor(displayP3Red: 207/255, green: 217/255, blue: 226/255, alpha: 1.0)
    let darkBuleGray = UIColor(displayP3Red: 11/255, green: 12/255, blue: 30/255, alpha: 1.0)
    var onceShow:Bool = false // ViewDidAppear 한번만 실행하기 위한 변수
    // 광고 배너
    var bannerView: GADBannerView!
    var bannerHeight: CGFloat = 0.0
    var isAdShow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad timeZone: \(TimeZone.current.secondsFromGMT())")
        // zposition config
        topView.layer.zPosition = 1.02
        menuView.layer.zPosition = 1.01
        skyImageView.layer.zPosition = -2.3
        stars1ImageView.layer.zPosition = -2.2
        stars2ImageView.layer.zPosition = -2.2
        moonImageView.layer.zPosition = -2.1
        seaImageView.layer.zPosition = -1.1
        seawaveImageView.layer.zPosition = -1.0
        // 날짜 표시
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy.MM.dd"
        dateButton.setTitle(dateFormatter.string(from: selectDate), for: .normal)
        // 시간 포함 2017.08.28 AM 05:38
        timeFormatter.locale = Locale.current
        timeFormatter.dateFormat = "yyyy.MM.dd a hh:mm"
        //print("currentLocation latitude -> \(currentLocation.coordinate.latitude) longitude -> \(currentLocation.coordinate.longitude)")
        // 위경도 좌표 값 가져오기 설정
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // 항상 실행되었을 때만 위치 좌표를 가져옴
        locationManager.startUpdatingLocation()
        // 날짜에 달 이미지 맞추기
        //let phase = nCalc.moonPhase(date: selectDate).phase
        //let lunarDay = nCalc.phaseTolunarday(phase: phase)
        //moonImageView.image = UIImage(named: "b_moon_\(lunarDay)")
        let nMoon = NemesisMoon()
        let julian = nMoon.solarToJulian(date: selectDate)
        let sunLng = nMoon.julianToSunLongitude(julian: julian)
        let moonLng = nMoon.julianToMoonLongitude(julian: julian)
        let lunar = nMoon.longitudeToLunarDay(sunLng: sunLng, moonLng: moonLng)
        let lunarDay = String(format: "%02d", lunar)
        moonImageView.image = UIImage(named: "b_moon_\(lunarDay)")
        // DatePicker 설정
        selectDatePicker.isHidden = true
        selectDatePicker.backgroundColor = UIColor(displayP3Red: 5/255, green: 28/255, blue: 46/255, alpha: 1.0)
        selectDatePicker.setValue(UIColor.green, forKey: "textColor")
        selectDatePicker.date = selectDate
        selectDatePicker.calendar = Calendar.current
        selectDatePicker.layer.zPosition = 4
        // swipe gesture
        let directions:[UISwipeGestureRecognizerDirection] = [.down, .up, .left, .right]
        for direct in directions {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipeGesture.direction = direct
            self.contentView.addGestureRecognizer(swipeGesture)
        }
        // AdMob Banner 설정
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-7335522539377881/9101989973"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["855234fcd08b0733d55d5803d54db883"]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 한번만 실행하기
        if (onceShow == false) {
            // stardust 만들어서 이동시키기 drand48() -> 0.0 ~ 1.0 결과가 나오는데 이는 현재 .now() 보다 결과로 나온 초 이후에 실행한다.
            DispatchQueue.main.asyncAfter(deadline: .now() + drand48()) {
                self.stardustDroping()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + drand48()) {
                self.stardustDroping()
            }
            // 반짝 반짝 작은 별
            twinkle(duration: 1.5)
            // 짐승 같은 달의 숨소리
            breathingMoon(scale: 1.1, duration: 2.5)
            // 음산하게 움직이는 구름
            dreary(delta: 2, duration: 0.5)
            // 항상 꿀렁이는 파도
            waving(delta: 1.1, duration: 0.5)
            // 항해하는 보트, 무심한 듯 시크한 듯 한번씩 지나가기
            DispatchQueue.main.asyncAfter(deadline: .now() + drand48()) {
                self.Sailing(duration: 60.5)
            }
            // 한번만 실행하기 위한 변수 설정
            onceShow = true
        }
        
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints([NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .top, multiplier: 1, constant: 0), NSLayoutConstraint(item: bannerView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)])
    }
    
    func stardustDroping() {
        let x_max = skyImageView.bounds.size.width + skyImageView.bounds.size.height - 200.0
        stardust_x = CGFloat(drand48()) * x_max + 100.0 // 범위는 100 ~ 400 까지
        stardust_duration = drand48() * 1.5 + 1.0 // 범위는 1.0 ~ 2.5 까지
        //print("startdust_x: \(stardust_x), stardust_duration: \(stardust_duration)")
        let stardustImageView = UIImageView(image: UIImage(named: "stardust"))
        stardustImageView.alpha = 0.0
        let sWidth = UIScreen.main.bounds.size.width * 0.2
        if stardust_x <= skyImageView.bounds.size.width {
            stardustImageView.frame = CGRect(x: stardust_x, y: 0, width: sWidth, height: sWidth)
        } else {
            stardustImageView.frame = CGRect(x: skyImageView.bounds.size.width, y: stardust_x - skyImageView.bounds.size.width, width: sWidth, height: sWidth)
            //print("1. stardustImageView_y : \(stardustImageView.frame.origin.y)")
        }
        // 바다 밑으로 떨어지도록 z축 설정
        stardustImageView.layer.zPosition = -2.0
        contentView.addSubview(stardustImageView)
        let y = stardust_x + stardustImageView.bounds.size.height
        if y <= skyImageView.frame.size.height {
            UIView.animate(withDuration: stardust_duration, delay: 0.8, options: [.curveEaseInOut], animations: {
                stardustImageView.frame.origin = CGPoint(x: -stardustImageView.frame.size.width, y: y)
                stardustImageView.alpha = 1.0
            }, completion: { finished in
                self.stardustDroping()
            })
        } else {
            UIView.animate(withDuration: stardust_duration, delay: 0.8, options: [.curveEaseInOut], animations: {
                stardustImageView.frame.origin = CGPoint(x: self.stardust_x - self.skyImageView.bounds.size.height, y: self.skyImageView.frame.size.height )
                //print("2. stardustImageView_y : \(stardustImageView.frame.origin.y)")
                stardustImageView.alpha = 1.0
            }, completion: { finished in
                self.stardustDroping()
            })
        }
    }
    
    func twinkle(duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.stars1ImageView.alpha = 0.3
            self.stars2ImageView.alpha = 1.0
        }, completion: { finished in
            self.stars1ImageView.alpha = 1.0
            self.stars2ImageView.alpha = 0.3
        })
    }
    
    func dreary(delta: CGFloat, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.cloud1ImageView.frame.origin = CGPoint(x: self.cloud1ImageView.frame.origin.x - delta, y: self.cloud1ImageView.frame.origin.y)
            self.cloud2ImageView.frame.origin = CGPoint(x: self.cloud2ImageView.frame.origin.x + delta, y: self.cloud2ImageView.frame.origin.y)
            self.cloud3ImageView.frame.origin = CGPoint(x: self.cloud3ImageView.frame.origin.x, y: self.cloud3ImageView.frame.origin.y - delta)
        }, completion: nil)
    }
    
    func waving(delta: CGFloat, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.seawaveImageView.frame.origin = CGPoint(x: self.seawaveImageView.frame.origin.x - delta, y: self.seawaveImageView.frame.origin.y)
        }, completion: nil)
    }
    
    func breathingMoon(scale: CGFloat, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.moonImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: { finished in
            self.moonImageView.transform = CGAffineTransform.identity
        })
    }
    
    func Sailing(duration: TimeInterval) {
        let boatImage = UIImage(named: "boat")
        let boatImageView = UIImageView(image: boatImage)
        boatImageView.frame.origin = CGPoint(x: UIScreen.main.bounds.size.width, y: seawaveImageView.frame.origin.y - (boatImageView.bounds.size.height * 0.5))
        contentView.addSubview(boatImageView)
        
        UIView.animate(withDuration: duration, delay: 0.5, options: [.curveEaseInOut], animations: {
            boatImageView.frame.origin.x = -UIScreen.main.bounds.size.width
        }, completion: { finished in
            boatImageView.removeFromSuperview()
        })
    }
    
    @IBAction func titleButtonTouch(_ sender: UIButton) {
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
    
    @IBAction func configButtonTouch(_ sender: UIButton) {
        touchPlaySound()
        menuView.isHidden = !menuView.isHidden
        menuViewTopMargin.constant = menuView.isHidden ? 0 : topView.bounds.height
        UIView.animate(withDuration: 0.3) {
            self.loadViewIfNeeded()
        }
    }
    
    
    @IBAction func selectButtonTouch(_ sender: UIButton) {
        touchPlaySound()
        selectDatePicker.isHidden = !selectDatePicker.isHidden
        // 광고가 있을 때와 없을때
        if isAdShow {
            datePickerTopMargin.constant = selectDatePicker.isHidden ? 0 : -(selectDatePicker.bounds.height + bannerHeight + 20)
            dateBottomMargin.constant = selectDatePicker.isHidden ? bannerHeight + 20 : selectDatePicker.bounds.height + 8 + bannerHeight + 20
        } else {
            datePickerTopMargin.constant = selectDatePicker.isHidden ? 0 : -selectDatePicker.bounds.height
            dateBottomMargin.constant = selectDatePicker.isHidden ? 20 : selectDatePicker.bounds.height + 8
        }
        
        UIView.animate(withDuration: 0.3) {
            self.loadViewIfNeeded()
        }
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        print(sender.direction)
        swipePlaySound()
        var dateComp = DateComponents()
        let x = moonImageView.frame.origin.x
        let y = moonImageView.frame.origin.y
        switch sender.direction {
        case [.left]:
            dateComp.day = 1
            UIView.animate(withDuration: 0.5, animations: {
                self.moonImageView.frame.origin.x += 5
            }) { finished in
                self.moonImageView.frame.origin.x = x
            }
        case [.right]:
            dateComp.day = -1
            UIView.animate(withDuration: 0.5, animations: {
                self.moonImageView.frame.origin.x -= 5
            }) { finished in
                self.moonImageView.frame.origin.x = x
            }
        case [.up]:
            dateComp.month = 1
            UIView.animate(withDuration: 0.5, animations: {
                self.moonImageView.frame.origin.y += 5
            }) { finished in
                self.moonImageView.frame.origin.y = y
            }
        case [.down]:
            dateComp.month = -1
            UIView.animate(withDuration: 0.5, animations: {
                self.moonImageView.frame.origin.y -= 5
            }) { finished in
                self.moonImageView.frame.origin.y = y
            }
        default:
            print("no select error")
        }
        
        selectDate = Calendar.current.date(byAdding: dateComp, to: selectDate)! // 날짜 계산
        locationManager.startUpdatingLocation() // 좌표 가져오기 시동
        selectDateMoonImageChanged(date: selectDate) // 이미지 변경
        selectDatePicker.date = selectDate // 어쩔지 모르니까 피커에 변경된 날짜 적용하기
    }
    
    fileprivate func selectDateMoonImageChanged(date: Date) {
        //
        let nMoon = NemesisMoon()
        let julian = nMoon.solarToJulian(date: date)
        let sunLng = nMoon.julianToSunLongitude(julian: julian)
        let moonLng = nMoon.julianToMoonLongitude(julian: julian)
        let lunar = nMoon.longitudeToLunarDay(sunLng: sunLng, moonLng: moonLng)
        let lunarDay = String(format: "%02d", lunar)
        //DispatchQueue.global().async {
            //let phase = nCalc.moonPhase(date: date).phase
            //let lunarDay = nCalc.phaseTolunarday(phase: phase)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0.01, options: [.curveEaseInOut], animations: {
                    self.moonImageView.image = UIImage(named: "b_moon_\(lunarDay)")
                    self.dateButton.setTitle(self.dateFormatter.string(from: date), for: .normal)
                }, completion: nil)
            }
        //}
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0.01, usingSpringWithDamping: 0.1, initialSpringVelocity: 5, options: [.curveLinear], animations: {
                self.dateButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: { (finished) in
                self.dateButton.transform = CGAffineTransform.identity
            })
        }
    }
    
    @IBAction func selectDatePickerChanged(_ sender: UIDatePicker) {
        selectDate = sender.date // 선택한 날짜 변수에 입력
        locationManager.startUpdatingLocation() // 좌표 가져오기 시동
        selectDateMoonImageChanged(date: selectDate)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last!
        if currentLocation.coordinate.longitude < 0 { // 그리니치에서 서쪽으론 음수이므로 이를 보정해줘야 정확한 값이 나온다.
            currentLocation = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: 360 - currentLocation.coordinate.longitude)
        }
        //print("currentLocation latitude \(currentLocation.coordinate.latitude) longitude \(currentLocation.coordinate.longitude)")
        locationManager.stopUpdatingLocation() // 갱신 했으니 좌표 가져오기 중단
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
    
    func swipePlaySound() {
        guard let url = Bundle.main.url(forResource: "swipe", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            swipePlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = swipePlayer else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // GADBannerViewDelegate
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceivedAD")
        // 광고가 표출되면 날짜 선택을 광고 위로 올린다.
        bannerHeight = bannerView.bounds.height
        dateBottomMargin.constant = bannerHeight + 20
        isAdShow = true
        addBannerViewToView(bannerView)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDayToCalendarSegue" {
            touchPlaySound()
            let dest = segue.destination as! CalendarViewController
            dest.selectDate = selectDate
        } else if segue.identifier == "goDayToAnimationSegue" {
            touchPlaySound()
            let dest = segue.destination as! AnimationViewController
            dest.selectDate = selectDate
        }
    }
}

