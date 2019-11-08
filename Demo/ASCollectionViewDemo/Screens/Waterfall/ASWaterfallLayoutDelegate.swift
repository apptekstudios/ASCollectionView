//
//  ASWaterfallLayout.swift
//  ASCollectionViewDemo
//
//  Created by Toby Brennan on 8/11/19.
//  Copyright © 2019 Apptek Studios. All rights reserved.
//

import Foundation
import UIKit
import ASCollectionView

protocol ASWaterfallLayoutDelegate {
	func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat
}
