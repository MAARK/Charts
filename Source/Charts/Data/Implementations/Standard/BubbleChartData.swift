//
//  BubbleChartData.swift
//  Charts
//
//  Bubble chart implementation:
//    Copyright 2015 Pierre-Marc Airoldi
//    Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

open class BubbleChartData: BarLineScatterCandleBubbleChartData
{
    // Maark addition
    open var maxSize: CGFloat = 0.0
    open var bubbleSizeMultiplier: CGFloat = 1.0
  
    public override init()
    {
        super.init()
    }
    
    public override init(dataSets: [IChartDataSet]?)
    {
        super.init(dataSets: dataSets)
    }
    
    /// Sets the width of the circle that surrounds the bubble when highlighted for all DataSet objects this data object contains
    open func setHighlightCircleWidth(_ width: CGFloat)
    {
        for set in (_dataSets as? [IBubbleChartDataSet])!
        {
            set.highlightCircleWidth = width
        }
    }
}
