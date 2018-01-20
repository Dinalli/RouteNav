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
    return 4
  }
  
  public func onboardingView(_ onboardingView: OnboardingView, configurationForPage page: Int) -> OnboardingConfiguration {
    switch page {
      
    case 0:
      return OnboardingConfiguration(
        image: UIImage(named: "LogoIcon")!,
        itemImage: UIImage(named: "blackBikeIcon")!,
        pageTitle: "Connect to Strava",
        pageDescription: "You will need to connect to your Strava account \n to use this app. \n Connect using facebook, google+ or Strava account.",
        backgroundImage: UIImage(named: "cycling-bicycle-riding-sport-38296"),
        topBackgroundImage: UIImage(named: "BackgroundOrange"),
        bottomBackgroundImage: UIImage(named: "WavesImage")
      )
        
    case 1:
        return OnboardingConfiguration(
            image: UIImage(named: "LogoIcon")!,
            itemImage: UIImage(named: "blackBikeIcon")!,
            pageTitle: "Location",
            pageDescription: "We need to use your location to show you \n where you are on a Map in relation to your routes,\n  we also need it to track you as you navigate.",
            backgroundImage: UIImage(named: "pexels-photo-287398"),
            topBackgroundImage: UIImage(named: "BackgroundOrange"),
            bottomBackgroundImage: UIImage(named: "WavesImage")
        )
      
    case 2:
      return OnboardingConfiguration(
        image: UIImage(named: "LogoIcon")!,
        itemImage: UIImage(named: "blackBikeIcon")!,
        pageTitle: "Download Routes",
        pageDescription: "Download your saved routes, \n \n View route details on the Map",
        backgroundImage: UIImage(named: "RouteMaps"),
        topBackgroundImage: UIImage(named: "BackgroundOrange"),
        bottomBackgroundImage: UIImage(named: "WavesImage")
      )
        
    case 3:
        return OnboardingConfiguration(
            image: UIImage(named: "LogoIcon")!,
            itemImage: UIImage(named: "blackBikeIcon")!,
            pageTitle: "Navigate",
            pageDescription: "Select a route to Navigate \n\n Track your progress",
            backgroundImage: UIImage(named: "Navigate"),
            topBackgroundImage: UIImage(named: "BackgroundOrange"),
            bottomBackgroundImage: UIImage(named: "WavesImage")
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
