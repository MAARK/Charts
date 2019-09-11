//
//  ChartCallout.swift
//  Charts
//
//  Created by Ryan VanAlstine on 6/26/16.
//  Copyright © 2016 Maark. All rights reserved.
//

import UIKit

@objc(ChartCallout)
open class Callout: NSObject {
    
    /// The callout image to render
    open var image: NSUIImage?
    
    /// The callout tag
    open var tag: Int = 0
    
    /// Use this to set the desired point on the chart canvas
    open var position: CGPoint = CGPoint()
    
    //open var currentPosition: CGPoint = CGPoint()
    
    /// Use this to return the desired offset you wish the Callout to have on the x-axis.
    open var offset: CGPoint = CGPoint()
    
    // This is the value that the callout has on the chart grid.  Its used to handle zoom and panning
    open var valuePoint: CGPoint = CGPoint()
    
    /// The callout's size
    open var size: CGSize
        {
        get
        {
            return image?.size ?? .zero
        }
    }
    
    /// The rect of the callout
    open var rect: CGRect!
    
    public override init()
    {
        super.init()
    }
    
    /// Returns the offset for drawing at the specific `point`
    ///
    /// - parameter point: This is the point at which the marker wants to be drawn. You can adjust the offset conditionally based on this argument.
    /// - By default returns the self.offset property. You can return any other value to override that.
    open func offsetForDrawingAtPos(point: CGPoint) -> CGPoint
    {
        return offset
    }
    
    /// Draws the Callout on the given position on the given context
    open func draw(context: CGContext, point: CGPoint)
    {
        if image == nil
        {
            return
        }
        
        let offset = self.offsetForDrawingAtPos(point: point)
        let size = self.size
        
        rect = CGRect(x: point.x + offset.x, y: point.y + offset.y, width: size.width, height: size.height)
        
        NSUIGraphicsPushContext(context)
        image!.draw(in: rect)
        NSUIGraphicsPopContext()
        
    }
    
    /// This method enables a custom Callout to update it's content everytime the CalloutView is redrawn according to the data entry it points to.
    ///
    /// - parameter highlight: the highlight object contains information about the highlighted value such as it's dataset-index, the selected range or stack-index (only stacked bar entries).
    open func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        // Do nothing here...
    }
    
}
