//
//  AKButton+Rx.swift
//  AKRxButton
//
//  Created by Alexander Kolov on 2020-07-28.
//  Copyright © 2020 Alexander Kolov. All rights reserved.
//

import AKButton
import RxCocoa
import RxSwift

extension Reactive where Base: AKButton {

  public var isLoading: Binder<Bool> {
    return Binder(base) { button, value in
      button.isLoading = value
    }
  }

}
