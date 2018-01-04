//
//  FilterMenuCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 23..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import DropDownMenuKit

protocol FilterMenuCellDelegate: class {
    func editingDidBegin(tag: Int)
    func editingDidEnd(tag: Int, index: Int)
}

class FilterMenuCell: DropDownMenuCell {

    weak var delegate: FilterMenuCellDelegate?
    
    var textField: NonCursorTextField?
    var pickerView: UIPickerView?
    var toolBar: UIToolbar?
    var selectedRow: Int = 0
    
    var data: [String] = [] {
        didSet {
            self.pickerView?.reloadComponent(0)
            
            guard let textField = self.textField else {
                fatalError("FilterMenuCell > initView Error")
            }
            
            print("\(className) > \(#function) > data[0] : \(data[0])")
            
            textField.text = data[0]
        }
    }

    override init() {
        super.init()
        
        print("\(className) > \(#function)")
        
        data = [String]()
        
        initPicker()
        initTextField()
    }
    
    convenience init(data: [String]) {
        self.init()
        self.data = data
        
        print("\(className) > \(#function) > data : \(data)")
        
        self.pickerView?.reloadComponent(0)
        
        guard let textField = self.textField else {
            fatalError("FilterMenuCell > initView Error")
        }
        
        textField.text = data[0]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("\(className) > \(#function) > required init")
        
        initPicker()
        initTextField()
    }
    
    func initTextField() {
        
        print("\(className) > \(#function)")
        
        self.textField = NonCursorTextField(frame: self.frame)
        
        guard let textField = self.textField else {
            fatalError("\(className) > \(#function) > Error")
        }
        
        textField.inputView = pickerView
        self.customView = textField
        
        textField.addTarget(self, action: #selector(self.beginEditing(_:)), for: .editingDidBegin)
        
        self.toolBar = UIToolbar()
        
        guard let toolbar = self.toolBar else {
            fatalError("\(className) > \(#function) > Toolbar Error")
        }
        
        toolbar.barStyle = UIBarStyle.default
        toolbar.isTranslucent = true
        toolbar.tintColor = UIColor(netHex: 0xf2797c)
        toolbar.backgroundColor = .white
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.done(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancel(_:)))
        
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        
        textField.inputAccessoryView = toolbar
    }
    
    func setEnabled(_ isEnabled: Bool) {
        self.textField?.isEnabled = isEnabled
    }

    func done(_ sender: Any) {
        print("\(className) > \(#function)")
        self.accessoryType = .none
        self.textField?.resignFirstResponder()
        
        self.textField?.text = data[selectedRow]
        
        delegate?.editingDidEnd(tag: self.tag, index: selectedRow)
    }
    
    func cancel(_ sender: Any) {
        print("\(className) > \(#function)")
        self.accessoryType = .none
        self.textField?.resignFirstResponder()
    }
    
    func dismiss() {
        print("\(className) > \(#function)")
        self.accessoryType = .none
        self.textField?.resignFirstResponder()
    }
    
    func beginEditing(_ sender: Any) {
        print("\(className) > \(#function)")
        delegate?.editingDidBegin(tag: self.tag)
    }
    
}

extension FilterMenuCell: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func initPicker() {
        
        self.pickerView = UIPickerView()
        
        guard let picker = self.pickerView else {
            fatalError("FilterMenuCell > initPicker > Error")
        }
        
        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .white
    }
    
    // MARK: UIPIckerView Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("\(className) > \(#function) : \(row)")
        
        //        self.textField?.text = data[row]
        self.selectedRow = row
    }
}
