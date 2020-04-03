//
//  nCalc.swift
//  moonday
//
//  Created by softviewdidload on 2016. 3. 17..
//  Copyright © 2016년 softviewdidload. All rights reserved.
//
/*
 
 The MIT License (MIT)
 
 Copyright (c) 2015 Braindrizzle Studio
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import CoreLocation

struct nCalc {
    
    // 특성 및 상수
    /// The obliquity of Earth
    static let obliquityOfEarth = rad * 23.4397
    /// 도 > 라디안 변환
    static let rad = Double.pi / 180
    // 줄리안 데이트에 근접한 태양 근사치를 구하기 위한 값
    // See Table 6 of http://aa.quae.nl/en/reken/zonpositie.html
    static let J0 = 0.0009
    /// 2000.1.1. 줄리안 데이트
    static let J2000 = 2451545.0
    
    // 날짜 및 시간 계산
    // 2000.1.1. 일부터 계산하는 줄리안 값
    static func daysSinceJan12000 (date: Date) -> Double {
        return toJulian(date: date) - J2000
    }
    
    static func hoursLater (date: Date, hours: Double) -> Date {
        let hourSeconds = 60.0 * 60.0
        return Date(timeIntervalSince1970: date.timeIntervalSince1970 + hours * hourSeconds)
    }
    
    // Date 형식의 날짜를 입력하면 줄리안 데이트를 돌려 줌
    static func toJulian (date: Date) -> Double {
        let daySeconds: Double = 60 * 60 * 24
        let J1970 = 2440588.0
        let localTime = Double(TimeZone.current.secondsFromGMT() / 3600) / 12.0 //0.75 // 한국기준 +9 = 9/12 = 0.75, 그리니치 기준
        return date.timeIntervalSince1970/daySeconds + localTime + J1970
    }
    
    // 줄리안 데이트를 입력하면 Date 형식의 날짜를 돌려줌
    static func fromJulian (julianDays: Double) -> Date {
        let daySeconds : Double = 60 * 60 * 24
        let J1970 = 2440588.0
        let locatTime = Double(TimeZone.current.secondsFromGMT() / 3600) / 12.0 //0.75 // 한국기준
        return Date(timeIntervalSince1970: (julianDays - locatTime - J1970) * daySeconds)
    }
    
    // 고도 계산
    static func altitude (hourAngle: Double, latitude: Double, declination: Double) -> Double {
        return asin(sin(latitude) * sin(declination) + cos(latitude) * cos(declination) * cos(hourAngle))
    }
    
    // 방위각 계산인데 남점 기준, 현재는 북점 기준을 더 많이 사용, 수정 할 것
    static func azimuth (hourAngle: Double, latitude: Double, declination: Double) -> Double {
        return atan2(sin(hourAngle), cos(hourAngle) * sin(latitude) - tan(declination) * cos(latitude))
    }
    
    // 위도와 경도로 적위를 계산한다. 위/경도는 라디안 값
    static func declination (latitude: Double, longitude: Double) -> Double {
        return asin(sin(latitude) * cos(obliquityOfEarth) + cos(latitude) * sin(obliquityOfEarth) * sin(longitude))
    }
    
    // 위도와 경도로 적경을 계산한다. 위/경도는 라디안 값
    static func rightAscension (latitude: Double, longitude: Double) -> Double {
        return atan2(sin(longitude) * cos(obliquityOfEarth) - tan(latitude) * sin(obliquityOfEarth), cos(longitude))
    }
    
    static func siderealTime (daysSinceJan12000: Double, longitude: Double) -> Double {
        return rad * (280.16 + 360.9856235 * daysSinceJan12000) - longitude
    }
    
    // MARK: - Moon Calculations
    static func moonCoordinates (daysSinceJan12000: Double) -> (declination: Double, distance: Double, rightAscension: Double) {
        let eclipticLongitude = rad * (218.316 + 13.176396 * daysSinceJan12000)
        let meanAnomaly = rad * (134.963 + 13.064993 * daysSinceJan12000)
        let meanDistance = rad * (93.272 + 13.229350 * daysSinceJan12000)
        let longitude = eclipticLongitude + rad * 6.289 * sin(meanAnomaly)
        let latitude = rad * 5.128 * sin(meanDistance)
        let distance = 385001 - 20905 * cos(meanAnomaly)
        return (declination(latitude: latitude, longitude: longitude), distance, rightAscension(latitude: latitude, longitude: longitude))
    }
    
    static func moonPosition(date: Date, location: CLLocationCoordinate2D) -> (altitude: Double, azimuth: Double, distance: Double) {
        let longitude = rad * -location.longitude
        let phi = rad * location.latitude
        let days = daysSinceJan12000(date: date)
        let coordinates = moonCoordinates(daysSinceJan12000: days)
        let hourAngle = siderealTime(daysSinceJan12000: days, longitude: longitude) - coordinates.rightAscension
        var moonAltitude = altitude(hourAngle: hourAngle, latitude: phi, declination: coordinates.declination)
        moonAltitude = moonAltitude + rad * 0.017 / tan(moonAltitude + rad * 10.26 / (moonAltitude + rad * 5.10))
        //println("Time: \(date),mAltitude: \(moonAltitude / rad)")
        return (moonAltitude, azimuth(hourAngle: hourAngle, latitude: phi, declination: coordinates.declination), coordinates.distance)
    }
    
    static func moonPhase (date: Date) -> (fractionOfMoonIlluminated: Double, phase: Double, angle: Double) {
        let days = daysSinceJan12000(date: date)
        let sunCoords = sunCoordinates(daysSinceJan12000: days)
        let moonCoords = moonCoordinates(daysSinceJan12000: days)
        let sunDistance = 149598000.0   // 1 AU
        // Geocentric elongation of the Moon from the Sun
        let phi = acos(sin(sunCoords.declination) * sin(moonCoords.declination) + cos(sunCoords.declination) * cos(moonCoords.declination) * cos(sunCoords.rightAscension - moonCoords.rightAscension))
        // Selenocentric elongation of the Earth from the Sun
        let inc = atan2(sunDistance * sin(phi), moonCoords.distance - sunDistance * cos(phi))
        let angle = atan2(cos(sunCoords.declination) * sin(sunCoords.rightAscension - moonCoords.rightAscension), sin(sunCoords.declination) * cos(moonCoords.declination) - cos(sunCoords.declination) * sin(moonCoords.declination) * cos(sunCoords.rightAscension - moonCoords.rightAscension))
        let fractionOfMoonIlluminated = (1 + cos(inc)) / 2
        let phase = 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Double.pi
        return (fractionOfMoonIlluminated, phase, angle)
    }
    
    static func moonRiseAndSet (date: Date, location: CLLocationCoordinate2D) -> (rise: Date, set: Date) {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        let day = calendar.date(from: dateComponents)
        let hc = 0.133 * rad
        var h0 = moonPosition(date: day!, location: location).altitude - hc
        var rise : Double?
        var set : Double?
        var a:Double, b:Double, d:Double, h1:Double, h2:Double, roots:Int, xe:Double
        var x1 = 0.0, x2 = 0.0, ye = 0.0
        
        for i in [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23] {
            h1 = moonPosition(date: hoursLater(date: day!, hours: Double(i)), location: location).altitude - hc
            h2 = moonPosition(date: hoursLater(date: day!, hours: Double(i) + 1), location: location).altitude - hc
            a = (h0 + h2) / 2 - h1
            b = (h2 - h0) / 2
            xe = -b / (2 * a)
            ye = (a * xe + b) * xe + h1
            d = b * b - 4 * a * h1
            roots = 0
            if d >= 0 {
                let dx = sqrt(d) / (abs(a) * 2)
                x1 = xe - dx
                x2 = xe + dx
                if abs(x1) <= 1 { roots += 1 }
                if abs(x2) <= 1 { roots += 1 }
                if x1 < -1 { x1 = x2 }
            }
            if roots == 1 {
                if h0 < 0 {
                    rise = Double(i) + x1
                } else {
                    set = Double(i) + x1
                }
            } else if roots == 2 {
                rise = Double(i) + (ye < 0 ? x2 : x1)
                set = Double(i) + (ye < 0 ? x1 : x2)
            }
            //            if rise != nil && set != nil { break }
            h0 = h2
        }
        
        var result = (rise: day, set: day)
        if rise != nil { result.rise = hoursLater(date: day!, hours: rise!) }
        if set != nil { result.set = hoursLater(date: day!, hours: set!) }
        
        if rise == nil && set == nil {
            if ye > 0 {
                result.rise = Date.distantFuture
                result.set = Date.distantFuture
            } else {
                result.rise = Date.distantPast
                result.set = Date.distantPast
            }
        }
        
        return result as! (rise: Date, set: Date)
    }
    
    
    
    // MARK: - Sun Calculations
    static func approximateTransit (julianCycleNumber: Double, longitude: Double, targetHourAngle: Double) -> Double {
        return J0 + julianCycleNumber + (targetHourAngle + longitude) / (2 * Double.pi)
    }
    
    static func eclipticLongitude (meanAnomaly: Double) -> Double {
        // Equation of Center
        let center = rad * (1.9148 * sin(meanAnomaly) + 0.02 * sin(2 * meanAnomaly) + 0.0003 * sin(3 * meanAnomaly))
        // Perihelion of Earth
        let perihelion = rad * 102.9372
        return meanAnomaly + center + perihelion + Double.pi
    }
    
    static func hourAngle (altitude: Double, latitude: Double, declination: Double) -> Double {
        return acos((sin(altitude) - sin(latitude) * sin(declination)) / (cos(latitude) * cos(declination)))
    }
    
    static func julianCycle (daysSinceJan12000: Double, longitude: Double) -> Double {
        return round(daysSinceJan12000 - J0 - longitude / (2 * Double.pi))
    }
    
    static func julianSet (altitude: Double, declination: Double, latitude: Double, longitude: Double, julianCycleNumber: Double, meanAnomaly: Double, meanLongitude: Double) -> Double {
        let hrAngle = hourAngle(altitude: altitude, latitude: latitude, declination: declination)
        let approxTransit = approximateTransit(julianCycleNumber: julianCycleNumber, longitude: longitude, targetHourAngle: hrAngle)
        return julianSolarTransit(approximateTransit: approxTransit, longitude: meanLongitude, meanAnomaly: meanAnomaly)
    }
    
    static func julianSolarTransit (approximateTransit: Double, longitude: Double, meanAnomaly: Double) -> Double {
        return J2000 + approximateTransit + 0.0053 * sin(meanAnomaly) - 0.0069 * sin(2 * longitude)
    }
    
    
    static func solarMeanAnomaly (daysSinceJan12000: Double) -> Double {
        return rad * (357.5291 + 0.98560028 * daysSinceJan12000)
    }
    
    
    static func sunCoordinates (daysSinceJan12000: Double) -> (declination: Double, rightAscension: Double) {
        let solarMA = solarMeanAnomaly(daysSinceJan12000: daysSinceJan12000)
        let eLongitude = eclipticLongitude(meanAnomaly: solarMA)
        return (declination(latitude: 0, longitude: eLongitude), rightAscension(latitude: 0, longitude: eLongitude))
    }
    
    static func sunPosition (date: Date, location: CLLocationCoordinate2D) -> (altitude: Double, azimuth: Double) {
        let longitude = rad * -location.longitude
        let latitude = rad * location.latitude
        let days = daysSinceJan12000(date: date)
        let coordinates = sunCoordinates(daysSinceJan12000: days)
        let hourAngle = siderealTime(daysSinceJan12000: days, longitude: longitude) - coordinates.rightAscension
        return (altitude(hourAngle: hourAngle, latitude: latitude, declination: coordinates.declination),
                azimuth(hourAngle: hourAngle, latitude: latitude, declination: coordinates.declination))
    }
    
    
    static func sunRiseAndSet (date: Date, location: CLLocationCoordinate2D) -> (rise: Date, set: Date, solarNoon: Date, nadir: Date) {
        // Standard altitude of the end of sunrise and start of sunset
        let sunRiseEndSetStartAltitude = -0.3
        let longitude = rad * -location.longitude
        let latitude = rad * location.latitude
        let days = daysSinceJan12000(date: date)
        let julCycle = julianCycle(daysSinceJan12000: days, longitude: longitude)
        let approxTransit = approximateTransit(julianCycleNumber: julCycle, longitude: longitude, targetHourAngle: 0)
        let meanAnomaly = solarMeanAnomaly(daysSinceJan12000: days)
        let eclipLongitude = eclipticLongitude(meanAnomaly: meanAnomaly)
        let declinatn = declination(latitude: 0, longitude: eclipLongitude)
        let julianNoon = julianSolarTransit(approximateTransit: approxTransit, longitude: eclipLongitude, meanAnomaly: meanAnomaly)
        let solarNoon = fromJulian(julianDays: julianNoon)
        let nadir = fromJulian(julianDays: julianNoon - 0.5)
        //var result = (rise: date, set: date, solarNoon: solarNoon, nadir: nadir)
        //var julinSet:Double, julianRise:Double
        let julinSet = julianSet(altitude: rad * sunRiseEndSetStartAltitude,
                                 declination: declinatn,
                                 latitude: latitude,
                                 longitude: longitude,
                                 julianCycleNumber: julCycle,
                                 meanAnomaly: meanAnomaly,
                                 meanLongitude: eclipLongitude)
        
        let julianRise = julianNoon - (julinSet - julianNoon)
        //        result.rise = fromJulian(julianDays: julianRise)
        //        result.set = fromJulian(julianDays: julinSet)
        return (rise: fromJulian(julianDays: julianRise), set: fromJulian(julianDays: julinSet), solarNoon: solarNoon, nadir: nadir)
    }
    
    
    static func sunSignificantTimes (date: Date, location: CLLocationCoordinate2D) -> [String: Date] {
        // Various standard altitudes of the sun. Feel free to add your own times, in the same format, to this array--they'll be added to the returned dictionary.
        let times = [
            [-0.833, "sunriseStart", "sunsetEnd"],
            [-0.3, "sunriseEnd", "sunsetStart"],
            [-6.0, "dawn", "dusk"],
            [-12.0, "nauticalDawn", "nauticalDusk"],
            [-18.0, "nightEnd", "nightStart"],
            [6.0, "goldenHourEnd", "goldenHourStart"]
        ]
        
        let longitude = rad * -location.longitude
        let latitude = rad * location.latitude
        let days = daysSinceJan12000(date: date)
        let julCycle = julianCycle(daysSinceJan12000: days, longitude: longitude)
        let approxTransit = approximateTransit(julianCycleNumber: julCycle, longitude: longitude, targetHourAngle: 0)
        let meanAnomaly = solarMeanAnomaly(daysSinceJan12000: days)
        let eclipLongitude = eclipticLongitude(meanAnomaly: meanAnomaly)
        let declinatn = declination(latitude: 0, longitude: eclipLongitude)
        let julianNoon = julianSolarTransit(approximateTransit: approxTransit, longitude: eclipLongitude, meanAnomaly: meanAnomaly)
        var result = [String: Date]()
        //var i:Int, julianEnd=0.0, julianStart:Double, length:Int
        var julianEnd=0.0, julianStart:Double
        for i in 0..<times.count {
            let time = times[i]
            if let altitude = time[0] as? Double {
                julianEnd = julianSet(altitude: rad * altitude,
                                      declination: declinatn,
                                      latitude: latitude,
                                      longitude: longitude,
                                      julianCycleNumber: julCycle,
                                      meanAnomaly: meanAnomaly,
                                      meanLongitude: eclipLongitude)
            }
            
            julianStart = julianNoon - (julianEnd - julianNoon)
            if let earlierTime = time[1] as? String {
                result[earlierTime] = fromJulian(julianDays: julianStart)
            }
            if let laterTime = time[2] as? String {
                result[laterTime] = fromJulian(julianDays: julianEnd)
            }
        }
        return result
    }
    
    // moon Phase 값에 따라 01..30 이미지를 돌려줘서 달력 이미지 생성
    static func phaseTolunarday(phase: Double) -> String {
        return String(format: "%02d", Int(phase * 30 + 1))
    }
}

class NemesisMoon {
    func rev(x: Double) -> Double {
        var rv = x - trunc(x / 360.0) * 360.0
        if rv < 0 {
            rv += 360.0
        }
        return rv
    }
    
    func degreeToRadian(degree: Double) -> Double {
        return degree * Double.pi / 180.0
    }
    
    func radianToDegree(radian: Double) -> Double {
        return radian * 180 / Double.pi
    }
    
    func solarToJulian(date: Date) -> Double {
        let daySeconds: Double = 60 * 60 * 24
        let J1970 = 2440588.0
        // localTime -> 0.75, 한국기준 +9 = 9/12 = 0.75, 그리니치 기준
        let localTime = Double(TimeZone.current.secondsFromGMT() / 3600) / 12.0
        return date.timeIntervalSince1970/daySeconds + localTime + J1970
    }
    
    func julianToSunLongitude(julian:Double) -> Double {
        // UT 기준, 서울은 9시간 빠름
        // Timezone을 가져와서 UT로 변경해 줄것
        let D:Double = julian - 2451544.0
        let SUN_W:Double = 282.9404 + 0.0000470935 * D
        let SUN_E:Double = 0.016709 - 0.00000000151 * D
        var SUN_M:Double = 356.0470 + 0.9856002585 * D
        SUN_M = rev(x: SUN_M)
        let SUN_EC:Double = SUN_M + (180.0/Double.pi) * SUN_E * sin(degreeToRadian(degree: SUN_M)) * (1 + SUN_E * cos(degreeToRadian(degree: SUN_M)))
        let SUN_X:Double = cos(degreeToRadian(degree: SUN_EC)) - SUN_E
        let SUN_Y:Double = sin(degreeToRadian(degree: SUN_EC)) * sqrt(1 - SUN_E * SUN_E)
        let SUN_V:Double = radianToDegree(radian: atan2(degreeToRadian(degree: SUN_Y), degreeToRadian(degree: SUN_X)))
        
        return rev(x: SUN_V + SUN_W)
    }
    
    func julianToMoonLongitude(julian:Double) -> Double {
        // UT 기준, 서울은 9시간 빠름
        // Timezone을 가져와서 UT로 변경해 줄것
        let D:Double = julian - 2451544.0
        let MOON_N:Double = 125.1228 - 0.0529538083 * D
        let MOON_I:Double = 5.1454
        let MOON_W:Double = 318.0634 + 0.1643573223 * D
        let MOON_A:Double = 60.2666
        let MOON_E:Double = 0.0549
        var MOON_M:Double = 115.3654 + 13.0649929509 * D
        MOON_M = rev(x: MOON_M)
        var MOON_E0:Double = MOON_M + (180.0/Double.pi) * MOON_E * sin(degreeToRadian(degree: MOON_M)) * (1 + MOON_E * cos(degreeToRadian(degree: MOON_M)))
        var MOON_E1:Double = 0.0
        var MOON_E2:Double = 0.0
        repeat {
            MOON_E2 = MOON_E0
            MOON_E1 = MOON_E0 - (MOON_E0 - (180.0/Double.pi) * MOON_E * sin(degreeToRadian(degree: MOON_E0)) - MOON_M)/(1 - MOON_E * cos(degreeToRadian(degree: MOON_E0)))
            MOON_E0 = MOON_E1
        } while MOON_E1 - MOON_E2 > 0.005
        
        let MOON_X:Double = MOON_A * (cos(degreeToRadian(degree: MOON_E1)) - MOON_E)
        let MOON_Y:Double = MOON_A * sqrt(1 - MOON_E * MOON_E) * sin(degreeToRadian(degree: MOON_E1))
        let MOON_R:Double = sqrt((MOON_X * MOON_X) + (MOON_Y * MOON_Y))
        var MOON_V:Double = rev(x: radianToDegree(radian: atan2(degreeToRadian(degree: MOON_Y), degreeToRadian(degree: MOON_X))))
        let MOON_X_ECLIP:Double = MOON_R * (cos(degreeToRadian(degree: MOON_N)) * cos(degreeToRadian(degree: MOON_V + MOON_W)) - sin(degreeToRadian(degree: MOON_N)) * sin(degreeToRadian(degree: MOON_V + MOON_W)) * cos(degreeToRadian(degree: MOON_I)))
        let MOON_Y_ECLIP:Double = MOON_R * (sin(degreeToRadian(degree: MOON_N)) * cos(degreeToRadian(degree: MOON_V + MOON_W)) + cos(degreeToRadian(degree: MOON_N)) * sin(degreeToRadian(degree: MOON_V + MOON_W)) * cos(degreeToRadian(degree: MOON_I)))
        MOON_V = rev(x: radianToDegree(radian: atan2(degreeToRadian(degree: MOON_Y_ECLIP), degreeToRadian(degree: MOON_X_ECLIP))))
        let SUN_M:Double = rev(x: 356.047 + 0.9856002585 * D)
        let SUN_L:Double = rev(x: rev(x: 282.9404 + 0.0000470935 * D) + SUN_M)
        let MOON_L:Double = rev(x: MOON_N + MOON_W + MOON_M)
        let MOON_D:Double = MOON_L - SUN_L
        let MOON_F:Double = MOON_L - MOON_N
        let P1:Double = -1.274 * sin(degreeToRadian(degree: MOON_M) - 2 * degreeToRadian(degree: MOON_D))
        let P2:Double = 0.658 * sin(degreeToRadian(degree: MOON_D))
        let P3:Double = -0.186 * sin(degreeToRadian(degree: SUN_M))
        let P4:Double = -0.059 * sin(2 * degreeToRadian(degree: MOON_M) - 2 * degreeToRadian(degree: MOON_D))
        let P5:Double = -0.057 * sin(degreeToRadian(degree: MOON_M) - 2 * degreeToRadian(degree: MOON_D) + degreeToRadian(degree: SUN_M))
        let P6:Double = 0.053 * sin(degreeToRadian(degree: MOON_M) + 2 * degreeToRadian(degree: MOON_D))
        let P7:Double = 0.046 * sin(2 * degreeToRadian(degree: MOON_D) - degreeToRadian(degree: SUN_M))
        let P8:Double = 0.041 * sin(degreeToRadian(degree: MOON_M) - degreeToRadian(degree: SUN_M))
        let P9:Double = -0.035 * sin(degreeToRadian(degree: MOON_D));
        let P10:Double = -0.031 * sin(degreeToRadian(degree: MOON_M) + degreeToRadian(degree: SUN_M))
        let P11:Double = -0.015 * sin(2 * degreeToRadian(degree: MOON_F) - 2 * degreeToRadian(degree: MOON_D))
        let P12:Double = 0.011 * sin(degreeToRadian(degree: MOON_M) - 4 * degreeToRadian(degree: MOON_D))
        
        return MOON_V + P1 + P2 + P3 + P4 + P5 + P6 + P7 + P8 + P9 + P10 + P11 + P12
    }
    
    func longitudeToLunarDay(sunLng: Double, moonLng: Double) -> Int {
        var lunarDay = 0
        let difference = fabs(sunLng - moonLng)
        // 360도를 2로 나누면 180도 이고 이를 15로 나누면 12도이다. 각 값의 6도씩 빼거나 더하면 구간을 구할 수 있다.
        // 0 ~ 180까지는 달이 커가고 있고 180~ 360은 달이 작아지고 있음
        return lunarDay
    }
}

