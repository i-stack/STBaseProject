//
//  STContractManager.swift
//  STBaseProject
//
//  Created by song on 2018/7/24.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit
import Contacts

class STContractManager: NSObject {
    
    var localizedCollection: UILocalizedIndexedCollation!
    
    override init() {
        super.init()
        localizedCollection = UILocalizedIndexedCollation.current()
    }
    
    /**
     *  获取联系人
     */
    func loadContactsData(complection: @escaping(Result<[STContractMessage], Error>) -> Void) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized {
            let contractData = self.beginLoadContractData()
            DispatchQueue.main.async {
                complection(.success(contractData))
            }
        } else if status == .notDetermined {
            CNContactStore().requestAccess(for: .contacts) { (result, error) in
                if result == true {
                    let contractData = self.beginLoadContractData()
                    DispatchQueue.main.async {
                        complection(.success(contractData))
                    }
                } else {
                    self.authorizationFailed()
                    DispatchQueue.main.async {
                        complection(.failure(NSError.init(domain: "authorization Failed", code: 0, userInfo: [:])))
                    }
                }
            }
        } else {
            self.authorizationFailed()
            DispatchQueue.main.async {
                complection(.failure(NSError.init(domain: "authorization Failed", code: 0, userInfo: [:])))
            }
        }
    }
  
    /**
     *  获取分组联系人
     */
    func loadSortContactsData(complection: @escaping(Result<([[STContractMessage]], [String]), Error>) -> Void) {
        self.loadContactsData { (result) in
            switch result {
            case .success(let contractData):
                let sortContractData = self.sortContract(contractData: contractData)
                DispatchQueue.main.async {
                    complection(.success(sortContractData))
                }
                break
            case .failure(_):
                DispatchQueue.main.async {
                    complection(.failure(NSError.init(domain: "load sort contacts data failure", code: 0, userInfo: [:])))
                }
                break
            }
        }
    }
    
    private func beginLoadContractData() -> [STContractMessage] {
        
        var contractList: [STContractMessage] = [STContractMessage]()
        
        let store = CNContactStore()
        let keys = [CNContactNoteKey,
                    CNContactDatesKey,
                    CNContactNicknameKey,
                    CNContactJobTitleKey,
                    CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactPhoneNumbersKey,
                    CNContactDepartmentNameKey,
                    CNContactEmailAddressesKey,
                    CNContactPostalAddressesKey,
                    CNContactOrganizationNameKey,
                    CNContactInstantMessageAddressesKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        do {
            try store.enumerateContacts(with: request, usingBlock: {
                (contact : CNContact, stop : UnsafeMutablePointer<ObjCBool>) -> Void in
                
                let contractMessage: STContractMessage = STContractMessage()
                
                let lastName = contact.familyName
                let firstName = contact.givenName
                contractMessage.contractName = lastName + firstName
                
                contractMessage.note = contact.note
                contractMessage.jobTitle = contact.jobTitle
                contractMessage.nickName = contact.nickname
                contractMessage.department = contact.departmentName
                contractMessage.organization = contact.organizationName
                
                for phone in contact.phoneNumbers {
                    var label = "未知标签"
                    if phone.label != nil {
                        label = CNLabeledValue<NSString>.localizedString(forLabel:
                            phone.label!)
                    }
                    let value = phone.value.stringValue
                    contractMessage.phone = label + ":" + value
                }
                
                for email in contact.emailAddresses {
                    var label = "未知标签"
                    if email.label != nil {
                        label = CNLabeledValue<NSString>.localizedString(forLabel:
                            email.label!)
                    }
                    
                    let value = email.value
                    contractMessage.email = label + ":" + String(value)
                }
                
                for address in contact.postalAddresses {
                    var label = "未知标签"
                    if address.label != nil {
                        label = CNLabeledValue<NSString>.localizedString(forLabel:
                            address.label!)
                    }
                    
                    let detail = address.value
                    let contry = detail.value(forKey: CNPostalAddressCountryKey) ?? ""
                    let state = detail.value(forKey: CNPostalAddressStateKey) ?? ""
                    let city = detail.value(forKey: CNPostalAddressCityKey) ?? ""
                    let street = detail.value(forKey: CNPostalAddressStreetKey) ?? ""
                    let code = detail.value(forKey: CNPostalAddressPostalCodeKey) ?? ""
                    let str = "国家:\(contry) 省:\(state) 城市:\(city) 街道:\(street)"
                        + " 邮编:\(code)"
                    contractMessage.address = label + ":" + str
                }
                
                for date in contact.dates {
                    var label = "未知标签"
                    if date.label != nil {
                        label = CNLabeledValue<NSString>.localizedString(forLabel:
                            date.label!)
                    }
                    
                    let dateComponents = date.value as DateComponents
                    let value = NSCalendar.current.date(from: dateComponents)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
                    contractMessage.birthday = label + ":" + dateFormatter.string(from: value!)
                }
                
                for im in contact.instantMessageAddresses {
                    var label = "未知标签"
                    if im.label != nil {
                        label = CNLabeledValue<NSString>.localizedString(forLabel:
                            im.label!)
                    }
                    let detail = im.value
                    let username: String = (detail.value(forKey: CNInstantMessageAddressUsernameKey)
                        ?? "") as! String
                    let service: String = (detail.value(forKey: CNInstantMessageAddressServiceKey)
                        ?? "") as! String
                    contractMessage.service = label + ":" + username + "服务:" + service
                }
                contractList.append(contractMessage)
            })
        } catch (let error) {
            let alert: UIAlertController = UIAlertController.init(title: "", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
            let action: UIAlertAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.cancel) { (action) in}
            alert.addAction(action)
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {})
        }
        return contractList
    }

    func sortContract(contractData: [STContractMessage]) -> ([[STContractMessage]], [String]) {
        var sectionTitleArray: [String] = [String]()
        var dataArray: [[STContractMessage]] = [[STContractMessage]]()
        if contractData.count > 0 {
            let sectionTitlesCount = localizedCollection.sectionTitles.count
            for _ in 0...sectionTitlesCount - 1 {
                let array: [STContractMessage] = [STContractMessage]()
                dataArray.append(array)
            }
            
            var sectionNames: [STContractMessage] = [STContractMessage]()
            for contractModel in contractData {
                let contractMessage: STContractMessage = contractModel
                sectionNames.append(contractMessage)
            }
            
            for model in sectionNames {
                let contractModel: STContractMessage = model
                let sectionNumber: Int = localizedCollection.section(for: contractModel, collationStringSelector: #selector(getter: STContractMessage.name))
                dataArray[sectionNumber].append(contractModel)
            }
            
            for i in 0...sectionTitlesCount - 1 {
                let sortedPersonArray = localizedCollection.sortedArray(from: dataArray[i], collationStringSelector: #selector(getter: STContractMessage.name))
                dataArray[i] = sortedPersonArray as! [STContractMessage]
            }
            
            var tempArray = [Int]()
            for (i, array) in dataArray.enumerated() {
                if array.count == 0 {
                    tempArray.append(i)
                } else {
                    sectionTitleArray.append(localizedCollection.sectionTitles[i])
                }
            }
            
            for i in tempArray.reversed() {
                dataArray.remove(at: i)
            }
        }
        return (dataArray, sectionTitleArray)
    }
    
    func authorizationFailed() -> Void {
        let alert: UIAlertController = UIAlertController.init(title: "温馨提示", message: "请在iPhone的“设置-隐私-通讯录”选项中，允许访问您的通讯录", preferredStyle: UIAlertController.Style.alert)
        let action: UIAlertAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.cancel) { (action) in}
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {})
    }
}
