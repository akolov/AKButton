//
//  AKButton.swift
//  AKButton
//
//  Created by Alexander Kolov on 2020-07-07.
//  Copyright © 2020 Alexander Kolov. All rights reserved.
//

import UIKit

@IBDesignable
open class AKButton: UIControl {

  public struct Configuration {
    public var cornerRadius: CGFloat
    public var backgroundColor: (UIControl.State) -> UIColor
    public var foregroundColor: (UIControl.State) -> UIColor
    public var tapAnimationDuration: TimeInterval
    public var tappedForegroundAlpha: CGFloat
    public var tappedBrightnessOffset: CGFloat
    public var font: UIFont
    public var spacing: CGFloat
    public var layoutMargins: UIEdgeInsets

    public init(
      cornerRadius: CGFloat = 8,
      backgroundColor: @escaping (UIControl.State) -> UIColor = { _ in .systemBlue },
      foregroundColor: @escaping (UIControl.State) -> UIColor = { _ in .white },
      tapAnimationDuration: TimeInterval = 0.3,
      tappedForegroundAlpha: CGFloat = 0.75,
      tappedBrightnessOffset: CGFloat = -0.1,
      font: UIFont = {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let metrics = UIFontMetrics(forTextStyle: .body)
        return metrics.scaledFont(for: font)
      }(),
      spacing: CGFloat = 15,
      margins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    ) {
      self.cornerRadius = cornerRadius
      self.backgroundColor = backgroundColor
      self.foregroundColor = foregroundColor
      self.tapAnimationDuration = tapAnimationDuration
      self.tappedForegroundAlpha = tappedForegroundAlpha
      self.tappedBrightnessOffset = tappedBrightnessOffset
      self.font = font
      self.spacing = spacing
      self.layoutMargins = margins
    }
  }

  // MARK: Properties

  public var title: (UIControl.State) -> String? = { _ in "Placeholder" } {
    didSet {
      titleLabel.text = title(state)
    }
  }

  public var action: (() -> Void)?

  public var configuration: Configuration {
    didSet {
      configure()
    }
  }

  public override var isEnabled: Bool {
    didSet {
      updateState()
    }
  }

  public override var isHighlighted: Bool {
    didSet {
      updateState()
    }
  }

  public override var isSelected: Bool {
    didSet {
      updateState()
    }
  }

  private var isTapped: Bool = false
  private var tappedBackgroundColor: UIColor?

  // MARK: Subviews

  public private(set) lazy var containerView: UIView = {
    let containerView = UIView()
    containerView.backgroundColor = .clear
    containerView.clipsToBounds = true
    containerView.isUserInteractionEnabled = false
    containerView.translatesAutoresizingMaskIntoConstraints = false
    return containerView
  }()

