//
//  SCLAlertView.swift
//  SCLAlertView Example
//
//  Created by Viktor Radchenko on 6/5/14.
//  Copyright (c) 2014 Viktor Radchenko. All rights reserved.
//

import Foundation
import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// Pop Up Styles
public enum SCLAlertViewStyle {
    case success, error, notice, warning, info, edit, wait, question
    
    public var defaultColor: UIColor {
        switch self {
        case .success:
            return UIColorFromRGB(0x22B573)
        case .error:
            return .init(light: UIColorFromRGB(0xC1272D), dark: .red)
        case .notice:
            return .init(light: UIColorFromRGB(0x727375), dark: UIColorFromRGB(0xC6C6C6))
        case .warning:
            return UIColorFromRGB(0xFFD110)
        case .info:
            return .init(light: UIColorFromRGB(0x2866BF), dark: UIColorFromRGB(0x6ABCE7))
        case .edit:
            return .init(light: UIColorFromRGB(0xA429FF), dark: UIColorFromRGB(0xD194FF))
        case .wait:
            return UIColorFromRGB(0xD62DA5)
        case .question:
            return .init(light: UIColorFromRGB(0x727375), dark: UIColorFromRGB(0xBABABA))
        }
        
    }

}

// Animation Styles
public enum SCLAnimationStyle {
    case noAnimation, topToBottom, bottomToTop, leftToRight, rightToLeft
}

// Action Types
public enum SCLActionType {
    case none, selector, closure
}

public enum SCLAlertButtonLayout {
    case horizontal, vertical
}
// Button sub-class
open class SCLButton: UIButton {
    var actionType = SCLActionType.none
    var target:AnyObject!
    var selector:Selector!
    var action:(()->Void)!
    var customBackgroundColor:UIColor?
    var customTextColor:UIColor?
    var initialTitle:String!
    var showTimeout:ShowTimeoutConfiguration?
    
    public struct ShowTimeoutConfiguration {
        let prefix: String
        let suffix: String
        
        public init(prefix: String = "", suffix: String = "") {
            self.prefix = prefix
            self.suffix = suffix
        }
    }
    
    public init() {
        super.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override public init(frame:CGRect) {
        super.init(frame:frame)
    }
}

// Allow alerts to be closed/renamed in a chainable manner
// Example: SCLAlertView().showSuccess(self, title: "Test", subTitle: "Value").close()
open class SCLAlertViewResponder {
    let alertview: SCLAlertView
    
    // Initialisation and Title/Subtitle/Close functions
    public init(alertview: SCLAlertView) {
        self.alertview = alertview
    }
    
    open func setTitle(_ title: String) {
        self.alertview.labelTitle.text = title
    }
    
    open func setSubTitle(_ subTitle: String?) {
      self.alertview.viewText.text = subTitle != nil ? subTitle : ""
    }
    
    open func setSubAttributedTitle(_ subTitle: NSAttributedString) {
      self.alertview.viewText.attributedText = subTitle
    }
    
    open func close() {
        self.alertview.hideView()
    }
    
    open func setDismissBlock(_ dismissBlock: @escaping DismissBlock) {
        self.alertview.dismissBlock = dismissBlock
    }
}

let kCircleHeightBackground: CGFloat = 62.0
let uniqueTag: Int = Int(arc4random() % UInt32(Int32.max))
let uniqueAccessibilityIdentifier: String = "SCLAlertView"

public typealias DismissBlock = () -> Void

// The Main Class
open class SCLAlertView: UIViewController {
    
    public struct SCLAppearance {
        let kDefaultShadowOpacity: CGFloat
        let kCircleTopPosition: CGFloat
        let kCircleBackgroundTopPosition: CGFloat
        let kCircleHeight: CGFloat
        let kCircleIconHeight: CGFloat
        let kTitleHeight:CGFloat
	let kTitleMinimumScaleFactor: CGFloat
        let kWindowWidth: CGFloat
        var kWindowHeight: CGFloat
        var kTextHeight: CGFloat
        let kTextFieldHeight: CGFloat
        let kTextViewdHeight: CGFloat
        let kButtonHeight: CGFloat
		let circleBackgroundColor: UIColor
        let contentViewColor: UIColor
        let contentViewBorderColor: UIColor
        let titleColor: UIColor
        let subTitleColor: UIColor

        let margin: Margin
        /// Margin for SCLAlertView.
        public struct Margin {
          //vertical
          
          /// The spacing between title's top and window's top.
          public var titleTop: CGFloat
          /// The spacing between textView/customView's bottom and first button's top.
          public var textViewBottom: CGFloat
          /// The spacing between buttons.
          public var buttonSpacing: CGFloat
          /// The spacing between textField.
          public var textFieldSpacing: CGFloat
          /// The last button's bottom margin against alertView's bottom
          public var bottom: CGFloat
          
          //Horizontal
          /// The subView's horizontal margin.
          public var horizontal: CGFloat = 12
        
          public init(titleTop: CGFloat = 30,
                      textViewBottom: CGFloat = 12,
                      buttonSpacing: CGFloat = 10,
                      textFieldSpacing: CGFloat = 15,
                      bottom: CGFloat = 14,
                      horizontal: CGFloat = 12) {
            self.titleTop = titleTop
            self.textViewBottom = textViewBottom
            self.buttonSpacing = buttonSpacing
            self.textFieldSpacing = textFieldSpacing
            self.bottom = bottom
            self.horizontal = horizontal
          }
        }

        // Fonts
        let kTitleFont: UIFont
        let kTextFont: UIFont
        let kButtonFont: UIFont
        
        // UI Options
        var disableTapGesture: Bool
        var showCloseButton: Bool
        var showCircularIcon: Bool
        var shouldAutoDismiss: Bool // Set this false to 'Disable' Auto hideView when SCLButton is tapped
        var contentViewCornerRadius : CGFloat
        var fieldCornerRadius : CGFloat
        var buttonCornerRadius : CGFloat
        var dynamicAnimatorActive : Bool
        var buttonsLayout: SCLAlertButtonLayout
        var textViewAlignment: NSTextAlignment = .center
        
        // Actions
        var hideWhenBackgroundViewIsTapped: Bool
        
        // Activity indicator
        var activityIndicatorStyle: UIActivityIndicatorView.Style
        
