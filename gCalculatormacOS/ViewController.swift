//
//  ViewController.swift
//  gCalculatormacOS
//
//  Created by 高小强 on 2017/5/26.
//  Copyright © 2017年 高小强. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var caculateValue = [uint(0), uint(0)]
    
    var bitButtonArray = [[NSButton](), [NSButton]()]
    var textFieldArray = [[NSTextField](), [NSTextField]()]
    
    let bitWith : CGFloat = 33
    let bitHeight : CGFloat = 20
    let rowGap : CGFloat = 5
    let columnGap : CGFloat = 5
    let leftMargin : CGFloat = 20
    let topMargin : CGFloat = 20
    
    func label2tag(label: String) -> Int {
        if label == "Value 1" {
            return 0
        }
        
        return 1
    }
    
    func updateUI() {
        for (tag, buttonArray) in self.bitButtonArray.enumerated() {
            for (index, button) in buttonArray.enumerated() {
                if self.caculateValue[tag] & (uint(1) << uint(31 - index)) != 0 {
                    button.state = NSOnState
                } else {
                    button.state = NSOffState
                }
            }
        }
        
        for (tag, textField) in self.textFieldArray.enumerated() {
            textField[0].stringValue = "".appendingFormat("%08X", self.caculateValue[tag])
            textField[1].stringValue = "".appendingFormat("%11O", self.caculateValue[tag])
            textField[2].stringValue = "".appendingFormat("%11U", self.caculateValue[tag])
        }
    }
    
    
    func bitButtonPress(_ sender: NSButton) {
        var value = self.caculateValue[sender.tag]
        let index = (sender.title as NSString).intValue
        
        if value & (uint(1) << uint(index)) != 0 {
            value &= ~(uint(1) << uint(index))
        } else {
            value |= uint(1) << uint(index)
        }
        
        self.caculateValue[sender.tag] = value
        
        self.updateUI()
    }
    
    func textFieldEnter(_ sender: NSTextField) {
        var value: uint = 0
        let scan = Scanner.init(string: sender.stringValue)
        
        switch sender.identifier! {
        case "HEX":
            if scan.scanHexInt32(&value) {
                self.caculateValue[sender.tag] = value
            }
            break
        case "OCT":
            var error: Bool = false
            for c in sender.stringValue.characters {
                if c <= "8" && c >= "0" {
                    value = value * 8 + uint((String(c) as NSString).integerValue - ("0" as NSString).integerValue)
                } else {
                    error = true
                    break
                }
            }
            
            if !error {
                self.caculateValue[sender.tag] = value
            }
            
            break
        case "DEC":
            var newValue: Int64 = 0
            if scan.scanInt64(&newValue) {
                if newValue > Int64(UINT32_MAX) {
                    newValue = Int64(UINT32_MAX)
                }
                
                self.caculateValue[sender.tag] = value
            }
            break
        default:
            break
        }
        
        self.updateUI()
    }
    
    func singleOp(_ sender: NSButton) {
        var calculate = self.caculateValue[sender.tag]
        let b31Button = self.bitButtonArray[sender.tag][0]
        let b0Button = self.bitButtonArray[sender.tag][31]
        
        switch sender.title {
        case "<<":
            calculate = calculate << uint(1)
            break
        case ">>":
            calculate = calculate >> uint(1)
            break
        case "Shl":
            let bit0 = b31Button.state == NSOnState ? 1 : 0
            calculate = calculate << uint(1) | uint(bit0)
            break
        case "Shr":
            let bit31 = b0Button.state == NSOnState ? 1 : 0
            calculate = calculate >> uint(1) | uint(bit31) << 31
            break
        case "~":
            calculate = ~calculate
            break
        default:
            break
        }
        
        self.caculateValue[sender.tag] = calculate
        
        self.updateUI()
    }
    
    func dulOp(_ sender: NSButton) {
        switch sender.title {
        case "AND":
            self.caculateValue[0] &= self.caculateValue[1]
            break
        case "OR":
            self.caculateValue[0] |= self.caculateValue[1]
            break
        case "XOR":
            self.caculateValue[0] ^= self.caculateValue[1]
            break
        default:
            break
        }
        self.updateUI()
    }
    
    func createButtons(buttonArray: inout [NSButton], length: Int, label: String) {
        var num = length
        while num > 0 {
            let button = NSButton()
            
            button.title = String(num-1)
            button.action = #selector(bitButtonPress(_:))
            button.bezelStyle = NSRoundRectBezelStyle
            button.setButtonType(NSPushOnPushOffButton)
            button.isBordered = true
            button.tag = self.label2tag(label: label)
            
            buttonArray.append(button)
            num -= 1
        }
    }
    
    func buttonShow(buttonArray: [NSButton], start_point: CGPoint) {
        var num = 0
        for button in buttonArray {
            let buttonX = start_point.x + CGFloat(num + Int(num / 4)) * bitWith
            let buttonY = start_point.y
            button.frame = CGRect(x: buttonX, y: buttonY, width: bitWith, height: bitHeight)
            
            self.view.addSubview(button)
            num += 1
        }
    }
    
    func createLabel(startPoint: CGPoint, width: CGFloat, height: CGFloat, value: String) {
        let label = NSTextField()
        label.stringValue = value
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        let labelSize = CGSize(width: width, height: height)
        label.frame = CGRect(origin: startPoint, size: labelSize)
        self.view.addSubview(label)
    }
    
    func createTextField(startPoint: CGPoint, width: CGFloat, height: CGFloat, label: String, id: String) {
        let textField = NSTextField()
        textField.isEditable = true
        textField.usesSingleLineMode = true
        textField.alignment = NSTextAlignment.right
        textField.tag = self.label2tag(label: label)
        textField.identifier = id
        textField.action = #selector(textFieldEnter(_:))
        
        self.textFieldArray[textField.tag].append(textField)
        
        let textFieldSize = CGSize(width: width, height: height)
        textField.frame = CGRect(origin: startPoint, size: textFieldSize)
        self.view.addSubview(textField)
    }
    
    func createBitRow(startPoint: CGPoint, buttonArray: inout [NSButton], rowValue: String) {
        var drawPoint = startPoint
        
        createLabel(startPoint: drawPoint, width: 2 * bitWith, height: bitHeight, value: rowValue)
        
        drawPoint.x += 2 * bitWith
        createButtons(buttonArray: &buttonArray, length: 32, label: rowValue)
        buttonShow(buttonArray: buttonArray, start_point: drawPoint)
    }
    
    func createSigleOpButton(startPoint: CGPoint, width: CGFloat, height: CGFloat, value: String, label: String) {
        let button = NSButton()
        
        button.title = value
        button.action = #selector(singleOp(_:))
        button.bezelStyle = NSRoundRectBezelStyle
        //button.setButtonType(NSPushOnPushOffButton)
        button.isBordered = true
        button.tag = self.label2tag(label: label)
        let buttonSize = CGSize(width: width, height: height)
        button.frame = CGRect(origin: startPoint, size: buttonSize)
        self.view.addSubview(button)
    }
    
    func createDulOpButton(startPoint: CGPoint, width: CGFloat, height: CGFloat, value: String) {
        let button = NSButton()
        
        button.title = value
        button.action = #selector(dulOp(_:))
        button.bezelStyle = NSRoundRectBezelStyle
        //button.setButtonType(NSPushOnPushOffButton)
        button.isBordered = true
        let buttonSize = CGSize(width: width, height: height)
        button.frame = CGRect(origin: startPoint, size: buttonSize)
        self.view.addSubview(button)
    }
    
    func createSigleOpRow(startPoint: CGPoint, rowValue: String) {
        var drawPoint = startPoint
        
        createLabel(startPoint: drawPoint, width: 2 * bitWith, height: bitHeight, value: rowValue)
        
        drawPoint.x += 2 * bitWith
        for value in ["HEX", "OCT", "DEC"] {
            createLabel(startPoint: drawPoint, width: bitWith, height: bitHeight, value: value)
            
            drawPoint.x += bitWith
            createTextField(startPoint: drawPoint, width: 3 * bitWith, height: bitHeight, label: rowValue, id: value)
            drawPoint.x += 3 * bitWith
        }
        
        drawPoint.x += columnGap
        for value in ["<<", ">>", "Shl", "Shr", "~"] {
            createSigleOpButton(startPoint: drawPoint, width: 2 * bitWith, height: bitHeight, value: value, label: rowValue)
            drawPoint.x += 2 * bitWith + columnGap
        }
    }
    
    func createDulOpRow(startPoint: CGPoint) {
        var drawPoint = startPoint
        
        for value in ["AND", "OR", "XOR"] {
            createDulOpButton(startPoint: drawPoint, width: 2 * bitWith, height: bitHeight, value: value)
            drawPoint.x += 2 * bitWith + columnGap
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var drawPoint = CGPoint(x: leftMargin, y: self.view.frame.height - topMargin)
        createBitRow(startPoint: drawPoint, buttonArray: &self.bitButtonArray[0], rowValue: "Value 1")
        
        drawPoint.y -= bitHeight + rowGap
        createBitRow(startPoint: drawPoint, buttonArray: &self.bitButtonArray[1], rowValue: "Value 2")
        
        drawPoint.y -= bitHeight + rowGap
        createSigleOpRow(startPoint: drawPoint, rowValue: "Value 1")
        
        drawPoint.y -= bitHeight + rowGap
        createSigleOpRow(startPoint: drawPoint, rowValue: "Vaule 2")
        
        drawPoint.y -= bitHeight + rowGap
        createDulOpRow(startPoint: drawPoint)

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