  public private(set) lazy var backgroundView: UIView = {
    let backgroundView = UIView()
    if #available(iOS 13.0, *) {
      backgroundView.layer.cornerCurve = .continuous
    }
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    return backgroundView
  }()

  public private(set) lazy var foregroundView: UIStackView = {
    let foregroundView = UIStackView()
    foregroundView.axis = .horizontal
    foregroundView.translatesAutoresizingMaskIntoConstraints = false
    foregroundView.isLayoutMarginsRelativeArrangement = true
    foregroundView.layoutMargins = self.configuration.layoutMargins
    return foregroundView
  }()

  public private(set) lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.text = self.title(state)
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    return titleLabel
  }()

  // MARK: Initializer

  public override init(frame: CGRect) {
    self.configuration = Configuration()
    super.init(frame: frame)
    commonInit()
  }

  public init(configuration: Configuration) {
    self.configuration = configuration
    super.init(frame: .zero)
    commonInit()
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    self.configuration = Configuration()
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    configure()

    addSubview(containerView)
    containerView.addSubview(backgroundView)
    containerView.addSubview(foregroundView)
    foregroundView.addArrangedSubview(titleLabel)

    NSLayoutConstraint.activate([
      containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      containerView.topAnchor.constraint(equalTo: self.topAnchor),
      containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    ])

    NSLayoutConstraint.activate([
      backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
      backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
    ])

    NSLayoutConstraint.activate([
      foregroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      foregroundView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      foregroundView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
      containerView.trailingAnchor.constraint(greaterThanOrEqualTo: foregroundView.trailingAnchor),
      foregroundView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
      containerView.bottomAnchor.constraint(greaterThanOrEqualTo: foregroundView.bottomAnchor)
    ])

    addTarget(self, action: #selector(didTouchDownInside), for: [.touchDown, .touchDownRepeat])
    addTarget(self, action: #selector(didTouchUpInside), for: [.touchUpInside])
    addTarget(self, action: #selector(didDragInside), for: [.touchDragEnter])
    addTarget(self, action: #selector(didDragOutside), for: [.touchDragExit, .touchCancel])
  }

  // MARK: Private methods

  private func configure() {
    updateState()

    backgroundView.layer.cornerRadius = configuration.cornerRadius
    foregroundView.spacing = configuration.spacing
    foregroundView.layoutMargins = configuration.layoutMargins
    titleLabel.font = configuration.font

    resetForegroundAfterAnimations()
  }

  private func updateState() {
    titleLabel.text = title(state)
    tappedBackgroundColor = Self.brightnessAdjusted(
      color: configuration.backgroundColor(state),
      amount: configuration.tappedBrightnessOffset
    )

    backgroundView.backgroundColor = isTapped ? tappedBackgroundColor : configuration.backgroundColor(state)
    titleLabel.backgroundColor = configuration.backgroundColor(state)
    titleLabel.textColor = configuration.foregroundColor(state)
  }

  // MARK: Tap handling

  @objc
  private func didTouchDownInside() {
    isTapped = true
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
  }

  @objc
  private func didTouchUpInside() {
    isTapped = false
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
    sendActions(for: .primaryActionTriggered)
    action?()
  }

  @objc
  private func didDragInside() {
    isTapped = true
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
  }

  @objc
  private func didDragOutside() {
    isTapped = false
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
  }

  // MARK: Animations

  private func updateBackgroundColor(animated: Bool) {
    guard let tappedBackgroundColor = tappedBackgroundColor else {
      return
    }

    let animations = {
      self.backgroundView.backgroundColor = self.isTapped
        ? tappedBackgroundColor
        : self.configuration.backgroundColor(self.state)
    }

    let completion = { (finished: Bool) in
      guard finished else {
        return
      }

      self.resetForegroundAfterAnimations()
    }

    if !animated {
      animations()
      completion(true)
    }
    else {
      prepareForegroundForAnimations()
      UIView.animate(
        withDuration: configuration.tapAnimationDuration,
        delay: 0,
        options: [.beginFromCurrentState],
        animations: animations,
        completion: completion
      )
    }
  }

  private func updateForegroundAlpha(animated: Bool) {
    guard configuration.tappedForegroundAlpha < 1 - .ulpOfOne else {
      return
    }

    let alpha = isTapped ? configuration.tappedForegroundAlpha : 1

    let animations = {
      self.foregroundView.arrangedSubviews.forEach { $0.alpha = alpha }
    }

    if !animated {
      self.foregroundView.layer.removeAnimation(forKey: "opacity")
      animations()
    }
    else {
      prepareForegroundForAnimations()
      UIView.animate(
        withDuration: configuration.tapAnimationDuration,
        delay: 0,
        options: [.beginFromCurrentState],
        animations: animations,
        completion: nil
      )
    }
  }

  private func prepareForegroundForAnimations() {
    foregroundView.arrangedSubviews.forEach { $0.backgroundColor = .clear }
  }

  private func resetForegroundAfterAnimations() {
    let color = isTapped ? .clear : configuration.backgroundColor(state)
    foregroundView.arrangedSubviews.forEach { $0.backgroundColor = color }
  }

  // MARK: Private methods

  private static func brightnessAdjusted(color: UIColor, amount: CGFloat) -> UIColor? {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
      return nil
    }

    b += amount
    b = max(b, 0)
    b = min(b, 1)

    return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
  }

}