        public init(kDefaultShadowOpacity: CGFloat = 0.7, kCircleTopPosition: CGFloat = 0.0, kCircleBackgroundTopPosition: CGFloat = 6.0, kCircleHeight: CGFloat = 56.0, kCircleIconHeight: CGFloat = 20.0, kTitleHeight:CGFloat = 25.0,  kWindowWidth: CGFloat = 240.0, kWindowHeight: CGFloat = 178.0, kTextHeight: CGFloat = 90.0, kTextFieldHeight: CGFloat = 30.0, kTextViewdHeight: CGFloat = 80.0, kButtonHeight: CGFloat = 35.0, kTitleFont: UIFont = UIFont.systemFont(ofSize: 20), kTitleMinimumScaleFactor: CGFloat = 1.0, kTextFont: UIFont = UIFont.systemFont(ofSize: 14), kButtonFont: UIFont = UIFont.boldSystemFont(ofSize: 14), showCloseButton: Bool = true, showCircularIcon: Bool = true, shouldAutoDismiss: Bool = true, contentViewCornerRadius: CGFloat = 5.0, fieldCornerRadius: CGFloat = 3.0, buttonCornerRadius: CGFloat = 3.0, hideWhenBackgroundViewIsTapped: Bool = false, circleBackgroundColor: UIColor? = nil, contentViewColor: UIColor? = nil, contentViewBorderColor: UIColor = UIColorFromRGB(0xCCCCCC), titleColor: UIColor? = nil, subTitleColor: UIColor? = nil, margin: Margin = Margin(), dynamicAnimatorActive: Bool = false, disableTapGesture: Bool = false, buttonsLayout: SCLAlertButtonLayout = .vertical, activityIndicatorStyle: UIActivityIndicatorView.Style = UIActivityIndicatorView.Style.medium, textViewAlignment: NSTextAlignment = .center) {
            
            self.kDefaultShadowOpacity = kDefaultShadowOpacity
            self.kCircleTopPosition = kCircleTopPosition
            self.kCircleBackgroundTopPosition = kCircleBackgroundTopPosition
            self.kCircleHeight = kCircleHeight
            self.kCircleIconHeight = kCircleIconHeight
            self.kTitleHeight = kTitleHeight
            self.kWindowWidth = kWindowWidth
            self.kWindowHeight = kWindowHeight
            self.kTextHeight = kTextHeight
            self.kTextFieldHeight = kTextFieldHeight
            self.kTextViewdHeight = kTextViewdHeight
            self.kButtonHeight = kButtonHeight
            self.circleBackgroundColor = circleBackgroundColor ?? .defaultBackgroundColor
            self.contentViewColor = contentViewColor ?? .defaultBackgroundColor
            self.contentViewBorderColor = contentViewBorderColor
            self.titleColor = titleColor ?? .defaultTitleColor
            self.subTitleColor = subTitleColor ?? .defaultSubTitleColor
        
            self.margin = margin
        
            self.kTitleFont = kTitleFont
            self.kTitleMinimumScaleFactor = kTitleMinimumScaleFactor
            self.kTextFont = kTextFont
            self.kButtonFont = kButtonFont
            
            self.disableTapGesture = disableTapGesture
            self.showCloseButton = showCloseButton
            self.showCircularIcon = showCircularIcon
            self.shouldAutoDismiss = shouldAutoDismiss
            self.contentViewCornerRadius = contentViewCornerRadius
            self.fieldCornerRadius = fieldCornerRadius
            self.buttonCornerRadius = buttonCornerRadius
            
            self.hideWhenBackgroundViewIsTapped = hideWhenBackgroundViewIsTapped
            self.dynamicAnimatorActive = dynamicAnimatorActive
            self.buttonsLayout = buttonsLayout
            
            self.activityIndicatorStyle = activityIndicatorStyle
            
            self.textViewAlignment = textViewAlignment
        }
        
        mutating func setkWindowHeight(_ kWindowHeight:CGFloat) {
            self.kWindowHeight = kWindowHeight
        }
        
        mutating func setkTextHeight(_ kTextHeight:CGFloat) {
            self.kTextHeight = kTextHeight
        }
    }
    
    public struct SCLTimeoutConfiguration {
        
        public typealias ActionType = () -> Void
        
        var value: TimeInterval
        let action: ActionType
        
        mutating func increaseValue(by: Double) {
            self.value = value + by
        }
        
        public init(timeoutValue: TimeInterval, timeoutAction: @escaping ActionType) {
            self.value = timeoutValue
            self.action = timeoutAction
        }
        
    }
    
    var appearance: SCLAppearance!
    
    // UI Colour
    var viewColor = UIColor()
    
    // UI Options
    open var iconTintColor: UIColor?
    open var customSubview : UIView?
    
    open var textViewDelegate : UITextViewDelegate? {
        didSet {
            viewText.delegate = textViewDelegate
            viewText.isEditable = textViewDelegate != nil
        }
    }
    
    // Members declaration
    var baseView = UIView()
    var labelTitle = UILabel()
    var viewText = UITextView()
    var contentView = UIView()
    var circleBG = UIView(frame:CGRect(x:0, y:0, width:kCircleHeightBackground, height:kCircleHeightBackground))
    var circleView = UIView()
    var circleIconView : UIView?
    var timeout: SCLTimeoutConfiguration?
    var showTimeoutTimer: Timer?
    var timeoutTimer: Timer?
    var dismissBlock : DismissBlock?
    fileprivate var inputs = [UITextField]()
    fileprivate var input = [UITextView]()
    internal var buttons = [SCLButton]()
    fileprivate var selfReference: SCLAlertView?
    private var style: SCLAlertViewStyle!
    private var isUsingDefaultIconImage = true
    private var window: UIWindow!
    
