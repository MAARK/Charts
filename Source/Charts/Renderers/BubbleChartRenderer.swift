//
//  BubbleChartRenderer.swift
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

#if !os(OSX)
    import UIKit
#endif


open class BubbleChartRenderer: BarLineScatterCandleBubbleRenderer
{
    open weak var dataProvider: BubbleChartDataProvider?
    
    public init(dataProvider: BubbleChartDataProvider?, animator: Animator?, viewPortHandler: ViewPortHandler?)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    open override func drawData(context: CGContext)
    {
        guard
            let dataProvider = dataProvider,
            let bubbleData = dataProvider.bubbleData
            else { return }
        
        for set in bubbleData.dataSets as! [IBubbleChartDataSet]
        {
            if set.isVisible
            {
                drawDataSet(context: context, dataSet: set)
            }
        }
    }
    
    fileprivate func getShapeSize(
        entrySize: CGFloat,
        maxSize: CGFloat,
        reference: CGFloat,
        normalizeSize: Bool) -> CGFloat
    {
        let factor: CGFloat = normalizeSize
            ? ((maxSize == 0.0) ? 1.0 : sqrt(entrySize / maxSize))
            : entrySize
        let shapeSize: CGFloat = reference * factor
        return shapeSize
    }
    
    fileprivate var _pointBuffer = CGPoint()
    fileprivate var _sizeBuffer = [CGPoint](repeating: CGPoint(), count: 2)
    fileprivate var _indices: [Highlight] = []
    
    open func drawDataSet(context: CGContext, dataSet: IBubbleChartDataSet)
    {
        guard
            let dataProvider = dataProvider,
            let viewPortHandler = self.viewPortHandler,
            let bubbleData = dataProvider.bubbleData,
            let animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        
        _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        _sizeBuffer[0].x = 0.0
        _sizeBuffer[0].y = 0.0
        _sizeBuffer[1].x = 1.0
        _sizeBuffer[1].y = 0.0
        
        trans.pointValuesToPixel(&_sizeBuffer)
        
        context.saveGState()
        
        let normalizeSize = dataSet.isNormalizeSizeEnabled
        
        // calcualte the full width of 1 step on the x-axis
        let maxBubbleWidth: CGFloat = abs(_sizeBuffer[1].x - _sizeBuffer[0].x)
        let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
        let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
        
        for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
        {
            guard let entry = dataSet.entryForIndex(j) as? BubbleChartDataEntry else { continue }
            
            if let icon = entry.icon, dataSet.isDrawIconsEnabled { continue }
            
            _pointBuffer.x = CGFloat(entry.x)
            _pointBuffer.y = CGFloat(entry.y * phaseY)
            _pointBuffer = _pointBuffer.applying(valueToPixelMatrix)
            
            
            var shapeSize = getShapeSize(entrySize: entry.size, maxSize: dataSet.maxSize, reference: referenceSize, normalizeSize: normalizeSize)
            
            shapeSize = shapeSize / bubbleData.bubbleSizeMultiplier
            
            entry.shapeSize = shapeSize
            let shapeHalf = shapeSize / 2.0
            
            if !viewPortHandler.isInBoundsTop(_pointBuffer.y + shapeHalf)
                || !viewPortHandler.isInBoundsBottom(_pointBuffer.y - shapeHalf)
            {
                continue
            }
            
            if !viewPortHandler.isInBoundsLeft(_pointBuffer.x + shapeHalf)
            {
                continue
            }
            
            if !viewPortHandler.isInBoundsRight(_pointBuffer.x - shapeHalf)
            {
                break
            }
            
            var color = dataSet.color(atIndex: Int(entry.x))
            if let icon = entry.icon, dataSet.isDrawIconsEnabled
            {
                color = UIColor.clear
            }
            
            entry.yPx = _pointBuffer.y - shapeHalf
            entry.xPx = _pointBuffer.x - shapeHalf
            let rect = CGRect(
                x: _pointBuffer.x - shapeHalf,
                y: _pointBuffer.y - shapeHalf,
                width: shapeSize,
                height: shapeSize
            )
            
            
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect)
        }
        
