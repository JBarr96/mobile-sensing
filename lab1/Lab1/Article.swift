//
//  Article.swift
//  Lab1
//
//  Created by Johnathan Barr on 9/12/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import Foundation

class Article {
    let source, author, title, description, url, urlToImage, publishedAt, content: String
    
    init(source: String, author: String, title: String, description: String, url: String, urlToImage: String, publishedAt: String, content: String) {
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
    }
}

