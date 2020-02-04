//
//  HomePostDetailsController.swift
//  InstagramClone
//
//  Created by Wasim Alatrash on 2/4/20.
//  Copyright © 2020 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class HomePostDetailsController: UIViewController {
    
    var delegate: NewHomePostCellDelegate?
    
    var post: HomePost! {
        didSet {
            setData()
        }
    }
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let padding: CGFloat = 12
    
    private let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()
    
    private let sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    private let likeCounter: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    static var cellId = "NewhomePostCellId"
    
    override func viewDidLoad() {
        title = post.title
        let scrollView = UIScrollView()
        
        view.addSubview(scrollView)
        scrollView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, width: view.frame.width)
        
        scrollView.addSubview(photoImageView)
        photoImageView.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor)
        photoImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        
        setupActionButtons()

        scrollView.addSubview(likeCounter)
        likeCounter.anchor(top: likeButton.bottomAnchor, left: view.leftAnchor, paddingTop: padding, paddingLeft: padding)
        
        scrollView.addSubview(descriptionLabel)
        descriptionLabel.anchor(top: likeCounter.bottomAnchor, left: view.leftAnchor, bottom: scrollView.bottomAnchor , right: view.rightAnchor, paddingTop: padding - 6, paddingLeft: padding, paddingBottom: padding, paddingRight: padding)
    }
    
    private func setupActionButtons() {
        sendMessageButton.addTarget(self, action: #selector(handleShare), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, sendMessageButton])
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.spacing = 16
        view.addSubview(stackView)
        stackView.anchor(top: photoImageView.bottomAnchor, left: view.leftAnchor, paddingTop: padding, paddingLeft: padding)
    }
    
    private func setData() {
        guard let post = post else { return }
        photoImageView.loadImage(urlString: post.imageUrl)
        likeButton.setImage(post.likedByCurrentUser == true ? #imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        setLikes(to: post.likes)
        setupAttributedCaption()
    }
    
    private func setupAttributedCaption() {
        let data = Data(post.description.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            descriptionLabel.attributedText = attributedString
        }
    }
    
    private func setLikes(to value: Int) {
        if value <= 0 {
            likeCounter.text = ""
        } else if value == 1 {
            likeCounter.text = "1 like"
        } else {
            likeCounter.text = "\(value) likes"
        }
    }
        
    @objc private func handleLike() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if post.likedByCurrentUser {
            Database.database().reference().child("likes").child(post.id).child(uid).removeValue { (err, _) in
                if let err = err {
                    print("Failed to unlike post:", err)
                    return
                }
                self.post.likedByCurrentUser = false
                self.post.likes = self.post.likes - 1
            }
        } else {
            let values = [uid : 1]
            Database.database().reference().child("likes").child(post.id).updateChildValues(values) { (err, _) in
                if let err = err {
                    print("Failed to like post:", err)
                    return
                }
                self.post.likedByCurrentUser = true
                self.post.likes = self.post.likes + 1
            }
        }
    }
    
    @objc private func handleComment() {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.postId = post.id
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    @objc private func handleShare() {
        if let myWebsite = URL(string: post.link) {//Enter link to your app here
            let objectsToShare = [post.title, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}