        context.restoreGState()
    }
    
    open override func drawValues(context: CGContext)
    {
        guard let
            dataProvider = dataProvider,
            let viewPortHandler = self.viewPortHandler,
            let bubbleData = dataProvider.bubbleData,
            let animator = animator
            else { return }
        
        // if values are drawn
        if isDrawingValuesAllowed(dataProvider: dataProvider)
        {
            guard let dataSets = bubbleData.dataSets as? [BubbleChartDataSet] else { return }
            
            let phaseX = max(0.0, min(1.0, animator.phaseX))
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            var highlightPTx: CGFloat = 0
            var highlightPTy: CGFloat = 0
            var highlightIconOffset = CGPoint.zero
            var highlightMultiplier: CGFloat = 0
            var highlightEntry: BubbleChartDataEntry?
            var highlightDataSet: BubbleChartDataSet?
            
            for i in 0..<dataSets.count
            {
                let dataSet = dataSets[i]
                
                if !shouldDrawValues(forDataSet: dataSet)
                {
                    continue
                }
                
                let alpha = phaseX == 1 ? phaseY : phaseX
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
                
                let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let iconsOffset = dataSet.iconsOffset
                
                
                
                
                for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
                {
                    guard let e = dataSet.entryForIndex(j) as? BubbleChartDataEntry else { break }
                    
                    let valueTextColor = dataSet.valueTextColorAt(j).withAlphaComponent(CGFloat(alpha))
                    
                    pt.x = CGFloat(e.x)
                    pt.y = CGFloat(e.y * phaseY)
                    pt = pt.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(pt.x))
                    {
                        //continue
                    }
                    
                    if ((!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y)))
                    {
                        continue
                    }
                    
                    
                    let text = String(format: "%0.2f", e.size)
                    
                    // Larger font for larger bubbles?
                    let valueFont = dataSet.valueFont
                    let zoomedInFont = dataSet.zoomedInValueFont
                    let lineHeight = valueFont.lineHeight
                    
                    var highlighted = false
                    
                    for high in _indices
                    {
                        if let dataSet = bubbleData.getDataSetByIndex(high.dataSetIndex) as? IBubbleChartDataSet, dataSet.isHighlightEnabled == true {
                            if let entry = dataSet.entryForXValue(high.x, closestToY: high.y) as? BubbleChartDataEntry {
                                if entry == e { highlighted = true }
                            }
                        }
                    }
                    
                    
                    if let icon = e.icon, dataSet.isDrawIconsEnabled
                    {
                        if highlighted {
                            highlightPTx = pt.x
                            highlightPTy = pt.y
                            highlightIconOffset = iconsOffset
                            highlightMultiplier = dataSet.bubbleIconSizeMultiplier
                            highlightEntry = e
                            highlightDataSet = dataSet
                        } else {
                            var image = icon
                            if let highlightImage = e.highlightedIcon {
                                image = highlighted ? highlightImage : icon
                            }
                            
                            var updatedSize = CGSize(width: icon.size.width * dataSet.bubbleIconSizeMultiplier, height: icon.size.height * dataSet.bubbleIconSizeMultiplier)
                            
                            if viewPortHandler.scaleX > 1 {
                                updatedSize = CGSize(width: icon.size.width * viewPortHandler.scaleX * 1.2, height: icon.size.height * viewPortHandler.scaleY * 1.2)
                            }
                            ChartUtils.drawImage(context: context,
                                                 image: image,
                                                 x: pt.x + iconsOffset.x,
                                                 y: pt.y + iconsOffset.y,
                                                 size: updatedSize)
                        }
                    }
                    
                    
                    
                    if viewPortHandler.scaleX > dataSet.zoomThreshold && highlighted { continue }
                    
                    if dataSet.isDrawValuesEnabled
                    {
                        
                        let yCoord: CGFloat = viewPortHandler.scaleX > dataSet.zoomThreshold ? pt.y - (0.5 * lineHeight) - 15 : pt.y - (0.5 * lineHeight)
                        let font = viewPortHandler.scaleX > dataSet.zoomThreshold ? zoomedInFont : valueFont
                        
                        ChartUtils.drawText(
                            context: context,
                            text: text,
                            point: CGPoint(
                                x: pt.x,
                                y: yCoord),//pt.y - (0.5 * lineHeight)),
                            align: .center,
                            attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: valueTextColor])
                     
                        drawEntryLabel(context: context, dataSet: dataSet, e: e)
                    }
                }
            }
            
            // Draw the highlight above everything
            if let e = highlightEntry,
                let icon = e.icon,
                let dataSet = highlightDataSet
            {
                var image = icon
                if let highlightImage = e.highlightedIcon {
                    image = highlightImage
                }
                
                var updatedSize = CGSize(width: icon.size.width * highlightMultiplier, height: icon.size.height * highlightMultiplier)
                
                if viewPortHandler.scaleX > 1 {
                    updatedSize = CGSize(width: icon.size.width * viewPortHandler.scaleX * 1.2, height: icon.size.height * viewPortHandler.scaleY * 1.2)
                }
                
                ChartUtils.drawImage(context: context,
                                     image: image,
                                     x: highlightPTx + highlightIconOffset.x,
                                     y: highlightPTy + highlightIconOffset.y,
                                     size: updatedSize)
                
                drawEntryLabel(context: context, dataSet: dataSet, e: e)
            }
            
        }
    }
  
  
    open func drawEntryLabel(context: CGContext, dataSet: BubbleChartDataSet, e: BubbleChartDataEntry) {
        
        guard let
            dataProvider = dataProvider,
            let viewPortHandler = self.viewPortHandler,
            let bubbleData = dataProvider.bubbleData,
            let animator = animator
            else { return }
        
        if isDrawingValuesAllowed(dataProvider: dataProvider)
        {

            let phaseX = max(0.0, min(1.0, animator.phaseX))

            var pt = CGPoint()
            
            let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            
            let phaseY = animator.phaseY
            
            _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
            
            let valueToPixelMatrix = trans.valueToPixelMatrix
            
            _sizeBuffer[0].x = 0.0
            _sizeBuffer[0].y = 0.0
            _sizeBuffer[1].x = 1.0
            _sizeBuffer[1].y = 0.0
            
            trans.pointValuesToPixel(&_sizeBuffer)
            
            context.saveGState()
            
            let normalizeSize = dataSet.isNormalizeSizeEnabled
            
            // calcualte the full width of 1 step on the x-axis
            let maxBubbleWidth: CGFloat = abs(_sizeBuffer[1].x - _sizeBuffer[0].x)
            let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
            let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
            
            if !shouldDrawValues(forDataSet: dataSet) { return }
            
            let alpha = phaseX == 1 ? phaseY : phaseX
            
            guard let formatter = dataSet.valueFormatter else { return }
            
            _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
            
            let iconsOffset = dataSet.iconsOffset
            
            if e.showLabel {
                
                _pointBuffer.x = CGFloat(e.x)
                _pointBuffer.y = CGFloat(e.y * phaseY)
                _pointBuffer = _pointBuffer.applying(valueToPixelMatrix)
                
                var shapeSize = getShapeSize(entrySize: e.size, maxSize: dataSet.maxSize, reference: referenceSize, normalizeSize: normalizeSize)
                shapeSize = shapeSize / bubbleData.bubbleSizeMultiplier
                
                var shapeHalf = shapeSize / 2.0
                
                if let icon = e.icon {
                    shapeHalf = (icon.size.height / 2.0) * dataSet.bubbleIconSizeMultiplier
                }
                
                let width = e.label.size(attributes: [NSFontAttributeName: e.labelFont]).width
                
                pt.x = CGFloat(e.x)
                pt.y = CGFloat(e.y * phaseY)
                pt = pt.applying(valueToPixelMatrix)
                
                var moveLabelLeft = false
                var moveLabelRight = false
                if (!viewPortHandler.isInBoundsRight(pt.x + width))
                {
                    moveLabelLeft = true
                    
                }
                
                if ((!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y)))
                {
                    moveLabelRight = true
                }
                
                var labelFont = e.labelFont
                let lineHeight = labelFont.lineHeight
                
                var highlighted = false
                
                for high in _indices
                {
                    if let dataSet = bubbleData.getDataSetByIndex(high.dataSetIndex) as? IBubbleChartDataSet, dataSet.isHighlightEnabled == true {
                        if let entry = dataSet.entryForXValue(high.x, closestToY: high.y) as? BubbleChartDataEntry {
                            if entry == e { highlighted = true }
                        }
                    }
                }
                
                var modifier: CGFloat = e.isMultiline ? 16 : 10
                modifier = modifier * dataSet.bubbleIconSizeMultiplier
                
                var x: CGFloat =  pt.x
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                
                let totalLineHeight: CGFloat = e.isMultiline ? lineHeight * 2 : lineHeight
                
                if viewPortHandler.scaleX > dataSet.zoomThreshold && highlighted {
                    
                    let pe = String(format: "%.0f", e.x)
                    let percentage = String(format: "%.0f", e.y)
                    
                    ChartUtils.drawMultilineText(
                        context: context,
                        text: "P/E: \(pe)x\nGrowth: \(percentage)%",
                        point: CGPoint(x: x, y: pt.y),
                        attributes:[NSFontAttributeName: labelFont, NSForegroundColorAttributeName: UIColor.white, NSParagraphStyleAttributeName: paragraph],
                        constrainedToSize: CGSize(width: width * 2, height: labelFont.lineHeight * 2),
                        anchor: CGPoint(x: 0.5, y: 0.5),
                        angleRadians: 0.0)
                    
                    return
                }
                
                if viewPortHandler.scaleX > dataSet.zoomThreshold {
                    let labelColor = UIColor.white
                    var y: CGFloat = e.isMultiline ? pt.y + lineHeight + 2 : pt.y + lineHeight - 4
                    
                    let width = e.label.size(attributes: [NSFontAttributeName: labelFont]).width
                    
                    if width > 100 { labelFont = UIFont(name: labelFont.fontName, size: labelFont.pointSize - 2.5)! }
                    
                    ChartUtils.drawMultilineText(
                        context: context,
                        text: e.label,
                        point: CGPoint(x: x, y: y),
                        attributes:[NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelColor, NSParagraphStyleAttributeName: paragraph],
                        constrainedToSize: CGSize(width: width, height: totalLineHeight),
                        anchor: CGPoint(x: 0.5, y: 0.5),
                        angleRadians: 0.0)
                } else {
                    let labelColor = highlighted ? dataSet.highlightLabelColor : dataSet.color(atIndex: 0)
                    var y: CGFloat = pt.y + shapeHalf + modifier
                    ChartUtils.drawMultilineText(
                        context: context,
                        text: e.label,
                        point: CGPoint(x: x, y: y),
                        attributes:[NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelColor, NSParagraphStyleAttributeName: paragraph],
                        constrainedToSize: CGSize(width: width, height: totalLineHeight),
                        anchor: CGPoint(x: 0.5, y: 0.5),
                        angleRadians: 0.0)
                }
            }
            
        }
    }
    open override func drawExtras(context: CGContext)
    {
    }
    
    open override func drawHighlighted(context: CGContext, indices: [Highlight])
    {
        guard let
            dataProvider = dataProvider,
            let viewPortHandler = self.viewPortHandler,
            let bubbleData = dataProvider.bubbleData,
            let animator = animator
            else { return }
        
        context.saveGState()
        
        _indices = indices
        
        let phaseY = animator.phaseY
        
        for high in indices
        {
            guard
                let dataSet = bubbleData.getDataSetByIndex(high.dataSetIndex) as? IBubbleChartDataSet,
                dataSet.isHighlightEnabled
                else { continue }
            
            guard let entry = dataSet.entryForXValue(high.x, closestToY: high.y) as? BubbleChartDataEntry else { continue }
            
            if !isInBoundsX(entry: entry, dataSet: dataSet) { continue }
            
            let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            
            _sizeBuffer[0].x = 0.0
            _sizeBuffer[0].y = 0.0
            _sizeBuffer[1].x = 1.0
            _sizeBuffer[1].y = 0.0
            
            trans.pointValuesToPixel(&_sizeBuffer)
            
            let normalizeSize = dataSet.isNormalizeSizeEnabled
            
            // calcualte the full width of 1 step on the x-axis
            let maxBubbleWidth: CGFloat = abs(_sizeBuffer[1].x - _sizeBuffer[0].x)
            let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
            let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
            
            _pointBuffer.x = CGFloat(entry.x)
            _pointBuffer.y = CGFloat(entry.y * phaseY)
            trans.pointValueToPixel(&_pointBuffer)
            
            let shapeSize = getShapeSize(entrySize: entry.size, maxSize: dataSet.maxSize, reference: referenceSize, normalizeSize: normalizeSize)
            let shapeHalf = shapeSize / 2.0
            
            if !viewPortHandler.isInBoundsTop(_pointBuffer.y + shapeHalf) ||
                !viewPortHandler.isInBoundsBottom(_pointBuffer.y - shapeHalf)
            {
                continue
            }
            
            if !viewPortHandler.isInBoundsLeft(_pointBuffer.x + shapeHalf)
            {
                continue
            }
            
            if !viewPortHandler.isInBoundsRight(_pointBuffer.x - shapeHalf)
            {
                break
            }
            
            let originalColor = dataSet.color(atIndex: Int(entry.x))
            
            var h: CGFloat = 0.0
            var s: CGFloat = 0.0
            var b: CGFloat = 0.0
            var a: CGFloat = 0.0
            
            originalColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            
            let color = NSUIColor(hue: h, saturation: s, brightness: b * 0.5, alpha: a)
            let rect = CGRect(
                x: _pointBuffer.x - shapeHalf,
                y: _pointBuffer.y - shapeHalf,
                width: shapeSize,
                height: shapeSize)
            
            context.setLineWidth(dataSet.highlightCircleWidth)
            context.setStrokeColor(color.cgColor)
            context.strokeEllipse(in: rect)
            
            high.setDraw(x: _pointBuffer.x, y: _pointBuffer.y)
        }
        
        context.restoreGState()
    }
}
