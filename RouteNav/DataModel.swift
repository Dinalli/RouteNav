//
//  DataModel.swift
//  Athlee-Onboarding
//
//  Created by mac on 06/07/16.
//  Copyright © 2016 Athlee. All rights reserved.
//

import UIKit
import OnboardingKit

public final class DataModel: NSObject, OnboardingViewDelegate, OnboardingViewDataSource {
  
  public var didShow: ((Int) -> Void)?
  public var willShow: ((Int) -> Void)?
  
  public func numberOfPages() -> Int {
    return 2
  }
  
  public func onboardingView(_ onboardingView: OnboardingView, configurationForPage page: Int) -> OnboardingConfiguration {
    switch page {
      
    case 0:
      return OnboardingConfiguration(
        image: UIImage(named: "pexels-photo-287398")!,
        itemImage: UIImage(named: "LogoIcon")!,
        pageTitle: "PhotoFIT",
        pageDescription: "A new kind of fittness tracking! \n\n100% free, because great health should be accessible to all!",
        backgroundImage: nil,
        topBackgroundImage: nil,
        bottomBackgroundImage: nil
      )
      
    case 1:
      return OnboardingConfiguration(
        image: UIImage(named: "pexels-photo-287398")!,
        itemImage: UIImage(named: "LogoIcon")!,
        pageTitle: "Body Metrics",
        pageDescription: "Body metrics will never be the same! \n\nTrack bodyweight, body fat, and add a snap shot of your progress!",
        backgroundImage: nil,
        topBackgroundImage: nil,
        bottomBackgroundImage: nil
      )
      
    default:
      fatalError("Out of range!")
    }
  }
  
  public func onboardingView(_ onboardingView: OnboardingView, configurePageView pageView: PageView, atPage page: Int) {
    pageView.titleLabel.textColor = UIColor.white
    pageView.titleLabel.layer.shadowOpacity = 0.6
    pageView.titleLabel.layer.shadowColor = UIColor.black.cgColor
    pageView.titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
    pageView.titleLabel.layer.shouldRasterize = true
    pageView.titleLabel.layer.rasterizationScale = UIScreen.main.scale
  }
  
  public func onboardingView(_ onboardingView: OnboardingView, didSelectPage page: Int) {
    print("Did select pge \(page)")
    didShow?(page)
  }
  
  public func onboardingView(_ onboardingView: OnboardingView, willSelectPage page: Int) {
    print("Will select page \(page)")
    willShow?(page)
  }
}
