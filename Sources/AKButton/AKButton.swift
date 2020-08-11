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

  public struct BorderStyle {
    public var color: UIColor
    public var width: CGFloat

    public init(color: UIColor, width: CGFloat) {
      self.color = color
      self.width = width
    }
  }

  public struct ShadowStyle {
    public var alpha: Float
    public var color: UIColor
    public var offset: CGSize
    public var radius: CGFloat

    public init(
      alpha: Float = 0,
      color: UIColor = .black,
      offset: CGSize = CGSize(width: 0, height: -3),
      radius: CGFloat = 3
    ) {
      self.alpha = alpha
      self.color = color
      self.offset = offset
      self.radius = radius
    }
  }

  public struct Configuration {
    public var cornerRadius: CGFloat
    public var backgroundColor: (UIControl.State) -> UIColor
    public var foregroundColor: (UIControl.State) -> UIColor
    public var borderStyle: ((UIControl.State) -> BorderStyle?)?
    public var shadowStyle: ((UIControl.State) -> ShadowStyle?)?
    public var tapAnimationDuration: TimeInterval
    public var tappedForegroundAlpha: CGFloat
    public var font: UIFont
    public var contentAlignment: UIStackView.Alignment
    public var spacing: CGFloat
    public var layoutMargins: UIEdgeInsets

    public init(
      cornerRadius: CGFloat = 8,
      backgroundColor: @escaping (UIControl.State) -> UIColor = { _ in .systemBlue },
      foregroundColor: @escaping (UIControl.State) -> UIColor = { _ in .white },
      borderStyle: ((UIControl.State) -> BorderStyle?)? = nil,
      shadowStyle: ((UIControl.State) -> ShadowStyle?)? = nil,
      tapAnimationDuration: TimeInterval = 0.3,
      tappedForegroundAlpha: CGFloat = 0.75,
      font: UIFont = {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let metrics = UIFontMetrics(forTextStyle: .body)
        return metrics.scaledFont(for: font)
      }(),
      contentAlignment: UIStackView.Alignment = .center,
      spacing: CGFloat = 15,
      margins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    ) {
      self.cornerRadius = cornerRadius
      self.backgroundColor = backgroundColor
      self.foregroundColor = foregroundColor
      self.borderStyle = borderStyle
      self.shadowStyle = shadowStyle
      self.tapAnimationDuration = tapAnimationDuration
      self.tappedForegroundAlpha = tappedForegroundAlpha
      self.font = font
      self.contentAlignment = contentAlignment
      self.spacing = spacing
      self.layoutMargins = margins
    }
  }

  // MARK: Properties

  public var attributedTitle: ((UIControl.State) -> NSAttributedString?)? {
    didSet {
      updateTitle()
    }
  }

  public var title: (UIControl.State) -> String? = { _ in "Placeholder" } {
    didSet {
      updateTitle()
    }
  }

  public var image: (UIControl.State) -> (UIImage?, UIImageView.ContentMode) = { _ in (nil, .scaleToFill) } {
    didSet {
      let (_image, contentMode) = image(state)
      imageView.image = _image
      imageView.isHidden = _image == nil
      imageView.contentMode = contentMode
    }
  }

  public var action: (() -> Void)?

  open var configuration: Configuration {
    didSet {
      configure()
    }
  }

  open override var isEnabled: Bool {
    didSet {
      updateState()
    }
  }

  open override var isHighlighted: Bool {
    didSet {
      updateState()
    }
  }

  open override var isSelected: Bool {
    didSet {
      updateState()
    }
  }

  open var isLoading: Bool = false {
    didSet {
      updateLoadingState()
    }
  }

  private var isTapped: Bool = false

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
    foregroundView.alignment = configuration.contentAlignment
    foregroundView.translatesAutoresizingMaskIntoConstraints = false
    foregroundView.isLayoutMarginsRelativeArrangement = true
    foregroundView.layoutMargins = self.configuration.layoutMargins
    return foregroundView
  }()

  public private(set) lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.backgroundColor = .clear
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    return titleLabel
  }()

  public let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.isHidden = true
    imageView.contentMode = .scaleToFill
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  public let loadingIndicator: UIActivityIndicatorView = {
    let loadingIndicator = UIActivityIndicatorView()
    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    return loadingIndicator
  }()

  // MARK: Initialization

  public static func empty() -> AKButton {
    let config = Configuration(
      cornerRadius: 0,
      backgroundColor: { _ in .clear },
      foregroundColor: { _ in .clear },
      margins: .zero
    )

    let button = AKButton(configuration: config)
    button.title = { _ in nil }
    return button
  }

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
    containerView.addSubview(loadingIndicator)
    foregroundView.addArrangedSubview(imageView)
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
      foregroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      foregroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      foregroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
      foregroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
    ])

    NSLayoutConstraint.activate([
      loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      loadingIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
      loadingIndicator.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
      loadingIndicator.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
      loadingIndicator.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor)
    ])

    addTarget(self, action: #selector(didTouchDownInside), for: [.touchDown, .touchDownRepeat])
    addTarget(self, action: #selector(didTouchUpInside), for: [.touchUpInside])
    addTarget(self, action: #selector(didDragInside), for: [.touchDragEnter])
    addTarget(self, action: #selector(didDragOutside), for: [.touchDragExit, .touchCancel])
  }

  // MARK: View Lifecycle

  open override func layoutSubviews() {
    super.layoutSubviews()
    if configuration.shadowStyle != nil
    && layer.shadowPath?.boundingBoxOfPath != bounds {
      updateShadowPath()
    }
  }

  // MARK: Private methods

  private func configure() {
    updateState()

    backgroundView.layer.cornerRadius = configuration.cornerRadius
    foregroundView.alignment = configuration.contentAlignment
    foregroundView.spacing = configuration.spacing
    foregroundView.layoutMargins = configuration.layoutMargins

    if attributedTitle?(state) == nil {
      titleLabel.font = configuration.font
    }
  }

  private func updateState() {
    backgroundView.backgroundColor = configuration.backgroundColor(state)
    imageView.tintColor = configuration.foregroundColor(state)
    loadingIndicator.color = configuration.foregroundColor(state)

    if attributedTitle?(state) == nil {
      titleLabel.textColor = configuration.foregroundColor(state)
    }

    let borderStyle = configuration.borderStyle?(state)
    backgroundView.layer.borderColor = borderStyle?.color.cgColor
    backgroundView.layer.borderWidth = borderStyle?.width ?? 0

    if let shadowStyle = configuration.shadowStyle?(state) {
      layer.shadowOffset = shadowStyle.offset
      layer.shadowRadius = shadowStyle.radius
      layer.shadowOpacity = shadowStyle.alpha
      layer.shadowColor = shadowStyle.color.cgColor
    }
    else {
      layer.shadowOpacity = 0
    }

    updateShadowPath()
    updateTitle()
  }

  private func updateLoadingState() {
    foregroundView.isHidden = isLoading
    if isLoading {
      loadingIndicator.color = configuration.foregroundColor(state)
      loadingIndicator.startAnimating()
    }
    else {
      loadingIndicator.stopAnimating()
    }
  }

  private func updateTitle() {
    if let attributedTitle = attributedTitle?(state) {
      titleLabel.attributedText = attributedTitle
    }
    else if let title = title(state) {
      titleLabel.text = title
    }
    else {
      titleLabel.text = nil
    }

    titleLabel.isHidden = titleLabel.text == nil && titleLabel.attributedText == nil
  }

  private func updateShadowPath() {
    guard configuration.shadowStyle?(state) != nil else {
      layer.shadowPath = nil
      return
    }

    layer.shadowPath = UIBezierPath(
      roundedRect: bounds,
      cornerRadius: configuration.cornerRadius
    ).cgPath
  }

  // MARK: Tap handling

  @objc
  private func didTouchDownInside() {
    isTapped = true
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
    updateBorderStyle(animated: true)
  }

  @objc
  private func didTouchUpInside() {
    isTapped = false
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
    updateBorderStyle(animated: true)
    sendActions(for: .primaryActionTriggered)
    action?()
  }

  @objc
  private func didDragInside() {
    isTapped = true
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
    updateBorderStyle(animated: true)
  }

  @objc
  private func didDragOutside() {
    isTapped = false
    updateForegroundAlpha(animated: true)
    updateBackgroundColor(animated: true)
    updateBorderStyle(animated: true)
  }

  // MARK: Animations

  private func updateBorderStyle(animated: Bool) {
    let borderStyle = configuration.borderStyle?(state)

    let animations = {
      self.backgroundView.layer.borderColor = borderStyle?.color.cgColor
      self.backgroundView.layer.borderWidth = borderStyle?.width ?? 0
    }

    if animated {
      let colorAnimation = CABasicAnimation(keyPath: "borderColor")
      colorAnimation.toValue = borderStyle?.color.cgColor

      let widthAnimation = CABasicAnimation(keyPath: "borderWidth")
      widthAnimation.toValue = borderStyle?.width

      let groupAnimation = CAAnimationGroup()
      groupAnimation.animations = [colorAnimation, widthAnimation]
      groupAnimation.duration = configuration.tapAnimationDuration

      backgroundView.layer.removeAnimation(forKey: "border")
      backgroundView.layer.add(groupAnimation, forKey: "border")
    }

    animations()
  }

  private func updateBackgroundColor(animated: Bool) {
    let animations = {
      self.backgroundView.backgroundColor = self.configuration.backgroundColor(self.state)
    }

    if !animated {
      animations()
    }
    else {
      UIView.transition(
        with: backgroundView,
        duration: configuration.tapAnimationDuration,
        options: [.beginFromCurrentState, .transitionCrossDissolve],
        animations: animations,
        completion: nil
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
      UIView.animate(
        withDuration: configuration.tapAnimationDuration,
        delay: 0,
        options: [.beginFromCurrentState],
        animations: animations,
        completion: nil
      )
    }
  }

}
