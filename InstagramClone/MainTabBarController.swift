//
//  MainTabBarController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 3/19/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .black
        tabBar.isTranslucent = false
        delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if Auth.auth().currentUser == nil {
            presentLoginController()
        } else {
            setupViewControllers()
        }
    }
    
    func setupViewControllers() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeController(collectionViewLayout: UICollectionViewFlowLayout()))
        let plusNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let userProfileNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_selected"), rootViewController: userProfileController)
        
        Database.database().fetchUser(withUID: uid) { (user) in
            userProfileController.user = user
        }
        
        viewControllers = [homeNavController, plusNavController ,userProfileNavController]
    }

    var authUI: FUIAuth?

    private func presentLoginController() {
        self.authUI = FUIAuth.defaultAuthUI()
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        self.authUI?.delegate = self
        self.authUI?.shouldHideCancelButton = true
        
        // privacy
        let kFirebaseTermsOfService = URL(string: "https://gigglepets.net/privacy/")!
        authUI?.tosurl = kFirebaseTermsOfService
        
        var providers: [FUIAuthProvider] = [
            FUIEmailAuth(),
            FUIGoogleAuth(),
            FUIFacebookAuth()
        ]
        
        if #available(iOS 13.0, *) {
            let appleProvider = FUIOAuth.appleAuthProvider()
            
            providers.append(appleProvider)
        }
        
        self.authUI?.providers = providers
        
        let loginController = self.authUI!.authViewController() //LoginController()
        //let navController = UINavigationController(rootViewController: loginController)
        loginController.modalPresentationStyle = .fullScreen
        let imgView = UIImageView(image: #imageLiteral(resourceName: "logo.png") )
        imgView.contentMode = .scaleAspectFit
        imgView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: loginController.view.safeAreaLayoutGuide.layoutFrame.width, height: 200)
        loginController.view.backgroundColor = .white
        
        for child in loginController.children {
            for subview in child.view.subviews{
                subview.backgroundColor = .white
                if let scrollView = subview as? UIScrollView {
                    let viewFrame = scrollView.bounds.height
                    imgView.frame = CGRect(x: 0, y: viewFrame/3 - 100, width: loginController.view.safeAreaLayoutGuide.layoutFrame.width, height: 200)

                    scrollView.subviews.forEach({ $0.backgroundColor = .white })
                    scrollView.addSubview(imgView)
                }
            }
        }

//        loginController.children.first?.view.addSubview(imgView)
        self.present(loginController, animated: true, completion: nil)
    }
    
    private func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let viewController = rootViewController
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.isTranslucent = false
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        navController.tabBarItem.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        return navController
    }
}

//MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.index(of: viewController)
        if index == 1 {
            let layout = UICollectionViewFlowLayout()
            let photoSelectorController = PhotoSelectorController(collectionViewLayout: layout)
            let nacController = UINavigationController(rootViewController: photoSelectorController)
            present(nacController, animated: true, completion: nil)
            return false
        }
        return true
    }
}



extension MainTabBarController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        print(authDataResult?.user)
        
    }
}