    public init(appearance: SCLAppearance) {
        self.appearance = appearance
        super.init(nibName:nil, bundle:nil)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    required public init() {
        appearance = SCLAppearance()
        super.init(nibName:nil, bundle:nil)
        setup()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        if appearance == nil {
            appearance = SCLAppearance()
        }
        
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    fileprivate func setup() {
        // Set up main view
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: isShowing() ? 0 : appearance.kDefaultShadowOpacity)
        view.addSubview(baseView)
        // Base View
        baseView.frame = view.frame
        baseView.addSubview(contentView)
        // Content View
        contentView.layer.cornerRadius = appearance.contentViewCornerRadius
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.addSubview(labelTitle)
        contentView.addSubview(viewText)
        // Circle View
        circleBG.backgroundColor = appearance.circleBackgroundColor
        circleBG.layer.cornerRadius = circleBG.frame.size.height / 2
        baseView.addSubview(circleBG)
        circleBG.addSubview(circleView)
        let x = (kCircleHeightBackground - appearance.kCircleHeight) / 2
        circleView.frame = CGRect(x:x, y:x+appearance.kCircleTopPosition, width:appearance.kCircleHeight, height:appearance.kCircleHeight)
        circleView.layer.cornerRadius = circleView.frame.size.height / 2
        // Title
        labelTitle.numberOfLines = 0
        labelTitle.textAlignment = .center
        labelTitle.font = appearance.kTitleFont
        if(appearance.kTitleMinimumScaleFactor < 1){
            labelTitle.minimumScaleFactor = appearance.kTitleMinimumScaleFactor
            labelTitle.adjustsFontSizeToFitWidth = true
        }
        labelTitle.frame = CGRect(x:appearance.margin.horizontal, y:appearance.margin.titleTop, width: subViewsWidth, height:appearance.kTitleHeight)
        // View text
        viewText.isEditable = false
        viewText.isSelectable = false
        viewText.textAlignment = appearance.textViewAlignment
        viewText.textContainerInset = UIEdgeInsets.zero
        viewText.textContainer.lineFragmentPadding = 0;
        viewText.font = appearance.kTextFont
        // Colours
        contentView.backgroundColor = appearance.contentViewColor
        viewText.backgroundColor = appearance.contentViewColor
        labelTitle.textColor = appearance.titleColor
        viewText.textColor = appearance.subTitleColor
        contentView.layer.borderColor = appearance.contentViewBorderColor.cgColor
        //Gesture Recognizer for tapping outside the textinput
        if appearance.disableTapGesture == false {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SCLAlertView.tapped(_:)))
            tapGesture.numberOfTapsRequired = 1
            self.view.addGestureRecognizer(tapGesture)
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
   
        guard !keyboardHasBeenShown else {
            return
        }
	    
        let sz = window.frame.size
        
        // Set background frame
        view.frame.size = sz

        let defaultTopOffset: CGFloat = 32

        // get actual height of title text
        var titleActualHeight: CGFloat = 0
        if let title = labelTitle.text {
          titleActualHeight = title.heightWithConstrainedWidth(width: subViewsWidth, font: labelTitle.font) + 10
          // get the larger height for the title text
          titleActualHeight = (titleActualHeight > appearance.kTitleHeight ? titleActualHeight : appearance.kTitleHeight)
        }

        // computing the right size to use for the textView
        let maxHeight = sz.height - 100 // max overall height
        var consumedHeight = CGFloat(0)
        consumedHeight += (titleActualHeight > 0 ? appearance.margin.titleTop + titleActualHeight : defaultTopOffset)
        consumedHeight += appearance.margin.bottom
        
        let buttonMargin = appearance.margin.buttonSpacing
        let textFieldMargin = appearance.margin.textFieldSpacing
        if appearance.buttonsLayout == .vertical {
            consumedHeight += appearance.kButtonHeight * CGFloat(buttons.count)
            consumedHeight += buttonMargin * (CGFloat(buttons.count) - 1)
        } else {
            consumedHeight += appearance.kButtonHeight
        }
        consumedHeight += (appearance.kTextFieldHeight + textFieldMargin) * CGFloat(inputs.count)
        consumedHeight += appearance.kTextViewdHeight * CGFloat(input.count)
        let maxViewTextHeight = maxHeight - consumedHeight
        let viewTextWidth = subViewsWidth
        var viewTextHeight = appearance.kTextHeight
        
        // Check if there is a custom subview and add it over the textview
        if let customSubview = customSubview {
            viewTextHeight = min(customSubview.frame.height, maxViewTextHeight)
            viewText.text = ""
            viewText.addSubview(customSubview)
        } else if viewText.text.isEmpty {
            viewTextHeight = 0
        } else {
            // computing the right size to use for the textView
            let suggestedViewTextSize = viewText.sizeThatFits(CGSize(width: viewTextWidth, height: CGFloat.greatestFiniteMagnitude))
            viewTextHeight = min(suggestedViewTextSize.height, maxViewTextHeight)
            
            // scroll management
            if (suggestedViewTextSize.height > maxViewTextHeight) {
                viewText.isScrollEnabled = true
            } else {
                viewText.isScrollEnabled = false
            }
        }
        
        var windowHeight = consumedHeight + viewTextHeight
        windowHeight += viewText.text.isEmpty ? 0 : appearance.margin.textViewBottom // only viewText.text is not empty should have margin.

        // Set frames
        var x = (sz.width - appearance.kWindowWidth) / 2
        var y = (sz.height - windowHeight - (appearance.kCircleHeight / 8)) / 2
        contentView.frame = CGRect(x:x, y:y, width:appearance.kWindowWidth, height:windowHeight)
        contentView.layer.cornerRadius = appearance.contentViewCornerRadius
        y -= kCircleHeightBackground * 0.6
        x = (sz.width - kCircleHeightBackground) / 2
        circleBG.frame = CGRect(x:x, y:y+appearance.kCircleBackgroundTopPosition, width:kCircleHeightBackground, height:kCircleHeightBackground)
        
        //adjust Title frame based on circularIcon show/hide flag
//        let titleOffset : CGFloat = appearance.showCircularIcon ? 0.0 : -12.0
        let titleOffset: CGFloat = 0
        labelTitle.frame = labelTitle.frame.offsetBy(dx: 0, dy: titleOffset)
        
        // Subtitle
        y = titleActualHeight > 0 ? appearance.margin.titleTop + titleActualHeight + titleOffset : defaultTopOffset
        viewText.frame = CGRect(x:appearance.margin.horizontal, y:y, width: viewTextWidth, height:viewTextHeight)
        // Text fields
        y += viewTextHeight
        y += viewText.text.isEmpty ? 0 : appearance.margin.textViewBottom // only viewText.text is not empty should have margin.
      
        for txt in inputs {
            txt.frame = CGRect(x:appearance.margin.horizontal, y:y, width:subViewsWidth, height:appearance.kTextFieldHeight)
            txt.layer.cornerRadius = appearance.fieldCornerRadius
            y += appearance.kTextFieldHeight + textFieldMargin
        }
        for txt in input {
            txt.frame = CGRect(x:appearance.margin.horizontal, y:y, width:subViewsWidth, height:appearance.kTextViewdHeight - appearance.margin.textViewBottom)
            //txt.layer.cornerRadius = fieldCornerRadius
            y += appearance.kTextViewdHeight
        }
        // Buttons
        var buttonX = appearance.margin.horizontal
        switch appearance.buttonsLayout {
        case .vertical:
            for btn in buttons {
                btn.frame = CGRect(x:buttonX, y:y, width:subViewsWidth, height:appearance.kButtonHeight)
                btn.layer.cornerRadius = appearance.buttonCornerRadius
                y += appearance.kButtonHeight + buttonMargin
            }
        case .horizontal:
          let numberOfButton = CGFloat(buttons.count)
          let buttonsSpace = numberOfButton >= 1 ? CGFloat(10) * (numberOfButton - 1) : 0
          let widthEachButton = (subViewsWidth - buttonsSpace) / numberOfButton
            for btn in buttons {
                btn.frame = CGRect(x:buttonX, y:y, width: widthEachButton, height:appearance.kButtonHeight)
                btn.layer.cornerRadius = appearance.buttonCornerRadius
                buttonX += widthEachButton
                buttonX += buttonsSpace
            }
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(SCLAlertView.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(SCLAlertView.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override open func touchesEnded(_ touches:Set<UITouch>, with event:UIEvent?) {
        if event?.touches(for: view)?.count > 0 {
            view.endEditing(true)
        }
    }
    
    open func addTextField(_ title:String?=nil)->UITextField {
        // Update view height
        appearance.setkWindowHeight(appearance.kWindowHeight + appearance.kTextFieldHeight)
        // Add text field
        let txt = UITextField()
        txt.borderStyle = UITextField.BorderStyle.roundedRect
        txt.font = appearance.kTextFont
        txt.autocapitalizationType = UITextAutocapitalizationType.words
        txt.clearButtonMode = UITextField.ViewMode.whileEditing
        
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        
        if title != nil {
            txt.placeholder = title!
        }
        
        contentView.addSubview(txt)
        inputs.append(txt)
        return txt
    }
    
    open func addTextView()->UITextView {
        // Update view height
        appearance.setkWindowHeight(appearance.kWindowHeight + appearance.kTextViewdHeight)
        // Add text view
        let txt = UITextView()
        // No placeholder with UITextView but you can use KMPlaceholderTextView library 
        txt.font = appearance.kTextFont
        //txt.autocapitalizationType = UITextAutocapitalizationType.Words
        //txt.clearButtonMode = UITextFieldViewMode.WhileEditing
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        contentView.addSubview(txt)
        input.append(txt)
        return txt
    }
    
    @discardableResult
    open func addButton(_ title:String, backgroundColor:UIColor? = nil, textColor:UIColor? = nil, showTimeout:SCLButton.ShowTimeoutConfiguration? = nil, action:@escaping ()->Void)->SCLButton {
        let btn = addButton(title, backgroundColor: backgroundColor, textColor: textColor, showTimeout: showTimeout)
        btn.actionType = SCLActionType.closure
        btn.action = action
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapped(_:)), for:.touchUpInside)
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapDown(_:)), for:[.touchDown, .touchDragEnter])
        btn.addTarget(self, action:#selector(SCLAlertView.buttonRelease(_:)), for:[.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside] )
        return btn
    }
    
    @discardableResult
    open func addButton(_ title:String, backgroundColor:UIColor? = nil, textColor:UIColor? = nil, showTimeout:SCLButton.ShowTimeoutConfiguration? = nil, target:AnyObject, selector:Selector)->SCLButton {
        let btn = addButton(title, backgroundColor: backgroundColor, textColor: textColor, showTimeout: showTimeout)
        btn.actionType = SCLActionType.selector
        btn.target = target
        btn.selector = selector
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapped(_:)), for:.touchUpInside)
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapDown(_:)), for:[.touchDown, .touchDragEnter])
        btn.addTarget(self, action:#selector(SCLAlertView.buttonRelease(_:)), for:[.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside] )
        return btn
    }
    
    @discardableResult
    fileprivate func addButton(_ title:String, backgroundColor:UIColor? = nil, textColor:UIColor? = nil, showTimeout:SCLButton.ShowTimeoutConfiguration? = nil)->SCLButton {
        // Update view height
        appearance.setkWindowHeight(appearance.kWindowHeight + appearance.kButtonHeight)
        
        // Add button
        let btn = SCLButton()
        btn.layer.masksToBounds = true
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = appearance.kButtonFont
        btn.customBackgroundColor = backgroundColor
        btn.customTextColor = textColor
        btn.initialTitle = title
        btn.showTimeout = showTimeout
        contentView.addSubview(btn)
        buttons.append(btn)
        return btn
    }
    
    @objc func buttonTapped(_ btn:SCLButton) {
        if btn.actionType == SCLActionType.closure {
            btn.action()
        } else if btn.actionType == SCLActionType.selector {
            let ctrl = UIControl()
            ctrl.sendAction(btn.selector, to:btn.target, for:nil)
        } else {
            print("Unknow action type for button")
        }
        
        if(self.view.alpha != 0.0 && appearance.shouldAutoDismiss){ hideView() }
    }
    
    
    @objc func buttonTapDown(_ btn:SCLButton) {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0
        let pressBrightnessFactor = 0.85
        btn.backgroundColor?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness = brightness * CGFloat(pressBrightnessFactor)
        btn.backgroundColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    @objc func buttonRelease(_ btn:SCLButton) {
        btn.backgroundColor = btn.customBackgroundColor ?? viewColor
    }
    
    var tmpContentViewFrameOrigin: CGPoint?
    var tmpCircleViewFrameOrigin: CGPoint?
    var keyboardHasBeenShown:Bool = false
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardHasBeenShown = true
        
        guard let userInfo = (notification as NSNotification).userInfo else {return}
        guard let endKeyBoardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.minY else {return}
        
        if tmpContentViewFrameOrigin == nil {
            tmpContentViewFrameOrigin = self.contentView.frame.origin
        }
        
        if tmpCircleViewFrameOrigin == nil {
            tmpCircleViewFrameOrigin = self.circleBG.frame.origin
        }
        
        var newContentViewFrameY = self.contentView.frame.maxY - endKeyBoardFrame
        if newContentViewFrameY < 0 {
            newContentViewFrameY = 0
        }
        
        let newBallViewFrameY = self.circleBG.frame.origin.y - newContentViewFrameY
        self.contentView.frame.origin.y -= newContentViewFrameY
        self.circleBG.frame.origin.y = newBallViewFrameY
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if(keyboardHasBeenShown){//This could happen on the simulator (keyboard will be hidden)
            if(self.tmpContentViewFrameOrigin != nil){
                self.contentView.frame.origin.y = self.tmpContentViewFrameOrigin!.y
                self.tmpContentViewFrameOrigin = nil
            }
            if(self.tmpCircleViewFrameOrigin != nil){
                self.circleBG.frame.origin.y = self.tmpCircleViewFrameOrigin!.y
                self.tmpCircleViewFrameOrigin = nil
            }
            
            keyboardHasBeenShown = false
        }
    }
    
    //Dismiss keyboard when tapped outside textfield & close SCLAlertView when hideWhenBackgroundViewIsTapped
    @objc func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        if let tappedView = gestureRecognizer.view , tappedView.hitTest(gestureRecognizer.location(in: tappedView), with: nil) == baseView && appearance.hideWhenBackgroundViewIsTapped {
            
            hideView()
        }
    }
    
    // showCustom(view, title, subTitle, UIColor, UIImage)
    @discardableResult
    open func showCustom(_ title: String, subTitle: String? = nil, color: UIColor, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .success, colorStyle: color, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showCustom(_ title: String, subTitle: NSAttributedString? = nil, color: UIColor, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .success, colorStyle: color, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    
    // showSuccess(view, title, subTitle)
    @discardableResult
    open func showSuccess(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.success.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .success, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showSuccess(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.success.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .success, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showError(view, title, subTitle)
    @discardableResult
    open func showError(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.error.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .error, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showError(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.error.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .error, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showNotice(view, title, subTitle)
    @discardableResult
    open func showNotice(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.notice.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .notice, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showNotice(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.notice.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .notice, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showWarning(view, title, subTitle)
    @discardableResult
    open func showWarning(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.warning.defaultColor, colorTextButton: UIColor = .black, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .warning, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showWarning(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.warning.defaultColor, colorTextButton: UIColor = .black, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .warning, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showInfo(view, title, subTitle)
    @discardableResult
    open func showInfo(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.info.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .info, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showInfo(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.info.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .info, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showWait(view, title, subTitle)
    @discardableResult
    open func showWait(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor?=SCLAlertViewStyle.wait.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .wait, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showWait(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor?=SCLAlertViewStyle.wait.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .wait, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    @discardableResult
    open func showEdit(_ title: String, subTitle: String? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.edit.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .edit, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showEdit(_ title: String, subTitle: NSAttributedString? = nil, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor=SCLAlertViewStyle.edit.defaultColor, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout: timeout, completeText:closeButtonTitle, style: .edit, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showTitle(view, title, subTitle, style)
    @discardableResult
    open func showTitle(_ title: String, subTitle: String? = nil, style: SCLAlertViewStyle, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor = .black, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout:timeout, completeText:closeButtonTitle, style: style, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    @discardableResult
    open func showTitle(_ title: String, subTitle: NSAttributedString? = nil, style: SCLAlertViewStyle, closeButtonTitle:String?=nil, timeout:SCLTimeoutConfiguration?=nil, colorStyle: UIColor = .black, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, timeout:timeout, completeText:closeButtonTitle, style: style, colorStyle: colorStyle, colorTextButton: colorTextButton, circleIconImage: circleIconImage, animationStyle: animationStyle, window: window)
    }
    
    // showTitle(view, title, subTitle, timeout, style)
    @discardableResult
    open func showTitle(_ title: String, subTitle: Any? = nil, timeout: SCLTimeoutConfiguration?, completeText: String?, style: SCLAlertViewStyle, colorStyle: UIColor? = .black, colorTextButton: UIColor? = nil, circleIconImage: UIImage? = nil, animationStyle: SCLAnimationStyle = .topToBottom, window: UIWindow? = nil) -> SCLAlertViewResponder {
        selfReference = self
        view.alpha = 0
        view.tag = uniqueTag
        view.accessibilityIdentifier = uniqueAccessibilityIdentifier
        let rv = window ?? UIApplication.shared.windows.filter({$0.isKeyWindow}).first ??
            UIApplication.shared.windows.first!
        self.window = rv
        rv.addSubview(view)
        view.frame = rv.bounds
        baseView.frame = rv.bounds
        self.style = style
        
        // Alert colour
        viewColor = colorStyle ?? style.defaultColor

        // Title
        if !title.isEmpty {
            self.labelTitle.text = title
            let actualHeight = title.heightWithConstrainedWidth(width: subViewsWidth, font: self.labelTitle.font)
            self.labelTitle.frame = CGRect(x:appearance.margin.horizontal, y:appearance.margin.titleTop, width: subViewsWidth, height:actualHeight)
        }
        
        // Subtitle
        if let subTitle = subTitle as? String, !subTitle.isEmpty {
            viewText.text = subTitle
            // Adjust text view size, if necessary
            let str = subTitle as NSString
            let attr = [NSAttributedString.Key.font:viewText.font ?? UIFont()]
            let sz = CGSize(width: subViewsWidth, height:90)
            let r = str.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attr, context:nil)
            let ht = ceil(r.size.height)
            if ht < appearance.kTextHeight {
                appearance.kWindowHeight -= (appearance.kTextHeight - ht)
                appearance.setkTextHeight(ht)
            }
        }
        if let subTitle = subTitle as? NSAttributedString, !subTitle.string.isEmpty {
            viewText.attributedText = subTitle
            // Adjust text view size, if necessary
            let sz = CGSize(width: subViewsWidth, height:90)
            let r = subTitle.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
            let ht = ceil(r.size.height)
            if ht < appearance.kTextHeight {
                appearance.kWindowHeight -= (appearance.kTextHeight - ht)
                appearance.setkTextHeight(ht)
            }
        }
        
        // Done button
        if appearance.showCloseButton {
            
            // Retrieves the "done" word translated using Apple's UIKit dictionary
            let localizedDone = Bundle(for: UIApplication.self).localizedString(forKey: "Done", value: nil, table: nil)
            
            _ = addButton(completeText ?? localizedDone, target:self, selector:#selector(SCLAlertView.hideView))
        }
        
        //hidden/show circular view based on the ui option
        circleView.isHidden = !appearance.showCircularIcon
        circleBG.isHidden = !appearance.showCircularIcon
        
        // Alert view colour and images
        circleView.backgroundColor = viewColor
        
        // Spinner / icon
        if style == .wait {
            let indicator = UIActivityIndicatorView(style: appearance.activityIndicatorStyle)
            indicator.color = .defaultBackgroundColor
            indicator.startAnimating()
            circleIconView = indicator
        }
        else {
            isUsingDefaultIconImage = circleIconImage == nil
            let iconImage = circleIconImage ?? getIconImage()
            if let iconTintColor = iconTintColor {
                circleIconView = UIImageView(image: iconImage?.withRenderingMode(.alwaysTemplate))
                circleIconView?.tintColor = iconTintColor
            }
            else {
                circleIconView = UIImageView(image: iconImage)
            }
        }
        circleView.addSubview(circleIconView!)
        let x = (appearance.kCircleHeight - appearance.kCircleIconHeight) / 2
        circleIconView!.frame = CGRect( x: x, y: x, width: appearance.kCircleIconHeight, height: appearance.kCircleIconHeight)
        circleIconView?.layer.masksToBounds = true
        
        for txt in inputs {
            txt.layer.borderColor = viewColor.cgColor
        }
        
        for txt in input {
            txt.layer.borderColor = viewColor.cgColor
        }
        
        for btn in buttons {
            if let customBackgroundColor = btn.customBackgroundColor {
                // Custom BackgroundColor set
                btn.backgroundColor = customBackgroundColor
            } else {
                // Use default BackgroundColor derived from AlertStyle
                btn.backgroundColor = viewColor
            }
            
            if let customTextColor = btn.customTextColor {
                // Custom TextColor set
                btn.setTitleColor(customTextColor, for: .normal)
            } else {
                if let colorTextButton = colorTextButton {
                    btn.setTitleColor(colorTextButton, for: .normal)
                } else {
                    btn.setTitleColor(UIColor.defaultButtonTitleColor, for: .normal)
                }
            }
        }
        
        // Adding timeout
        if let timeout = timeout {
            self.timeout = timeout
            timeoutTimer?.invalidate()
            timeoutTimer = Timer.scheduledTimer(timeInterval: timeout.value, target: self, selector: #selector(SCLAlertView.hideViewTimeout), userInfo: nil, repeats: false)
            showTimeoutTimer?.invalidate()
            showTimeoutTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(SCLAlertView.updateShowTimeout), userInfo: nil, repeats: true)
        }
        
        // Animate in the alert view
        self.showAnimation(animationStyle)
       
        // Chainable objects
        return SCLAlertViewResponder(alertview: self)
    }
    
    // Show animation in the alert view
    fileprivate func showAnimation(_ animationStyle: SCLAnimationStyle = .topToBottom, animationStartOffset: CGFloat = -400.0, boundingAnimationOffset: CGFloat = 15.0, animationDuration: TimeInterval = 0.2) {
        
        var animationStartOrigin = self.baseView.frame.origin
        var animationCenter : CGPoint = window.center
        
        switch animationStyle {

        case .noAnimation:
            self.view.alpha = 1.0
            return;
            
        case .topToBottom:
            animationStartOrigin = CGPoint(x: animationStartOrigin.x, y: self.baseView.frame.origin.y + animationStartOffset)
            animationCenter = CGPoint(x: animationCenter.x, y: animationCenter.y + boundingAnimationOffset)
            
        case .bottomToTop:
            animationStartOrigin = CGPoint(x: animationStartOrigin.x, y: self.baseView.frame.origin.y - animationStartOffset)
            animationCenter = CGPoint(x: animationCenter.x, y: animationCenter.y - boundingAnimationOffset)
            
        case .leftToRight:
            animationStartOrigin = CGPoint(x: self.baseView.frame.origin.x + animationStartOffset, y: animationStartOrigin.y)
            animationCenter = CGPoint(x: animationCenter.x + boundingAnimationOffset, y: animationCenter.y)
            
        case .rightToLeft:
            animationStartOrigin = CGPoint(x: self.baseView.frame.origin.x - animationStartOffset, y: animationStartOrigin.y)
            animationCenter = CGPoint(x: animationCenter.x - boundingAnimationOffset, y: animationCenter.y)
        }

        self.baseView.frame.origin = animationStartOrigin
        
        // When people call SCLAlertView from viewDidLoad of their root UIViewController
        // on the app start we many end up with a non-key window and later our view will be covered
        // by the view controller's view.
        // The best we can do is to bring our view to front later.
        let bringViewToFront = !window.isKeyWindow
        
        if self.appearance.dynamicAnimatorActive {
            UIView.animate(withDuration: animationDuration, animations: { 
                self.view.alpha = 1.0
            }) { _ in
                if bringViewToFront {
                    self.window.bringSubviewToFront(self.view)
                }
            }
            self.animate(item: self.baseView, center: window.center)
        } else {
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.alpha = 1.0
                 self.baseView.center = animationCenter
                }, completion: { finished in
                    if bringViewToFront {
                        self.window.bringSubviewToFront(self.view)
                    }
                    UIView.animate(withDuration: animationDuration, animations: {
                        self.view.alpha = 1.0
                        self.baseView.center = self.window.center
                    })
            })
        }
    }
    
    // DynamicAnimator function
    var animator : UIDynamicAnimator?
    var snapBehavior : UISnapBehavior?
    
    fileprivate func animate(item : UIView , center: CGPoint) {
    
        if let snapBehavior = self.snapBehavior {
            self.animator?.removeBehavior(snapBehavior)
        }
        
        self.animator = UIDynamicAnimator.init(referenceView: self.view)
        let tempSnapBehavior  =  UISnapBehavior.init(item: item, snapTo: center)
        self.animator?.addBehavior(tempSnapBehavior)
        self.snapBehavior? = tempSnapBehavior
    }
    
    //
    @objc open func updateShowTimeout() {
        
        guard let timeout = self.timeout else {
            return
        }
        
        self.timeout?.value = timeout.value.advanced(by: -1)
        
        for btn in buttons {
            guard let showTimeout = btn.showTimeout else {
                continue
            }

            let timeoutStr: String = showTimeout.prefix + String(Int(timeout.value)) + showTimeout.suffix
            let txt = String(btn.initialTitle) + " " + timeoutStr
            btn.setTitle(txt, for: .normal)
            
        }

    }
    
    // Close SCLAlertView
    @objc open func hideView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
            }, completion: { finished in
                
                // Stop timeoutTimer so alertView does not attempt to hide itself and fire it's dimiss block a second time when close button is tapped
                self.timeoutTimer?.invalidate()
                
                // Stop showTimeoutTimer
                self.showTimeoutTimer?.invalidate()
                
                if let dismissBlock = self.dismissBlock {
                    // Call completion handler when the alert is dismissed
                    dismissBlock()
                }
                
                // This is necessary for SCLAlertView to be de-initialized, preventing a strong reference cycle with the viewcontroller calling SCLAlertView.
                for button in self.buttons {
                    button.action = nil
                    button.target = nil
                    button.selector = nil
                }
                
                self.view.removeFromSuperview()
                self.selfReference = nil
        })
    }
    
    @objc open func hideViewTimeout() {
        self.timeout?.action()
        self.hideView()
    }
    
    func checkCircleIconImage(_ circleIconImage: UIImage?, defaultImage: UIImage) -> UIImage {
        if let image = circleIconImage {
            return image
        } else {
            return defaultImage
        }
    }
    
    //Return true if a SCLAlertView is already being shown, false otherwise
    open func isShowing() -> Bool {
        if let subviews = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.subviews {
            for view in subviews {
                if view.tag == uniqueTag && view.accessibilityIdentifier == uniqueAccessibilityIdentifier {
                    return true
                }
            }
        }
        return false
    }

    private func getIconImage() -> UIImage? {
        switch style {
        case .wait, .none:
            return nil
        case .success:
            return SCLAlertViewStyleKit.imageOfCheckmark
        case .error:
            return SCLAlertViewStyleKit.imageOfCross
        case .notice:
            return SCLAlertViewStyleKit.imageOfNotice
        case .warning:
            return SCLAlertViewStyleKit.imageOfWarning
        case .info:
            return SCLAlertViewStyleKit.imageOfInfo
        case .edit:
            return SCLAlertViewStyleKit.imageOfEdit
        case .question:
            return SCLAlertViewStyleKit.imageOfQuestion
        }
    }
}

// Helper function to convert from RGB to UIColor
public func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

// ------------------------------------
// Icon drawing
// Code generated by PaintCode
// ------------------------------------

class SCLAlertViewStyleKit : NSObject {
    
    // Cache
    struct Cache {
        static var imageOfCheckmark: UIImage?
        static var checkmarkTargets: [AnyObject]?
        static var imageOfCross: UIImage?
        static var crossTargets: [AnyObject]?
        static var imageOfNotice: UIImage?
        static var noticeTargets: [AnyObject]?
        static var imageOfWarning: UIImage?
        static var warningTargets: [AnyObject]?
        static var imageOfInfo: UIImage?
        static var infoTargets: [AnyObject]?
        static var imageOfEdit: UIImage?
        static var editTargets: [AnyObject]?
        static var imageOfQuestion: UIImage?
        static var questionTargets: [AnyObject]?
    }
    
    // Initialization
    /// swift 1.2 abolish func load
    //    override class func load() {
    //    }
    
    // Drawing Methods
    class func drawCheckmark() {
        // Checkmark Shape Drawing
        let checkmarkShapePath = UIBezierPath()
        checkmarkShapePath.move(to: CGPoint(x: 73.25, y: 14.05))
        checkmarkShapePath.addCurve(to: CGPoint(x: 64.51, y: 13.86), controlPoint1: CGPoint(x: 70.98, y: 11.44), controlPoint2: CGPoint(x: 66.78, y: 11.26))
        checkmarkShapePath.addLine(to: CGPoint(x: 27.46, y: 52))
        checkmarkShapePath.addLine(to: CGPoint(x: 15.75, y: 39.54))
        checkmarkShapePath.addCurve(to: CGPoint(x: 6.84, y: 39.54), controlPoint1: CGPoint(x: 13.48, y: 36.93), controlPoint2: CGPoint(x: 9.28, y: 36.93))
        checkmarkShapePath.addCurve(to: CGPoint(x: 6.84, y: 49.02), controlPoint1: CGPoint(x: 4.39, y: 42.14), controlPoint2: CGPoint(x: 4.39, y: 46.42))
        checkmarkShapePath.addLine(to: CGPoint(x: 22.91, y: 66.14))
        checkmarkShapePath.addCurve(to: CGPoint(x: 27.28, y: 68), controlPoint1: CGPoint(x: 24.14, y: 67.44), controlPoint2: CGPoint(x: 25.71, y: 68))
        checkmarkShapePath.addCurve(to: CGPoint(x: 31.65, y: 66.14), controlPoint1: CGPoint(x: 28.86, y: 68), controlPoint2: CGPoint(x: 30.43, y: 67.26))
        checkmarkShapePath.addLine(to: CGPoint(x: 73.08, y: 23.35))
        checkmarkShapePath.addCurve(to: CGPoint(x: 73.25, y: 14.05), controlPoint1: CGPoint(x: 75.52, y: 20.75), controlPoint2: CGPoint(x: 75.7, y: 16.65))
        checkmarkShapePath.close()
        checkmarkShapePath.miterLimit = 4;
        UIColor.black.setFill()
        checkmarkShapePath.fill()
    }
    
    class func drawCross() {
        // Cross Shape Drawing
        let crossShapePath = UIBezierPath()
        crossShapePath.move(to: CGPoint(x: 10, y: 70))
        crossShapePath.addLine(to: CGPoint(x: 70, y: 10))
        crossShapePath.move(to: CGPoint(x: 10, y: 10))
        crossShapePath.addLine(to: CGPoint(x: 70, y: 70))
        crossShapePath.lineCapStyle = CGLineCap.round;
        crossShapePath.lineJoinStyle = CGLineJoin.round;
        UIColor.black.setStroke()
        crossShapePath.lineWidth = 14
        crossShapePath.stroke()
    }
    
    class func drawNotice() {
        // Notice Shape Drawing
        let noticeShapePath = UIBezierPath()
        noticeShapePath.move(to: CGPoint(x: 72, y: 48.54))
        noticeShapePath.addLine(to: CGPoint(x: 72, y: 39.9))
        noticeShapePath.addCurve(to: CGPoint(x: 66.38, y: 34.01), controlPoint1: CGPoint(x: 72, y: 36.76), controlPoint2: CGPoint(x: 69.48, y: 34.01))
        noticeShapePath.addCurve(to: CGPoint(x: 61.53, y: 35.97), controlPoint1: CGPoint(x: 64.82, y: 34.01), controlPoint2: CGPoint(x: 62.69, y: 34.8))
        noticeShapePath.addCurve(to: CGPoint(x: 60.36, y: 35.78), controlPoint1: CGPoint(x: 61.33, y: 35.97), controlPoint2: CGPoint(x: 62.3, y: 35.78))
        noticeShapePath.addLine(to: CGPoint(x: 60.36, y: 33.22))
        noticeShapePath.addCurve(to: CGPoint(x: 54.16, y: 26.16), controlPoint1: CGPoint(x: 60.36, y: 29.3), controlPoint2: CGPoint(x: 57.65, y: 26.16))
        noticeShapePath.addCurve(to: CGPoint(x: 48.73, y: 29.89), controlPoint1: CGPoint(x: 51.64, y: 26.16), controlPoint2: CGPoint(x: 50.67, y: 27.73))
        noticeShapePath.addLine(to: CGPoint(x: 48.73, y: 28.71))
        noticeShapePath.addCurve(to: CGPoint(x: 43.49, y: 21.64), controlPoint1: CGPoint(x: 48.73, y: 24.78), controlPoint2: CGPoint(x: 46.98, y: 21.64))
        noticeShapePath.addCurve(to: CGPoint(x: 39.03, y: 25.37), controlPoint1: CGPoint(x: 40.97, y: 21.64), controlPoint2: CGPoint(x: 39.03, y: 23.01))
        noticeShapePath.addLine(to: CGPoint(x: 39.03, y: 9.07))
        noticeShapePath.addCurve(to: CGPoint(x: 32.24, y: 2), controlPoint1: CGPoint(x: 39.03, y: 5.14), controlPoint2: CGPoint(x: 35.73, y: 2))
        noticeShapePath.addCurve(to: CGPoint(x: 25.45, y: 9.07), controlPoint1: CGPoint(x: 28.56, y: 2), controlPoint2: CGPoint(x: 25.45, y: 5.14))
        noticeShapePath.addLine(to: CGPoint(x: 25.45, y: 41.47))
        noticeShapePath.addCurve(to: CGPoint(x: 24.29, y: 43.44), controlPoint1: CGPoint(x: 25.45, y: 42.45), controlPoint2: CGPoint(x: 24.68, y: 43.04))
        noticeShapePath.addCurve(to: CGPoint(x: 9.55, y: 43.04), controlPoint1: CGPoint(x: 16.73, y: 40.88), controlPoint2: CGPoint(x: 11.88, y: 40.69))
        noticeShapePath.addCurve(to: CGPoint(x: 8, y: 46.58), controlPoint1: CGPoint(x: 8.58, y: 43.83), controlPoint2: CGPoint(x: 8, y: 45.2))
        noticeShapePath.addCurve(to: CGPoint(x: 14.4, y: 55.81), controlPoint1: CGPoint(x: 8.19, y: 50.31), controlPoint2: CGPoint(x: 12.07, y: 53.84))
        noticeShapePath.addLine(to: CGPoint(x: 27.2, y: 69.56))
        noticeShapePath.addCurve(to: CGPoint(x: 42.91, y: 77.8), controlPoint1: CGPoint(x: 30.5, y: 74.47), controlPoint2: CGPoint(x: 35.73, y: 77.21))
        noticeShapePath.addCurve(to: CGPoint(x: 43.88, y: 77.8), controlPoint1: CGPoint(x: 43.3, y: 77.8), controlPoint2: CGPoint(x: 43.68, y: 77.8))
        noticeShapePath.addCurve(to: CGPoint(x: 47.18, y: 78), controlPoint1: CGPoint(x: 45.04, y: 77.8), controlPoint2: CGPoint(x: 46.01, y: 78))
        noticeShapePath.addLine(to: CGPoint(x: 48.34, y: 78))
        noticeShapePath.addLine(to: CGPoint(x: 48.34, y: 78))
        noticeShapePath.addCurve(to: CGPoint(x: 71.61, y: 52.08), controlPoint1: CGPoint(x: 56.48, y: 78), controlPoint2: CGPoint(x: 69.87, y: 75.05))
        noticeShapePath.addCurve(to: CGPoint(x: 72, y: 48.54), controlPoint1: CGPoint(x: 71.81, y: 51.29), controlPoint2: CGPoint(x: 72, y: 49.72))
        noticeShapePath.close()
        noticeShapePath.miterLimit = 4;
        UIColor.black.setFill()
        noticeShapePath.fill()
    }
    
    class func drawWarning() {
        // Color Declarations
        let greyColor = UIColor(red: 0.236, green: 0.236, blue: 0.236, alpha: 1.000)
        
        // Warning Group
        // Warning Circle Drawing
        let warningCirclePath = UIBezierPath()
        warningCirclePath.move(to: CGPoint(x: 40.94, y: 63.39))
        warningCirclePath.addCurve(to: CGPoint(x: 36.03, y: 65.55), controlPoint1: CGPoint(x: 39.06, y: 63.39), controlPoint2: CGPoint(x: 37.36, y: 64.18))
        warningCirclePath.addCurve(to: CGPoint(x: 34.14, y: 70.45), controlPoint1: CGPoint(x: 34.9, y: 66.92), controlPoint2: CGPoint(x: 34.14, y: 68.49))
        warningCirclePath.addCurve(to: CGPoint(x: 36.22, y: 75.54), controlPoint1: CGPoint(x: 34.14, y: 72.41), controlPoint2: CGPoint(x: 34.9, y: 74.17))
        warningCirclePath.addCurve(to: CGPoint(x: 40.94, y: 77.5), controlPoint1: CGPoint(x: 37.54, y: 76.91), controlPoint2: CGPoint(x: 39.06, y: 77.5))
        warningCirclePath.addCurve(to: CGPoint(x: 45.86, y: 75.35), controlPoint1: CGPoint(x: 42.83, y: 77.5), controlPoint2: CGPoint(x: 44.53, y: 76.72))
        warningCirclePath.addCurve(to: CGPoint(x: 47.93, y: 70.45), controlPoint1: CGPoint(x: 47.18, y: 74.17), controlPoint2: CGPoint(x: 47.93, y: 72.41))
        warningCirclePath.addCurve(to: CGPoint(x: 45.86, y: 65.35), controlPoint1: CGPoint(x: 47.93, y: 68.49), controlPoint2: CGPoint(x: 47.18, y: 66.72))
        warningCirclePath.addCurve(to: CGPoint(x: 40.94, y: 63.39), controlPoint1: CGPoint(x: 44.53, y: 64.18), controlPoint2: CGPoint(x: 42.83, y: 63.39))
        warningCirclePath.close()
        warningCirclePath.miterLimit = 4;
        
        greyColor.setFill()
        warningCirclePath.fill()
        
        
        // Warning Shape Drawing
        let warningShapePath = UIBezierPath()
        warningShapePath.move(to: CGPoint(x: 46.23, y: 4.26))
        warningShapePath.addCurve(to: CGPoint(x: 40.94, y: 2.5), controlPoint1: CGPoint(x: 44.91, y: 3.09), controlPoint2: CGPoint(x: 43.02, y: 2.5))
        warningShapePath.addCurve(to: CGPoint(x: 34.71, y: 4.26), controlPoint1: CGPoint(x: 38.68, y: 2.5), controlPoint2: CGPoint(x: 36.03, y: 3.09))
        warningShapePath.addCurve(to: CGPoint(x: 31.5, y: 8.77), controlPoint1: CGPoint(x: 33.01, y: 5.44), controlPoint2: CGPoint(x: 31.5, y: 7.01))
        warningShapePath.addLine(to: CGPoint(x: 31.5, y: 19.36))
        warningShapePath.addLine(to: CGPoint(x: 34.71, y: 54.44))
        warningShapePath.addCurve(to: CGPoint(x: 40.38, y: 58.16), controlPoint1: CGPoint(x: 34.9, y: 56.2), controlPoint2: CGPoint(x: 36.41, y: 58.16))
        warningShapePath.addCurve(to: CGPoint(x: 45.67, y: 54.44), controlPoint1: CGPoint(x: 44.34, y: 58.16), controlPoint2: CGPoint(x: 45.67, y: 56.01))
        warningShapePath.addLine(to: CGPoint(x: 48.5, y: 19.36))
        warningShapePath.addLine(to: CGPoint(x: 48.5, y: 8.77))
        warningShapePath.addCurve(to: CGPoint(x: 46.23, y: 4.26), controlPoint1: CGPoint(x: 48.5, y: 7.01), controlPoint2: CGPoint(x: 47.74, y: 5.44))
        warningShapePath.close()
        warningShapePath.miterLimit = 4;
        
        greyColor.setFill()
        warningShapePath.fill()
    }
    
    class func drawInfo() {
        // Info Shape Drawing
        let infoShapePath = UIBezierPath()
        infoShapePath.move(to: CGPoint(x: 45.66, y: 15.96))
        infoShapePath.addCurve(to: CGPoint(x: 45.66, y: 5.22), controlPoint1: CGPoint(x: 48.78, y: 12.99), controlPoint2: CGPoint(x: 48.78, y: 8.19))
        infoShapePath.addCurve(to: CGPoint(x: 34.34, y: 5.22), controlPoint1: CGPoint(x: 42.53, y: 2.26), controlPoint2: CGPoint(x: 37.47, y: 2.26))
        infoShapePath.addCurve(to: CGPoint(x: 34.34, y: 15.96), controlPoint1: CGPoint(x: 31.22, y: 8.19), controlPoint2: CGPoint(x: 31.22, y: 12.99))
        infoShapePath.addCurve(to: CGPoint(x: 45.66, y: 15.96), controlPoint1: CGPoint(x: 37.47, y: 18.92), controlPoint2: CGPoint(x: 42.53, y: 18.92))
        infoShapePath.close()
        infoShapePath.move(to: CGPoint(x: 48, y: 69.41))
        infoShapePath.addCurve(to: CGPoint(x: 40, y: 77), controlPoint1: CGPoint(x: 48, y: 73.58), controlPoint2: CGPoint(x: 44.4, y: 77))
        infoShapePath.addLine(to: CGPoint(x: 40, y: 77))
        infoShapePath.addCurve(to: CGPoint(x: 32, y: 69.41), controlPoint1: CGPoint(x: 35.6, y: 77), controlPoint2: CGPoint(x: 32, y: 73.58))
        infoShapePath.addLine(to: CGPoint(x: 32, y: 35.26))
        infoShapePath.addCurve(to: CGPoint(x: 40, y: 27.67), controlPoint1: CGPoint(x: 32, y: 31.08), controlPoint2: CGPoint(x: 35.6, y: 27.67))
        infoShapePath.addLine(to: CGPoint(x: 40, y: 27.67))
        infoShapePath.addCurve(to: CGPoint(x: 48, y: 35.26), controlPoint1: CGPoint(x: 44.4, y: 27.67), controlPoint2: CGPoint(x: 48, y: 31.08))
        infoShapePath.addLine(to: CGPoint(x: 48, y: 69.41))
        infoShapePath.close()
        UIColor.black.setFill()
        infoShapePath.fill()
    }
    
    class func drawEdit() {
        // Edit shape Drawing
        let editPathPath = UIBezierPath()
        editPathPath.move(to: CGPoint(x: 71, y: 2.7))
        editPathPath.addCurve(to: CGPoint(x: 71.9, y: 15.2), controlPoint1: CGPoint(x: 74.7, y: 5.9), controlPoint2: CGPoint(x: 75.1, y: 11.6))
        editPathPath.addLine(to: CGPoint(x: 64.5, y: 23.7))
        editPathPath.addLine(to: CGPoint(x: 49.9, y: 11.1))
        editPathPath.addLine(to: CGPoint(x: 57.3, y: 2.6))
        editPathPath.addCurve(to: CGPoint(x: 69.7, y: 1.7), controlPoint1: CGPoint(x: 60.4, y: -1.1), controlPoint2: CGPoint(x: 66.1, y: -1.5))
        editPathPath.addLine(to: CGPoint(x: 71, y: 2.7))
        editPathPath.addLine(to: CGPoint(x: 71, y: 2.7))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 47.8, y: 13.5))
        editPathPath.addLine(to: CGPoint(x: 13.4, y: 53.1))
        editPathPath.addLine(to: CGPoint(x: 15.7, y: 55.1))
        editPathPath.addLine(to: CGPoint(x: 50.1, y: 15.5))
        editPathPath.addLine(to: CGPoint(x: 47.8, y: 13.5))
        editPathPath.addLine(to: CGPoint(x: 47.8, y: 13.5))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 17.7, y: 56.7))
        editPathPath.addLine(to: CGPoint(x: 23.8, y: 62.2))
        editPathPath.addLine(to: CGPoint(x: 58.2, y: 22.6))
        editPathPath.addLine(to: CGPoint(x: 52, y: 17.1))
        editPathPath.addLine(to: CGPoint(x: 17.7, y: 56.7))
        editPathPath.addLine(to: CGPoint(x: 17.7, y: 56.7))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 25.8, y: 63.8))
        editPathPath.addLine(to: CGPoint(x: 60.1, y: 24.2))
        editPathPath.addLine(to: CGPoint(x: 62.3, y: 26.1))
        editPathPath.addLine(to: CGPoint(x: 28.1, y: 65.7))
        editPathPath.addLine(to: CGPoint(x: 25.8, y: 63.8))
        editPathPath.addLine(to: CGPoint(x: 25.8, y: 63.8))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 25.9, y: 68.1))
        editPathPath.addLine(to: CGPoint(x: 4.2, y: 79.5))
        editPathPath.addLine(to: CGPoint(x: 11.3, y: 55.5))
        editPathPath.addLine(to: CGPoint(x: 25.9, y: 68.1))
        editPathPath.close()
        editPathPath.miterLimit = 4;
        editPathPath.usesEvenOddFillRule = true;
        UIColor.black.setFill()
        editPathPath.fill()
    }
    
    class func drawQuestion() {
        // Questionmark Shape Drawing
        let questionShapePath = UIBezierPath()
        questionShapePath.move(to: CGPoint(x: CGFloat(33.75), y: CGFloat(54.1)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(44.15), y: CGFloat(54.1)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(44.15), y: CGFloat(47.5)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(51.85), y: CGFloat(37.2)), controlPoint1: CGPoint(x: CGFloat(44.15), y: CGFloat(42.9)), controlPoint2: CGPoint(x: CGFloat(46.75), y: CGFloat(41.2)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(61.95), y: CGFloat(19.9)), controlPoint1: CGPoint(x: CGFloat(59.05), y: CGFloat(31.6)), controlPoint2: CGPoint(x: CGFloat(61.95), y: CGFloat(28.5)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(41.45), y: CGFloat(2.8)), controlPoint1: CGPoint(x: CGFloat(61.95), y: CGFloat(7.6)), controlPoint2: CGPoint(x: CGFloat(52.85), y: CGFloat(2.8)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(25.05), y: CGFloat(5.8)), controlPoint1: CGPoint(x: CGFloat(34.75), y: CGFloat(2.8)), controlPoint2: CGPoint(x: CGFloat(29.65), y: CGFloat(3.8)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(25.05), y: CGFloat(14.4)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(38.15), y: CGFloat(12.3)), controlPoint1: CGPoint(x: CGFloat(29.15), y: CGFloat(13.2)), controlPoint2: CGPoint(x: CGFloat(32.35), y: CGFloat(12.3)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(49.65), y: CGFloat(20.8)), controlPoint1: CGPoint(x: CGFloat(45.65), y: CGFloat(12.3)), controlPoint2: CGPoint(x: CGFloat(49.65), y: CGFloat(14.4)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(43.65), y: CGFloat(31.7)), controlPoint1: CGPoint(x: CGFloat(49.65), y: CGFloat(26)), controlPoint2: CGPoint(x: CGFloat(47.95), y: CGFloat(28.4)))
        questionShapePath.addCurve(to: CGPoint(x: CGFloat(33.75), y: CGFloat(46.6)), controlPoint1: CGPoint(x: CGFloat(37.15), y: CGFloat(36.9)), controlPoint2: CGPoint(x: CGFloat(33.75), y: CGFloat(39.7)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(33.75), y: CGFloat(54.1)))
        questionShapePath.close()
        questionShapePath.move(to: CGPoint(x: CGFloat(33.15), y: CGFloat(75.4)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(45.35), y: CGFloat(75.4)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(45.35), y: CGFloat(63.7)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(33.15), y: CGFloat(63.7)))
        questionShapePath.addLine(to: CGPoint(x: CGFloat(33.15), y: CGFloat(75.4)))
        questionShapePath.close()
        UIColor.black.setFill()
        questionShapePath.fill()
    }
    
    // Generated Images
    class var imageOfCheckmark: UIImage {
        if (Cache.imageOfCheckmark != nil) {
            return Cache.imageOfCheckmark!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawCheckmark()
        Cache.imageOfCheckmark = UIGraphicsGetImageFromCurrentImageContext()?.withTintColor(.systemBackground)
        UIGraphicsEndImageContext()
        return Cache.imageOfCheckmark!
    }
    
    class var imageOfCross: UIImage {
        if (Cache.imageOfCross != nil) {
            return Cache.imageOfCross!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawCross()
        Cache.imageOfCross = UIGraphicsGetImageFromCurrentImageContext()?.withTintColor(.systemBackground)
        UIGraphicsEndImageContext()
        return Cache.imageOfCross!
    }
    
    class var imageOfNotice: UIImage {
        if (Cache.imageOfNotice != nil) {
            return Cache.imageOfNotice!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawNotice()
        Cache.imageOfNotice = UIGraphicsGetImageFromCurrentImageContext()?.withTintColor(.systemBackground)
        UIGraphicsEndImageContext()
        return Cache.imageOfNotice!
    }
    
    class var imageOfWarning: UIImage {
        if (Cache.imageOfWarning != nil) {
            return Cache.imageOfWarning!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawWarning()
        Cache.imageOfWarning = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfWarning!
    }
    
    class var imageOfInfo: UIImage {
        if (Cache.imageOfInfo != nil) {
            return Cache.imageOfInfo!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawInfo()
        Cache.imageOfInfo = UIGraphicsGetImageFromCurrentImageContext()?.withTintColor(.systemBackground)
        UIGraphicsEndImageContext()
        return Cache.imageOfInfo!
    }
    
    class var imageOfEdit: UIImage {
        if (Cache.imageOfEdit != nil) {
            return Cache.imageOfEdit!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawEdit()
        Cache.imageOfEdit = UIGraphicsGetImageFromCurrentImageContext()?.withTintColor(.systemBackground)
        UIGraphicsEndImageContext()
        return Cache.imageOfEdit!
    }
    
    class var imageOfQuestion: UIImage {
        if (Cache.imageOfQuestion != nil) {
            return Cache.imageOfQuestion!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawQuestion()
        Cache.imageOfQuestion = UIGraphicsGetImageFromCurrentImageContext()?.withTintColor(.systemBackground)
        UIGraphicsEndImageContext()
        return Cache.imageOfQuestion!
    }
    
}

extension SCLAlertView {
  var subViewsWidth: CGFloat {
    return appearance.kWindowWidth - 2 * appearance.margin.horizontal
  }
}

fileprivate extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init(dynamicProvider: { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }

    static var defaultBackgroundColor: UIColor = .systemBackground
    
    static var defaultTitleColor: UIColor = .label
    
    static var defaultSubTitleColor: UIColor {
        return UIColor(light: UIColorFromRGB(0x4D4D4D), dark: UIColorFromRGB(0xADADAD))
    }
    
    static var defaultButtonTitleColor: UIColor = .systemBackground
}
