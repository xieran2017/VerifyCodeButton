//
//  IdentifyingCodeButton.swift
//  test
//
//  Created by xie ran on 2017/6/12.
//  Copyright © 2017年 xie ran. All rights reserved.
//

import UIKit

// MARK: Timer Class
protocol IdentifyingCodeTimerProtocol : class {
    func timerHandlerTrigged(leftSeconds : Int)
}

public class IdentifyingCodeTimer : NSObject {
    
    static let sharedInstance = IdentifyingCodeTimer()
    
    static let totalSeconds = 60
    
    fileprivate override init() {}
    
    var leftTime = IdentifyingCodeTimer.totalSeconds
    
    weak var delegate : IdentifyingCodeTimerProtocol?
    
    var identifier : String = ""
    
    var sessionId = ""
    
    var dispatch_timer: DispatchSourceTimer?
    
    static func timer(ofIdentifier identifier: String) -> IdentifyingCodeTimer {
        
        var timer = objc_getAssociatedObject(IdentifyingCodeTimer.sharedInstance, UnsafeRawPointer.init(bitPattern: identifier.hashValue)!)

        if timer == nil {
            timer = IdentifyingCodeTimer()
            
            objc_setAssociatedObject(IdentifyingCodeTimer.sharedInstance, UnsafeRawPointer.init(bitPattern: identifier.hashValue)!, timer, .OBJC_ASSOCIATION_RETAIN)
        }
        
        return timer as! IdentifyingCodeTimer
    }
    
    func start() {
        if self.leftTime == IdentifyingCodeTimer.totalSeconds {
            createTimer()
        }
    }
    
    func createTimer() {
        dispatch_timer = DispatchSource.makeTimerSource(flags: [], queue:DispatchQueue.global())
        dispatch_timer?.setEventHandler {[weak self] in
            self?.leftTime -= 1

            guard self?.delegate != nil , let timeLeft = self?.leftTime else {
                return
            }
            
            //timer callback
            self?.delegate?.timerHandlerTrigged(leftSeconds: timeLeft)
            
            if timeLeft == 0 {
                self?.dispatch_timer?.cancel()
                
                self?.leftTime = IdentifyingCodeTimer.totalSeconds
                self?.sessionId = ""
                
                if let identifier = self?.identifier {
                    objc_setAssociatedObject(IdentifyingCodeTimer.sharedInstance, UnsafeRawPointer.init(bitPattern: identifier.hashValue)!, nil, .OBJC_ASSOCIATION_ASSIGN)
                }
            }
        }
        dispatch_timer?.schedule(deadline: .now(), repeating: 1)
        dispatch_timer?.resume()
    }
    
