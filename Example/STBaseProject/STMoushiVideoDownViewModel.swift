//
//  STMoushiVideoDownViewModel.swift
//  STBaseProject_Example
//
//  Created by song on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import UIKit

class STMoushiVideoDownViewModel: NSObject {
    
    private var dataSources:[STMoushiVideoDownModel] = [STMoushiVideoDownModel]()
    
    func cellDateSources() -> [STMoushiVideoDownModel] {
        return dataSources
    }
    
    func cellForRow(indexPath: IndexPath) -> STMoushiVideoDownModel {
        if dataSources.count > indexPath.row {
            return dataSources[indexPath.row]
        }
        return STMoushiVideoDownModel()
    }
    
    func loadData(complection: @escaping(Bool) -> Void) {
        dataSources.removeAll()
        var model = STMoushiVideoDownModel()
        model.title = "本地商家运营师"
        model.nibName = "STLocalBusinessOperatorViewController"
        model.className = model.nibName
        dataSources.append(model)
        DispatchQueue.main.async {
            complection(true)
        }
    }
}
