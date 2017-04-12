//
//  ChartDiagonalLine.swift
//  Pods
//
//  Created by Ryan VanAlstine on 4/12/17.
//
//

import Foundation
import CoreGraphics

open class ChartDiagonalLine: ComponentBase
{
    
    open var startY = Double(0.0)
    open var endY = Double(0.0)
    open var startX = Double(0.0)
    open var endX = Double(0.0)
    
    fileprivate var _lineWidth = CGFloat(2.0)
    open var lineColor = NSUIColor(red: 237.0/255.0, green: 91.0/255.0, blue: 91.0/255.0, alpha: 1.0)
    open var lineDashPhase = CGFloat(0.0)
    open var lineDashLengths: [CGFloat]?
    
    public override init()
    {
        super.init()
    }
    
    public init(startX: Double, endX: Double, startY: Double, endY: Double)
    {
        super.init()
        self.startY = startY
        self.endY = endY
        self.startX = startX
        self.endX = endX
    }
    
    /// set the line width of the chart (min = 0.2, max = 12); default 2
    open var lineWidth: CGFloat
        {
        get
        {
            return _lineWidth
        }
        set
        {
            if newValue < 0.2
            {
                _lineWidth = 0.2
            }
            else if newValue > 12.0
            {
                _lineWidth = 12.0
            }
            else
            {
                _lineWidth = newValue
            }
        }
    }
    
}
