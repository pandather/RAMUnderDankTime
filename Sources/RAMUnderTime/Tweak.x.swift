import Orion
import UIKit
import RAMUnderTimeC

struct sharedVars {
    
    var isNotchediPhone: Bool {
        return (!UIDevice.current.model.contains("iPad") && UIDevice.current.hasNotch)
    }
    
    var separatorText: String {
        return (isNotchediPhone) ? "\n" : " - "
    }
    
    var amountOfFreeRAM: String {
        return "\(separatorText)\(Int(memoryInfo.sharedInstance().get_free_memory())) MB"
    }
}

class StatusBarHook: ClassHook<UILabel> {
    @Property(.assign) var isUsingDotFormat: Bool = false
    @Property(.assign) var shouldUpdateTime: Bool = true
    
    static var targetName: String = "_UIStatusBarStringView"
    
    func initWithFrame(_ frame: CGRect) -> Target {
        let target = orig.initWithFrame(frame)
        
        NotificationCenter.default.addObserver(target, selector: #selector(updateText), name: Notification.Name("RUT_UpdateText"), object: nil)
        
        target.numberOfLines = 2
        target.textAlignment = NSTextAlignment.center
        
        return target
    }
    
    func setText(_ text: String) {
        
        var txt = text
        
        amIUsingDotTimeFormat(txt, separator: ".")
        
        if (txt.contains(":") || ((txt.contains(".") && self.isUsingDotFormat))) {
            
            if (txt.contains("MB")) {
                txt = txt.components(separatedBy: "\(sharedVars().separatorText)")[0]
            }

            var attributedString: NSMutableAttributedString
            var attributedString_secondComponent: NSAttributedString
            
            if (sharedVars().isNotchediPhone) {
                
                let firstAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13)]
                let secondAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10)]
                
                attributedString = NSMutableAttributedString(string: txt, attributes: firstAttributes)
                attributedString_secondComponent = NSAttributedString(string: sharedVars().amountOfFreeRAM, attributes: secondAttributes)
            
            } else {
                
                attributedString = NSMutableAttributedString(string: txt, attributes: nil)
                attributedString_secondComponent = NSAttributedString(string: sharedVars().amountOfFreeRAM, attributes: nil)
            
            }
            
            attributedString.append(attributedString_secondComponent)
            target.attributedText = attributedString
            
        } else {
            orig.setText(txt)
        }
    }
    
    func layoutSubviews() {
        orig.layoutSubviews()
        
        if (self.shouldUpdateTime) {
            
            amIUsingDotTimeFormat(target.text!, separator: ".")
            if (target.text!.contains(":") || ((target.text!.contains(".") && self.isUsingDotFormat))) {
                updateText()
                self.shouldUpdateTime = false
            }
        }
    }
    
    //orion: new
    func updateText() {
        
        amIUsingDotTimeFormat(target.text!, separator: ".")
        
        if (target.text!.contains(":") || ((target.text!.contains(".") && self.isUsingDotFormat))) {
            setText(target.text!)
        }
    }
    
    //orion: new
    func amIUsingDotTimeFormat(_ stringToSearch:String, separator:String) {
        let times = stringToSearch.components(separatedBy: separator).count - 1
        
        var isRussianiPadDateFormat = false
        if ((stringToSearch.components(separatedBy: " ").count - 1 == 2) && stringToSearch.contains(".")) {
            isRussianiPadDateFormat = true
        }
        
        if (times == 1 && !isRussianiPadDateFormat) {
            self.isUsingDotFormat = true
        } else {
            self.isUsingDotFormat = false
        }
    }
}

class SBHook: ClassHook<NSObject> {
    static var targetName: String = "SpringBoard"
    
    func frontDisplayDidChange(_ arg1: AnyObject) {
        orig.frontDisplayDidChange(arg1)
        NotificationCenter.default.post(name: NSNotification.Name("RUT_UpdateText"), object: nil)
    }
}

class CCHook: ClassHook<NSObject> {
    static var targetName: String = "SBIconController"
    
    func _controlCenterWillDismiss(_ arg1: AnyObject) {
        orig._controlCenterWillDismiss(arg1)
        NotificationCenter.default.post(name: NSNotification.Name("RUT_UpdateText"), object: nil)
    }
}

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}