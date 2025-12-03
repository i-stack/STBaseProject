//
//  ViewControllerViewModel.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import UIKit

class ViewControllerViewModel: NSObject {

    private var dataSources:[ViewControllerModel] = [ViewControllerModel]()
    
    func cellDateSources() -> [ViewControllerModel] {
        return dataSources
    }
    
    func cellForRow(indexPath: IndexPath) -> ViewControllerModel {
        if dataSources.count > indexPath.row {
            return dataSources[indexPath.row]
        }
        return ViewControllerModel()
    }
    
    func loadData(complection: @escaping(Bool) -> Void) {
        dataSources.removeAll()
        var model = ViewControllerModel()
        model.title = Bundle.st_localizedString(key: "test1")
        model.nibName = "STNextViewController"
        model.className = model.nibName
        dataSources.append(model)
        DispatchQueue.main.async {
            complection(true)
        }
    }
}
