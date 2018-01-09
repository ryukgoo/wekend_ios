//
//  EditProfileViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    // MARK: IBOutlet
    @IBOutlet weak var mainEditImage: EditImageView!
    @IBOutlet weak var editImage1: EditImageView!
    @IBOutlet weak var editImage2: EditImageView!
    @IBOutlet weak var editImage3: EditImageView!
    @IBOutlet weak var editImage4: EditImageView!
    @IBOutlet weak var editImage5: EditImageView!
    
    @IBOutlet weak var introductTextView: UITextView!
    
    var editImages: [EditImageView]!
    var viewModel: EditProfileViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        introductTextView.isScrollEnabled = false
        initEditImages()
        bindViewModel()
        
        viewModel?.loadUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    fileprivate func bindViewModel() {
        print("\(className) > \(#function)")
        guard let viewModel = viewModel else { return }
        viewModel.user.bindAndFire { [weak self] user in
            guard let user = user else { return }
            guard let editImages = self?.editImages else { return }
            for editImage in editImages {
                guard let imageUrl = self?.getImageUrl(id: user.userid, index: editImage.index) else { return }
                editImage.image.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
                    (image, error, cachedType, url) in
                }
            }
        }
    }
    
    private func initEditImages() {
        editImages = [mainEditImage, editImage1, editImage2, editImage3, editImage4, editImage5]
        
        for image in editImages {
            image.addGestureRecognizer(getTapGestureRecognizer())
        }
    }
    
    private func getImageUrl(id: String, index: Int) -> String {
        let imageName = "\(id)/\(Configuration.S3.PROFILE_IMAGE_NAME(index))"
        return Configuration.S3.PROFILE_IMAGE_URL + imageName
    }

    func editImageTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        guard let editView = tapGestureRecognizer.view as? EditImageView else {
            print("\(className) > \(#function) > sender : \(tapGestureRecognizer)")
            return
        }
        print("\(className) > \(#function) > \(editView.index)")
    }
    
    private func getTapGestureRecognizer() -> UITapGestureRecognizer {
        return UITapGestureRecognizer(target: self, action: #selector(self.editImageTapped(_:)))
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
