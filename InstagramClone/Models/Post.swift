//
//  Post.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import Foundation

struct Post {
    
    var id: String
    
    let user: User
    let imageUrl: String
    let caption: String
    let creationDate: Date
    
    var likes: Int = 0
    var likedByCurrentUser = false
    
    init(user: User, dictionary: [String: Any]) {
        self.user = user
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
    }
}

struct HomePost {
    
    var id: String
    
    var imageUrl: String?
    let title: String
    let caption: String
    let description: String
    let creationDate: Date
    let link: String

    var likes: Int = 0
    var likedByCurrentUser = false
    
    init(_ post: [String: Any]) {
        
        if let title = post["title"] as? [String : Any], let rendered = title["rendered"] as? String{
            self.title = rendered.replacingOccurrences(of: "<p>", with: "")
        } else {
            self.title = ""
        }
        
        
        if let excerpt = post["excerpt"] as? [String : Any], let rendered = excerpt["rendered"] as? String{
            self.caption = rendered.stripOutHtml() ?? ""
        }else {
            self.caption = ""
        }
        
        if let excerpt = post["content"] as? [String : Any], let rendered = excerpt["rendered"] as? String{
            self.description = rendered
        }else {
            self.description = ""
        }
        
        if let imageLink = post["featured_image_src"] as? String{
            self.imageUrl = imageLink
        }
        
    
        if let dateString = post["date"] as? String,
            let date = DateFormatter.homeFormat.date(from: dateString) {
            creationDate = date
        } else {
            creationDate = Date()
        }
        
        id = String(post["id"] as! Int)
        self.link = post["link"] as? String ?? ""
    }
}


extension DateFormatter {
    static var homeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }
}

extension String {

    func stripOutHtml() -> String? {
        do {
            guard let data = self.data(using: .unicode) else {
                return nil
            }
            let attributed = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            return attributed.string
        } catch {
            return nil
        }
    }
}
