//
//  UserProfileController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 3/19/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class UserProfileController: ProfilePostCellViewController {
    
    var user: User? {
        didSet {
            configureUser()
        }
    }
    
    lazy var refreshController = UIActivityIndicatorView(style: .whiteLarge)
    private var finishUpdatingUserProfile = true {
        didSet {
            if !self.finishUpdatingUserProfile {
                refreshController.center = header!.profileImageView.center
                refreshController.startAnimating()
                view.addSubview(refreshController)
            }else{
                refreshController.stopAnimating()
                refreshController.removeFromSuperview()
            }
        }
    }
    
    private var header: UserProfileHeader?
    
    private let alertController: UIAlertController = {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        return ac
    }()
    
//    private var isFinishedPaging = false
//    private var pagingCount: Int = 4
    
    private var isGridView: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateUserProfileFeed, object: nil)
        
        collectionView?.backgroundColor = .white
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UserProfileHeader.headerId)
        collectionView?.register(UserProfilePhotoGridCell.self, forCellWithReuseIdentifier: UserProfilePhotoGridCell.cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.register(UserProfileEmptyStateCell.self, forCellWithReuseIdentifier: UserProfileEmptyStateCell.cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        configureAlertController()
    }
    
    private func configureAlertController() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let logOutAction = UIAlertAction(title: "Log Out", style: .default) { (_) in
            do {
                try Auth.auth().signOut()
                (UIApplication.shared.delegate as! AppDelegate).setupMainView()
//                let loginController = LoginController()
//                let navController = UINavigationController(rootViewController: loginController)
//                navController.modalPresentationStyle = .fullScreen
//                self.present(navController, animated: true, completion: nil)
            } catch let err {
                print("Failed to sign out:", err)
            }
        }
        alertController.addAction(logOutAction)
    }
    
    private func configureUser() {
        guard let user = user else { return }
        
        if user.uid == Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleSettings))
        } else {
            let optionsButton = UIBarButtonItem(title: "•••", style: .plain, target: nil, action: nil)
            optionsButton.tintColor = .black
            navigationItem.rightBarButtonItem = optionsButton
        }
        
        navigationItem.title = user.username
        header?.user = user
        
        handleRefresh()
    }
    
    @objc private func handleSettings() {
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handleRefresh() {
        guard let uid = user?.uid else { return }
                
        //TODO: Replace this with pagination
        Database.database().fetchAllPosts(withUID: uid, completion: { (posts) in
            self.posts.removeAll()
            self.posts = posts
            self.posts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
            
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
        
        header?.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if posts.count == 0 {
            return 1
        }
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if posts.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserProfileEmptyStateCell.cellId, for: indexPath)
            return cell
        }
        
//        if indexPath.item == posts.count - 1, !isFinishedPaging {
//            paginatePosts()
//        }
        
        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserProfilePhotoGridCell.cellId, for: indexPath) as! UserProfilePhotoGridCell
            cell.post = posts[indexPath.item]
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
        cell.post = posts[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UserProfileHeader.headerId, for: indexPath) as? UserProfileHeader
            header?.delegate = self
            header?.user = user
        }
        return header!
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
    
extension UserProfileController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if posts.count == 0 {
            let emptyStateCellHeight = (view.safeAreaLayoutGuide.layoutFrame.height - 200)
            return CGSize(width: view.frame.width, height: emptyStateCellHeight)
        }
        
        if isGridView {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            let dummyCell = HomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
            let post = posts[indexPath.item]
            dummyCell.post = post
            dummyCell.layoutIfNeeded()
            
            var height: CGFloat = dummyCell.header.bounds.height
            height += view.frame.width
            height += 24 + 2 * dummyCell.padding //bookmark button + padding
            height += dummyCell.captionLabel.intrinsicContentSize.height + 8
            height += post.likes > 0 ? 10 : 0
            //TODO: unsure why this is needed
            height += 8
            
            return CGSize(width: view.frame.width, height: height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
}

//MARK: - UserProfileHeaderDelegate

extension UserProfileController: UserProfileHeaderDelegate {
    
    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }
    
    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }
    
    func handleChangeAvatar() {
        let actionsheet = UIAlertController(title: "Pick source type", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) in
                let vc = UIImagePickerController()
                vc.sourceType = .camera
                vc.allowsEditing = true
                vc.delegate = self
                self.present(vc, animated: true)
            }
            actionsheet.addAction(cameraAction)

        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { (_) in
                let vc = UIImagePickerController()
                vc.sourceType = .photoLibrary
                vc.allowsEditing = true
                vc.delegate = self
                self.present(vc, animated: true)
            }
            actionsheet.addAction(photoAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        
        actionsheet.addAction(cancelAction)
        
        present(actionsheet, animated: true) {
            
        }
        
    }
}

extension UserProfileController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        guard let uid = user?.uid,
            let username = user?.username else {
                return
        }

        header?.profileImageView.image = image
        finishUpdatingUserProfile = false
        Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
            Auth.auth().uploadUser(withUID: uid, username: username, profileImageUrl: profileImageUrl) {
                self.finishUpdatingUserProfile = true
            }
        })
    }
    
}