    static func resetTimer(ofIdentifier identifier: String) {
        let timer = objc_getAssociatedObject(IdentifyingCodeTimer.sharedInstance, UnsafeRawPointer.init(bitPattern: identifier.hashValue)!) as? IdentifyingCodeTimer

        if timer != nil && timer?.dispatch_timer != nil {
            timer?.sessionId = ""
            timer?.dispatch_timer?.cancel()
            objc_setAssociatedObject(IdentifyingCodeTimer.sharedInstance, UnsafeRawPointer.init(bitPattern: identifier.hashValue)!, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    var notStarted : Bool {
        return self.leftTime == IdentifyingCodeTimer.totalSeconds ? true : false
    }
}

enum VerifyCodeButtonState {
    case normal
    case sending
    case countingDown
    case resend
}

enum VerifyCodeButtonType {
    case withAttributeText
    case simple
}

public class VerifyCodeButton : UIButton , IdentifyingCodeTimerProtocol {
    var _state : VerifyCodeButtonState {
        didSet {
            switch _state {
            case .normal , .resend:
                self.isEnabled = true
                IdentifyingCodeTimer.resetTimer(ofIdentifier: self.identifier)
            case .countingDown:
                self.isEnabled = false
                start()
            case .sending:
                self.isEnabled = false
            }

            setAttributedTitle()
        }
    }
    var identifier: String
    var timeLeft = 0
    var phone: String?

    init(buttonType: VerifyCodeButtonType, identifier: String) {
        self.identifier = identifier
        self._state = .normal
        
        super.init(frame: .zero)
        
        self.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func buttonWithType(buttonType: VerifyCodeButtonType, identifier: String) -> VerifyCodeButton {
        switch buttonType {
        case .simple:
            return VerifyCodeSimpleButton.init(buttonType: buttonType, identifier: identifier)
        case .withAttributeText:
            return VerifyCodeAttributeTextButton.init(buttonType: buttonType, identifier: identifier)
        }
    }
    
    func timerHandlerTrigged(leftSeconds: Int) {
        self.timeLeft = leftSeconds
        
        DispatchQueue.main.async {
            if leftSeconds == 0 {
                self._state = .resend
            }
            
            self.setAttributedTitle()
        }
    }
    
    func setAttributedTitle() {
        
    }

    @discardableResult
    func start() -> IdentifyingCodeTimer {
        let timer = IdentifyingCodeTimer.timer(ofIdentifier: self.identifier)
        timer.identifier = self.identifier
        timer.start()
        timer.delegate = self as IdentifyingCodeTimerProtocol
        
        return timer
    }
}

// MARK: Attribute Text Button
private class VerifyCodeAttributeTextButton : VerifyCodeButton {
    let greyColor = UIColor.init(red: 153.0/255.0, green: 153.0/255.0, blue: 153.0/255.0, alpha: 1)
    let blueColor = UIColor.init(red: 32.0/255.0, green: 137.0/255.0, blue: 1.0, alpha: 1)
    let _font = UIScreen.main.bounds.width >= 375.0 ? UIFont.systemFont(ofSize: 14) : UIFont.systemFont(ofSize: 12)
    var vitualTimeStrWidth_long : CGFloat = 0.0
    var vitualTimeStrWidth_short : CGFloat = 0.0
    override var phone: String? {
        didSet {
            if phone != nil {
                setNeedsLayout()
            }
        }
    }

    override init(buttonType: VerifyCodeButtonType, identifier: String) {
        super.init(buttonType: buttonType, identifier: identifier)
        
        vitualTimeStrWidth_long = NSAttributedString(string: "99", attributes: [NSAttributedStringKey.font : _font]).size().width
        vitualTimeStrWidth_short = NSAttributedString(string: "0", attributes: [NSAttributedStringKey.font : _font]).size().width
        
        let timer = IdentifyingCodeTimer.timer(ofIdentifier: identifier)
        self.timeLeft = timer.leftTime
        
        if timer.leftTime > 0 && timer.leftTime < IdentifyingCodeTimer.totalSeconds {
            self._state = .countingDown
        } else {
            self._state = .resend
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {

        if self._state == .countingDown, phone != nil {

            /*draw 倒计时 title*/
            let vitualTimeStrWidth = self.timeLeft >= 10 ? vitualTimeStrWidth_long : vitualTimeStrWidth_short
            
            let prefixStr = NSAttributedString(string: "验证码已发送至" + phone! + "，", attributes: [NSAttributedStringKey.font : _font , NSAttributedStringKey.foregroundColor : greyColor])
            let timeStr = NSAttributedString(string: String(self.timeLeft), attributes: [NSAttributedStringKey.font : _font , NSAttributedStringKey.foregroundColor : blueColor])
            let suffixStr = NSMutableAttributedString(string: "S后请重新获取", attributes: [NSAttributedStringKey.font : _font])
            suffixStr.addAttributes([NSAttributedStringKey.foregroundColor : blueColor], range: NSRange(location: 0, length: 1))
            suffixStr.addAttributes([NSAttributedStringKey.foregroundColor : greyColor], range: NSRange.init(location: 1, length: suffixStr.length - 1))
            
            let totalWidth = prefixStr.size().width + suffixStr.size().width + vitualTimeStrWidth
            let height = max(prefixStr.size().height, suffixStr.size().height, timeStr.size().height)
            let horizonalMargin = (rect.width - totalWidth) / 2
            let topMargin = (rect.size.height - height) / 2
            
            prefixStr.draw(at: CGPoint(x: horizonalMargin, y: topMargin))
            timeStr.draw(at: CGPoint(x: horizonalMargin + totalWidth - suffixStr.size().width - timeStr.size().width - 2, y: topMargin))
            suffixStr.draw(at: CGPoint(x: horizonalMargin + prefixStr.size().width + vitualTimeStrWidth, y: topMargin))
            /***********/
            
        }
    
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let titleRect = self.titleRect(forContentRect: self.bounds)
        
        if point.x > titleRect.maxX - 55 && point.x <= titleRect.maxX && point.y >= titleRect.origin.y && point.y <= titleRect.maxY && self.isEnabled {
            return true
        }
        return false
    }
    
    override func setAttributedTitle() {
        
        let attrStr : NSMutableAttributedString!
        
        switch self._state {
        case .resend , .normal:
            attrStr = NSMutableAttributedString(string: "未收到验证码，请重新获取")
            attrStr.addAttributes([NSAttributedStringKey.foregroundColor : greyColor , NSAttributedStringKey.font : _font], range: NSRange(location: 0, length: attrStr.string.count))
            attrStr.addAttributes([NSAttributedStringKey.foregroundColor : blueColor], range: NSRange(location: 8, length: 4))
            self.setAttributedTitle(attrStr, for: .normal)
        case .countingDown:

            self.setAttributedTitle(nil, for: .normal)
            self.setAttributedTitle(nil, for: .disabled)
            self.setNeedsDisplay()
            
        case .sending:
            attrStr = NSMutableAttributedString(string: "正在获取...")
            attrStr.addAttributes([NSAttributedStringKey.font : _font , NSAttributedStringKey.foregroundColor : greyColor], range: NSRange(location: 0, length: attrStr.string.count))
            self.setAttributedTitle(attrStr, for: .disabled)
        }
    }
}

// MARK: Simple Button
private class VerifyCodeSimpleButton : VerifyCodeButton {

    override init(buttonType: VerifyCodeButtonType, identifier: String) {
        super.init(buttonType: buttonType, identifier: identifier)
        
        let timer = IdentifyingCodeTimer.timer(ofIdentifier: identifier)
        self.timeLeft = timer.leftTime
        
        self.setTitle("获取验证码", for: .normal)
        self.setTitle("\(timer.leftTime)" + " S", for: .disabled)
        
        self.setBackgroundImage(UIImage(named: "sms_code_fetch_border"), for: .normal)
        self.setBackgroundImage(UIImage(named: "sms_code_btn_disabled"), for: .disabled)
        self.setTitleColor(UIColor(red: 1, green: 102.0/255.0, blue: 0, alpha: 1), for: .normal)
        self.setTitleColor(UIColor(red: 170.0/255.0, green: 170.0/255.0, blue: 170.0/255.0, alpha: 1), for: .disabled)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        if timer.leftTime > 0 && timer.leftTime < IdentifyingCodeTimer.totalSeconds {
            self._state = .countingDown
        } else {
            self._state = .normal
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setAttributedTitle() {
        switch _state {
        case .normal:
            self.setTitle("获取验证码", for: .normal)
        case .resend:
            self.setTitle("重新获取", for: .normal)
        case .countingDown:            
            self.setTitle("\(self.timeLeft)" + " S", for: .disabled)
        case .sending:
            self.setTitle("正在获取...", for: .disabled)
        }
    }
}
