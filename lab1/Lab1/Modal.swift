//
//  Modal.swift
//  Lab1
//
//  Created by Johnathan Barr on 9/14/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

// based on tutorial found here: https://www.youtube.com/watch?v=u6TpJrZNuPU

import Foundation
import UIKit
class Modal: UIView{
    
    let modalLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "Please provide search terms"
        label.textAlignment = .center
        return label
    }()
    
    let returnButton: UIButton = {
        let button = UIButton()
        button.setTitle("Okay", for: .normal)
        button.setTitleColor(UIColor(red: 0.08984375, green: 0.41015625, blue: 0.9921875, alpha: 0.9), for: .normal)
        button.addTarget(self, action: #selector(animateOut), for: .touchUpInside)
        return button
    }()
    
    let container:UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        return v
    }()
    
    lazy var stack:UIStackView = {
        let stack = UIStackView(arrangedSubviews: [modalLabel, returnButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        return stack
    }()
    
    @objc func animateIn(){
        self.container.transform = CGAffineTransform(translationX: 0, y: -self.frame.height)
        self.alpha = 0
        UIView.animate(withDuration: 1 , delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
            self.container.transform = .identity
            self.alpha = 1
        })
    }
    
    @objc func animateOut(){
        UIView.animate(withDuration: 1 , delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: {
            self.container.transform = CGAffineTransform(translationX: 0, y: -self.frame.height)
            self.alpha = 0
        }) { (complete) in
            if complete{
                self.removeFromSuperview()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        self.frame = UIScreen.main.bounds
        
        self.addSubview(container)
        container.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        container.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        container.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7).isActive = true
        container.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.2).isActive = true

        container.addSubview(stack)
        stack.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        stack.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.8).isActive = true
        
        animateIn()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
