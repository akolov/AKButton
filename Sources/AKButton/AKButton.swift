//
//  AKButton.swift
//  AKButton
//
//  Created by Alexander Kolov on 2020-07-07.
//  Copyright © 2020 Alexander Kolov. All rights reserved.
//

import UIKit

open class AKButton: UIControl {

  public struct Configuration {
    public var cornerRadius: CGFloat
    public var backgroundColor: UIColor
    public var foregroundColor: UIColor
    public var tapAnimationDuration: TimeInterval
    public var tappedForegroundAlpha: CGFloat
    public var tappedBrightnessOffset: CGFloat
    public var font: UIFont
    public var spacing: CGFloat

    public init(
      cornerRadius: CGFloat = 8,
      backgroundColor: UIColor = .systemBlue,
      foregroundColor: UIColor = .white,
      tapAnimationDuration: TimeInterval = 0.3,
      tappedForegroundAlpha: CGFloat = 0.75,
      tappedBrightnessOffset: CGFloat = -0.1,
      font: UIFont = {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let metrics = UIFontMetrics(forTextStyle: .body)
        return metrics.scaledFont(for: font)
      }(),
      spacing: CGFloat = 15
    ) {
      self.cornerRadius = cornerRadius
      self.backgroundColor = backgroundColor
      self.foregroundColor = foregroundColor
      self.tapAnimationDuration = tapAnimationDuration
      self.tappedForegroundAlpha = tappedForegroundAlpha
      self.tappedBrightnessOffset = tappedBrightnessOffset
      self.font = font
      self.spacing = spacing
    }
  }

  // MARK: Properties

  public var title = "Placeholder" {
    didSet {
      titleLabel.text = title
    }
  }

  public var action: (() -> Void)?

  var configuration: Configuration {
    didSet {
      configure()
    }
  }

  private var isTapped: Bool = false
  private var tappedBackgroundColor: UIColor?

  // MARK: Subviews

  private lazy var containerView: UIView = {
    let containerView = UIView()
    containerView.backgroundColor = .clear
    containerView.clipsToBounds = true
    containerView.isUserInteractionEnabled = false
    containerView.translatesAutoresizingMaskIntoConstraints = false
    return containerView
  }()

  private lazy var backgroundView: UIView = {
    let backgroundView = UIView()
    if #available(iOS 13.0, *) {
      backgroundView.layer.cornerCurve = .continuous
    }
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    return backgroundView
  }()

  private lazy var foregroundView: UIStackView = {
    let foregroundView = UIStackView()
    foregroundView.axis = .horizontal
    foregroundView.translatesAutoresizingMaskIntoConstraints = false
    return foregroundView
  }()

  private lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.text = self.title
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    return titleLabel
  }()

  // MARK: Initializer

  override init(frame: CGRect) {
    self.configuration = Configuration()
    super.init(frame: frame)
    commonInit()
  }

  init(configuration: Configuration) {
    self.configuration = configuration
    super.init(frame: .zero)
    commonInit()
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
    tappedBackgroundColor = Self.brightnessAdjusted(
      color: configuration.backgroundColor,
      amount: configuration.tappedBrightnessOffset
    )

    backgroundView.backgroundColor = isTapped ? tappedBackgroundColor : configuration.backgroundColor
    backgroundView.layer.cornerRadius = configuration.cornerRadius
    foregroundView.spacing = configuration.spacing
    titleLabel.backgroundColor = configuration.backgroundColor
    titleLabel.font = configuration.font
    titleLabel.textColor = configuration.foregroundColor

    resetForegroundAfterAnimations()
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
      self.backgroundView.backgroundColor = self.isTapped ? tappedBackgroundColor : self.configuration.backgroundColor
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
    let color = isTapped ? .clear : configuration.backgroundColor
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
