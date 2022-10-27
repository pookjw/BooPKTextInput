//
//  ViewController.swift
//  BooPKTextInput
//
//  Created by Jinwoo Kim on 10/27/22.
//

import UIKit

@MainActor
final class ViewController: UIViewController {
    private let textView: UITextView = .init()
    private let guideLabel: UILabel = .init()
    private var guideLabelBottomLayout: NSLayoutConstraint?
    private var keyboardWillShowNotificationTask: Task<Void, Never>?
    private var keyboardWillChangeFrameNotificationTask: Task<Void, Never>?
    
    deinit {
        keyboardWillShowNotificationTask?.cancel()
        keyboardWillChangeFrameNotificationTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextView()
        configureGuideLabel()
        bind()
    }
    
    private func configureTextView() {
        textView.contentInsetAdjustmentBehavior = .always
        textView.text = """
        😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝
        😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝
        😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝😝
        """
        textView.font = .preferredFont(forTextStyle: .body)
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureGuideLabel() {
        guideLabel.backgroundColor = .brown
        guideLabel.text = "Hello"
        guideLabel.font = .preferredFont(forTextStyle: .headline)
        guideLabel.textAlignment = .center
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
        
//                let guideLabelBottomLayout: NSLayoutConstraint = guideLabel.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        let guideLabelBottomLayout: NSLayoutConstraint = guideLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            guideLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            guideLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            guideLabelBottomLayout
        ])
        
        self.guideLabelBottomLayout = guideLabelBottomLayout
    }
    
    private func bind() {
        keyboardWillShowNotificationTask = .detached { [weak self] in
            // It's not an async function, but the compiler requires `await`, why? - "Expression is 'async' but is not marked with 'await'"
            let notifications: NotificationCenter.Notifications = await NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification)
            for await notification in notifications {
                await self?.handle(keyboardNotification: notification)
            }
        }
        
        keyboardWillChangeFrameNotificationTask = .detached { [weak self] in
            // It's not an async function, but the compiler requires `await`, why? - "Expression is 'async' but is not marked with 'await'"
            let notifications: NotificationCenter.Notifications = await NotificationCenter.default.notifications(named: UIResponder.keyboardWillChangeFrameNotification)
            for await notification in notifications {
                await self?.handle(keyboardNotification: notification)
            }
        }
    }
    
    private func handle(keyboardNotification: Notification) {
        guard let animationCurve: UInt = keyboardNotification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let duration: TimeInterval = keyboardNotification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let beginFrame: CGRect = (keyboardNotification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let endFrame: CGRect = (keyboardNotification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }
        
        print(beginFrame, endFrame)
        guideLabel.text = "\(beginFrame), \(endFrame)"
        
        let height: CGFloat
        
        if ((beginFrame.origin.x == .zero) && (endFrame.origin.x == .zero)) ||
            (UIDevice.current.userInterfaceIdiom == .phone) {
            let offset: CGFloat = view.frame.height - endFrame.origin.y - view.safeAreaInsets.bottom
            height = offset > .zero ? offset : .zero
        } else {
            // Floating Keyboard
            height = .zero
        }
        
        guideLabelBottomLayout?.constant = height * (-1)
        
        let curve: UIView.AnimationOptions = .init(rawValue: animationCurve << 16)
        
        UIView.animate(withDuration: duration,
                       delay: .zero,
                       options: [curve]) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
}
