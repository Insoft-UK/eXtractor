/*
 Copyright © 2022 Insoft. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#if os(iOS) || os(tvOS)
import UIKit
import MobileCoreServices // before iOS 14
#else
import Cocoa
#endif
import CoreGraphics
import Foundation
import UniformTypeIdentifiers

#if os(macOS)
extension NSApplication {
    static var rootViewController: NSViewController? {
        return NSApplication.shared.windows.first?.contentViewController
    }
}
#else
extension UIApplication {
    static var rootViewController: UIViewController? {
        if #available(iOS 15, *) {
            // WTF! Apple
            return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
            
        } else {
            return UIApplication.shared.windows.first?.rootViewController
        }
    }
}
#endif

extension URL {
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

extension String {
    static let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
}

extension CGSize {
    static var screen: CGSize {
#if os(macOS)
        return NSScreen.main?.frame.size ?? .zero
#else
        return UIScreen.main.bounds.size
#endif
    }
    
    static var nativeScreen: CGSize {
#if os(macOS)
        return NSScreen.main?.frame.size ?? .zero
#else
        return UIScreen.main.nativeBounds.size
#endif
    }
}

extension CGPoint {
    static var center: CGPoint {
        return CGPoint(x: CGSize.screen.width / 2, y: CGSize.screen.height / 2)
    }
}

extension CGFloat {
#if os(macOS)
    static let scale = NSScreen.main?.backingScaleFactor
#else
    static let scale = UIScreen.main.scale
    static let nativeScale = UIScreen.main.nativeScale
#endif
    
    static var width: CGFloat {
        return CGSize.screen.width
    }
#if !os(macOS)
    static var nativeWidth: CGFloat {
        return UIScreen.main.nativeBounds.size.width
    }
#endif
    static var height: CGFloat {
        return CGSize.screen.height
    }
#if !os(macOS)
    static var nativeHight: CGFloat {
        return UIScreen.main.nativeBounds.size.height
    }
#endif
    static let margin = 18.0
#if os(macOS)
    static let scaleFactor = 1.5 * (NSScreen.main?.backingScaleFactor ?? 1.0)
#else
    static let scaleFactor = UIDevice.current.userInterfaceIdiom == .pad ? 1.5 * UIScreen.main.scale : UIScreen.main.scale
#endif
    static func degrees(_ angle: CGFloat) -> CGFloat {
        return angle * .pi/180
    }
}

extension Bool {
    static var isPad: Bool {
#if os(macOS)
        return false
#else
        return UIDevice.current.userInterfaceIdiom == .pad ? true : false
#endif
    }
    
    static var isMac: Bool {
#if os(macOS)
        return true
#else
        return false
#endif
    }
}

extension CGContext {
    
    /// Transforms the user coordinate system in a context
    /// such that the y-axis is flipped.
    func flipVertical() {
        concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: CGFloat(height)/abs(userSpaceToDeviceSpaceTransform.d)))
    }
}

// CGImage has no scale property, the @2x or @3x suffix will be ignored.
extension CGImage {
    static func create(fromPixelData pixelData: UnsafePointer<UInt8>, ofSize size: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let provider = CGDataProvider(data: CFDataCreate(nil, pixelData, Int(size.width) * Int(size.height) * 4)) {
            CGImageSourceCreateWithDataProvider(provider, nil)
            
            let cgImage = CGImage(
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: Int(8),
                bitsPerPixel: Int(32),
                bytesPerRow: Int(size.width) * Int(4),
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: CGColorRenderingIntent.defaultIntent
            )
            
            return cgImage
        }
        return nil
    }
    
    @discardableResult func write(to destinationURL: URL) -> Bool {
        if #available(iOS 14.0, *) {
            guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { return false }
            CGImageDestinationAddImage(destination, self, nil)
            return CGImageDestinationFinalize(destination)
        } else {
            guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else { return false }
            CGImageDestinationAddImage(destination, self, nil)
            return CGImageDestinationFinalize(destination)
        }
    }
    
    func resize(_ size: CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)
        
        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel
        
        
        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }
        
        context.interpolationQuality = .none
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
        
    }
}

#if !os(macOS)
extension UIImage {
    static func tiled(fromImage image: UIImage, ofSize size: CGSize) -> UIImage? {
        let textureSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        UIGraphicsBeginImageContext(size)
        if let context = UIGraphicsGetCurrentContext()
        {
            context.flipVertical()
            context.draw(image.cgImage!, in: textureSize, byTiling: true)
            if let uiImage = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                return uiImage
            }
        }
        UIGraphicsEndImageContext()
        
        return nil
    }
}
#endif

#if os(macOS)
extension NSImage {
    @discardableResult static func create(fromCGImage cgImage: CGImage) -> NSImage? {
        return NSImage(cgImage: cgImage, size: .zero)
    }
}
#endif

@objc class Extenions : NSObject {
    @objc @discardableResult class func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
        return image.write(to: destinationURL)
    }
    
    @objc class func createCGImage(fromPixelData pixelData:UnsafePointer<UInt8>, ofSize size:CGSize) -> CGImage? {
        return CGImage.create(fromPixelData: pixelData, ofSize: size)
    }
    
    
    @objc class func createNSImage(fromCGImage cgImage: CGImage) -> NSImage? {
        return NSImage.create(fromCGImage: cgImage)
    }
    
    @objc class func resizeCGImage(_ image: CGImage, toSize size: CGSize) -> CGImage? {
        return image.resize(size)
    }
#if !os(macOS)
    @objc class func tiledUIImage(fromImage image : UIImage, ofSize size:CGSize) -> UIImage? {
        return UIImage.tiled(fromImage: image, ofSize: size)
    }
#endif

    @objc class func screen() -> CGSize {
        return .screen
    }
    
    @objc class func center() -> CGPoint {
        return .center
    }
    
    @objc class func bundleVersion() -> String {
        return String.bundleVersion
    }
}
