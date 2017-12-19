//
//  PagerView.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 13..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit

protocol PagerViewDelegate: class {
    func loadPageViewItem(imageView: UIImageView, page: Int)
    func onPageTapped(page: Int)
}

class PagerView: UIView, UIScrollViewDelegate {
    
    var scrollView : UIScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    var pageControl : UIPageControl = UIPageControl(frame:CGRect(x: 0, y: 0, width: 0, height: 0))
    
    var pageViews : [UIImageView?] = []
    weak var delegate : PagerViewDelegate?
    
    var pageCount = 0 {
        didSet {
            initViews()
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
    override func layoutSubviews() {
        printLog(#function)
        loadVisiblePages()
    }
    */
    
    func initViews() {
        initPageViews()
        configureScrollView()
        configurePageControl()
        loadVisiblePages()
    }
    
    func initPageViews() {
        
        self.pageViews = []
        
        for _ in 0..<pageCount {
            self.pageViews.append(nil)
        }
    }
    
    func configureScrollView() {
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        scrollView.bounces = false
        scrollView.delegate = self
        self.addSubview(scrollView)
        
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(pageCount), height: self.scrollView.frame.size.height)
    }
    
    func configurePageControl() {
        
        pageControl = UIPageControl(frame: CGRect(x: 0, y: self.frame.height - 30, width: self.frame.width, height: 30))
        
        pageControl.numberOfPages = pageCount
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.red
        pageControl.pageIndicatorTintColor = UIColor.black
        pageControl.currentPageIndicatorTintColor = UIColor.white
        pageControl.hidesForSinglePage = true
        
        self.addSubview(pageControl)
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadVisiblePages()
    }
    
    func getPageItem(_ index: Int) -> UIImageView? {
        guard let imageView = pageViews[index] else {
            return nil
        }
        return imageView
    }
    
    private func loadPage(page: Int) {
        
        if (page < 0 || page >= self.pageCount) { return }
        
        if self.pageViews[page] == nil {
            var subViewFrame : CGRect = CGRect()
            subViewFrame.origin.x = self.scrollView.frame.size.width * CGFloat(page)
            subViewFrame.size = self.scrollView.frame.size
            
            let subView = UIImageView(frame: subViewFrame)
            subView.contentMode = .scaleAspectFill
            subView.clipsToBounds = true
            subView.tag = page
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                              action: #selector(PagerView.onPageTapped(_:)))
            tapGestureRecognizer.numberOfTapsRequired = 1
            subView.isUserInteractionEnabled = true
            subView.addGestureRecognizer(tapGestureRecognizer)
            
            self.scrollView.addSubview(subView)
            self.pageViews[page] = subView
        }
        
        // display each ImageView dispatch
        
        if let imageView = pageViews[page] {
            delegate?.loadPageViewItem(imageView: imageView, page: page)
        }
    }
    
    private func purgePage(page: Int) {
        if (page < 0 || page >= self.pageCount) { return }
        
        if let pageView = self.pageViews[page] {
            pageView.removeFromSuperview()
            self.pageViews[page] = nil
        }
    }
    
    func onPageTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        
        if let imageView = gestureRecognizer.view as? UIImageView {
            delegate?.onPageTapped(page: imageView.tag)
        }
    }
    
    private func loadVisiblePages() {
        
        if scrollView.frame.size.width == 0.0 {
            return
        }
        
        let page = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        self.pageControl.currentPage = page
        
        let prevPage = page - 1
        let nextPage = page + 1
        
        if prevPage > 0 {
            for index in 0..<prevPage {
                self.purgePage(page: index)
            }
        }
        
        for index in prevPage...nextPage {
            self.loadPage(page: index)
        }
        
        if nextPage < self.pageCount {
            for index in nextPage + 1 ..< self.pageCount {
                self.purgePage(page: index)
            }
        }
    }

}
