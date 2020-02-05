//
//  HomeController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class HomeController: HomePostCellViewController {
   
    private var currentPageNumber = 1
    private var isLoadingData = false
    var likesData: [String: Any] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(NewHomePostCell.self, forCellWithReuseIdentifier: NewHomePostCell.cellId)
        collectionView?.backgroundView = HomeEmptyStateView()
        collectionView?.backgroundView?.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateHomeFeed, object: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        fetchAllPosts()
    }
    
    private func configureNavigationBar() {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "logo").withRenderingMode(.alwaysOriginal))
        imgView.contentMode = .scaleAspectFit
        navigationItem.titleView = imgView
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }
    
    private func fetchAllPosts() {
        currentPageNumber = 1
        getData()
    }
    
    let dispatchQueue = DispatchQueue(label: "com.app.pets.serial")
    var data: Data?
    var response: URLResponse?
    var error :Error?
    
    let dispatchGroup = DispatchGroup()
    func getData(){
        guard !isLoadingData else { return }
        isLoadingData = true
        if self.currentPageNumber == 1 {
            self.collectionView?.refreshControl?.beginRefreshing()
        }
        
        let urlString = "https://gigglepets.net/wp-json/wp/v2/posts?page=\(currentPageNumber)&per_page=20&_fields=id,excerpt.rendered,title.rendered,link,featured_image_src,featured_media,content,date"
        
        var request = URLRequest.init(url: URL(string: urlString)!)
       // request.allHTTPHeaderFields = ["Authorization" : "Bearer DkuIGd5zUPuIjsy8bV7hOOOEqg91F5BC"]
        
        dispatchGroup.enter()
        dispatchQueue.async {
            Database.database().fetchHomePostsLikes { (data) in
                self.likesData = data
                self.dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        dispatchQueue.async {
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                self.data = data
                self.response = response
                self.error = error
                self.dispatchGroup.leave()
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            
            if self.collectionView.refreshControl?.isRefreshing ?? false {
                self.collectionView.refreshControl?.endRefreshing()
            }
            

            if let _ = self.error {
                if self.currentPageNumber == 1 {
                    self.showEmptyStateViewIfNeeded()
                }
                else{
                    self.currentPageNumber -= 1
                }
                return
            }
            
            guard let httpResponse = self.response as? HTTPURLResponse, httpResponse.statusCode == 200 else{
                self.collectionView.reloadData()
                return
            }
            
            do {
                
                if self.currentPageNumber == 1 {
                    self.posts = []
                }

                let parsedData = try JSONSerialization.jsonObject(with: self.data!) as! [[String : Any]]
                let mappedPosts = parsedData.map{ HomePost($0)}
                
                self.posts.append(contentsOf: mappedPosts)
                self.posts.enumerated().forEach { (index, post) in
                    let likes = self.likesData[post.id] as? [String: Any]
                    self.posts[index].likes = likes?.count ?? 0
                    if let userId = self.userId {
                        self.posts[index].likedByCurrentUser = likes?.keys.contains(userId) ?? false
                    }
                }
                
                self.collectionView.reloadData()
                
            } catch {
                self.currentPageNumber -= 1
            }
            self.isLoadingData = false
            self.showEmptyStateViewIfNeeded()
        }
        
        
    }
    
    func fetchLikes(){
        Database.database().fetchHomePostsLikes { (data) in
            self.likesData = data
        }
    }
    
    override func showEmptyStateViewIfNeeded() {
        if !isLoadingData && posts.isEmpty {
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                self.collectionView?.backgroundView?.alpha = 1
            }, completion: nil)
            
        } else {
            self.collectionView?.backgroundView?.alpha = 0
        }
    }
    
    @objc private func handleRefresh() {
        posts.removeAll()
        fetchAllPosts()
    }
    
    @objc private func handleCamera() {
        let cameraController = CameraController()
        present(cameraController, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastElement = self.posts.count - 1
        if indexPath.row == lastElement {
            self.currentPageNumber += 1
            self.getData()
        }
    }
    
    lazy var userId = Auth.auth().currentUser?.uid
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewHomePostCell.cellId, for: indexPath) as! NewHomePostCell
        if indexPath.item < posts.count {
            let post = posts[indexPath.item]
            cell.post = post
        }
        cell.delegate = self
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension HomeController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dummyCell = NewHomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
        let post = posts[indexPath.item]
        dummyCell.post = post
        dummyCell.layoutIfNeeded()
        
        var height: CGFloat = view.frame.width
        height += 24 + 2 * dummyCell.padding //bookmark button + padding
        height += dummyCell.captionLabel.intrinsicContentSize.height + 8
        height += post.likes > 0 ? 10 : 0

        return CGSize(width: view.frame.width, height: height)
    }
}
