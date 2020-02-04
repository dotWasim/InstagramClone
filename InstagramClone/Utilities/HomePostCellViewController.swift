//
//  HomeCellViewController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/15/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class HomePostCellViewController: UICollectionViewController, NewHomePostCellDelegate {

    var posts = [HomePost]()
    
    func showEmptyStateViewIfNeeded() {}
    
    //MARK: - HomePostCellDelegate
    
    func didTapTitle(post: HomePost) {
        let vc = HomePostDetailsController()
        vc.post = post
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didTapShare(post: HomePost) {

        if let myWebsite = URL(string: post.link) {//Enter link to your app here
            let objectsToShare = [post.title, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    
    func didTapComment(post: HomePost) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.postId = post.id
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapTitle(user: User) {
        
    }
    
    
    func didLike(for cell: NewHomePostCell) {
        guard let indexPath = collectionView?.indexPath(for: cell) else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var post = posts[indexPath.item]
        
        if post.likedByCurrentUser {
            Database.database().reference().child("likes").child(post.id).child(uid).removeValue { (err, _) in
                if let err = err {
                    print("Failed to unlike post:", err)
                    return
                }
                post.likedByCurrentUser = false
                post.likes = post.likes - 1
                self.posts[indexPath.item] = post
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            }
        } else {
            let values = [uid : 1]
            Database.database().reference().child("likes").child(post.id).updateChildValues(values) { (err, _) in
                if let err = err {
                    print("Failed to like post:", err)
                    return
                }
                post.likedByCurrentUser = true
                post.likes = post.likes + 1
                self.posts[indexPath.item] = post
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            }
        }
    }  
}

