/*
Copyright © 2021 Insoft. All rights reserved.

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


import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    //private var image: Image?
    
    @IBOutlet weak var mainMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        //image = Singleton.sharedInstance()?.image
        updateAllMenus()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func application(sender: NSApplication, openFile theDroppedFilePath: String) {
        // PROCESS YOUR FILES HERE
        
        if let url = URL(string: theDroppedFilePath) {
            Singleton.sharedInstance()?.image.modify(withContentsOf: url)
            NSApp.windows.first?.title = url.lastPathComponent
            Singleton.sharedInstance()?.mainScene.checkForKnownFormats()
            
        }
        updateAllMenus()
    }
    
    
    
    // MARK: - Private Action Methods
    
    @IBAction private func zoomIn(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            if image.yScale < 8.0 {
                image.setScale(image.yScale + 1.0)
                image.xScale = image.yScale * image.aspectRatio
            }
        }
    }
    
    @IBAction private func zoomOut(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            if image.yScale > 1.0 {
                image.setScale(image.yScale - 1.0)
                image.xScale = image.yScale * image.aspectRatio
            }
        }
    }
    
    @IBAction private func firstPalette(_ sender: NSMenuItem) {
        Singleton.sharedInstance()?.image.firstAtariSTPalette()
    }
    
    @IBAction private func nextPalette(_ sender: NSMenuItem) {
        Singleton.sharedInstance()?.image.nextAtariSTPalette()
    }
    
    @IBAction private func planeCount(_ sender: NSMenuItem) {
        Singleton.sharedInstance()?.image.setPlaneCount(UInt32(sender.tag))
        updateAllMenus()
    }
    
    @IBAction private func bitsPerPlane(_ sender: NSMenuItem) {
        Singleton.sharedInstance()?.image.setBitsPerPixel(UInt32(sender.tag))
        updateAllMenus()
    }
    
    
    @IBAction private func gridPresets(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            switch sender.tag {
            case 8:
                image.setTileWithWidthOf(8, andHightOf: 8)
            default:
                image.setTileWithWidthOf(1, andHightOf: 1)
            }
        }
        updateAllMenus()
    }
    
    @IBAction private func platform(_ sender: NSMenuItem) {
        // NOTE: bitsPerPixel is regarded as bitsPerPlane = (8 or 16) when planeCount is greater than 1!
        
        if let image = Singleton.sharedInstance()?.image {
            switch sender.tag {
            case 0: // ZX Spectrum
                image.setPlaneCount(1)
                image.setBitsPerPixel(1)
                image.setSize(CGSize(width: 256, height: 192))
                image.setTileWithWidthOf(1, andHightOf: 1)
                if let palette = Singleton.sharedInstance()?.image.palette {
                    if let filePath = Bundle.main.path(forResource: "ZX Spectrum", ofType: "act") {
                        palette.load(withContentsOfFile: filePath)
                    }
                }
                image.alphaPlane = false
                image.setAspectRatio(1.0)
                
            case 8:
                image.setPlaneCount(1)
                image.setBitsPerPixel(8)
                image.setSize(CGSize(width: 256, height: 192))
                image.setTileWithWidthOf(1, andHightOf: 1)
                if let palette = Singleton.sharedInstance()?.image.palette {
                    if let filePath = Bundle.main.path(forResource: "ZX Spectrum NEXT", ofType: "act") {
                        palette.load(withContentsOfFile: filePath)
                    }
                }
                image.alphaPlane = false
                image.setAspectRatio(1.0)
                
            case 1: // Atari ST Low Resolution
                image.setPlaneCount(4)
                image.setBitsPerPixel(16)
                image.setSize(CGSize(width: 320, height: 200))
                image.setTileWithWidthOf(1, andHightOf: 1)
                if let palette = Singleton.sharedInstance()?.image.palette {
                    if let filePath = Bundle.main.path(forResource: "Atari STE GEM Desktop", ofType: "act") {
                        palette.load(withContentsOfFile: filePath)
                    }
                }
                image.alphaPlane = false
                image.setAspectRatio(1.0)
                
            case 2: // Atari ST Medium Resolution
                image.setPlaneCount(2)
                image.setBitsPerPixel(16)
                image.setSize(CGSize(width: 640, height: 200))
                image.setTileWithWidthOf(1, andHightOf: 1)
                if let palette = Singleton.sharedInstance()?.image.palette {
                    if let filePath = Bundle.main.path(forResource: "Atari STE GEM Desktop", ofType: "act") {
                        palette.load(withContentsOfFile: filePath)
                    }
                    palette.setColorCount(4)
                }
                image.alphaPlane = false
                image.setAspectRatio(0.5)
                
            case 3: // Atari ST High Resolution
                image.setPlaneCount(1)
                image.setBitsPerPixel(1)
                image.setSize(CGSize(width: 640, height: 400))
                image.setTileWithWidthOf(1, andHightOf: 1)
                if let palette = Singleton.sharedInstance()?.image.palette {
                    if let filePath = Bundle.main.path(forResource: "Atari STE GEM Desktop", ofType: "act") {
                        palette.load(withContentsOfFile: filePath)
                    }
                    palette.setColorCount(2)
                }
                image.alphaPlane = false
                image.setAspectRatio(1.0)
                
            case 16:
                image.setPlaneCount(1)
                image.setBitsPerPixel(16)
                image.setSize(CGSize(width: 92, height: 64))
                image.setTileWithWidthOf(1, andHightOf: 1)
                
                image.alphaPlane = false
                image.pixelFormat = .RGB565
                image.bigEndian = true
                image.setAspectRatio(1.0)
                
            default: break
            }
        }
        
        updateAllMenus()
    }
    
    @IBAction private func loadPalette(_ sender: NSMenuItem) {
        if let palette = Singleton.sharedInstance()?.image.palette {
            if let filePath = Bundle.main.path(forResource: sender.title, ofType: "act") {
                palette.load(withContentsOfFile: filePath)
                return
            }
            if let filePath = Bundle.main.path(forResource: sender.title, ofType: "npl") {
                palette.load(withContentsOfFile: filePath)
                return
            }
        }
    }
    
    @IBAction private func aspectRatio(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            if sender.title == "1:1" {
                image.setAspectRatio(1.0)
            }
            if sender.title == "2:1" {
                image.setAspectRatio(2.0)
            }
            if sender.title == "1:2" {
                image.setAspectRatio(0.5)
            }
        }
        updateAllMenus();
    }
    
    @IBAction private func pageUp(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.setOffset(image.offset - image.bytesPerLine * Int(image.size.height))
        }
    }
    
    @IBAction private func pageDown(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.setOffset(image.offset + image.bytesPerLine * Int(image.size.height))
        }
    }
    
    @IBAction private func increaseWidth(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            var size = image.size
            size.width += CGFloat(image.deltaWidth())
            image.setSize(size)
        }
        updateAllMenus()
    }
    
    @IBAction private func decreaseWidth(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            var size = image.size;
            size.width -= CGFloat(image.deltaWidth());
            image.setSize(size)
        }
        updateAllMenus()
    }
    
    
    @IBAction private func increaseHeight(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            var size = image.size;
            size.height += CGFloat(image.tileHeight)
            image.setSize(size)
        }
        updateAllMenus()
    }
    
    
    @IBAction private func decreaseHeight(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            var size = image.size;
            size.height -= CGFloat(image.tileHeight)
            image.setSize(size)
        }
        updateAllMenus()
    }
    
    @IBAction private func padding(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.setPadding(Int(sender.tag))
        }
        updateAllMenus()
    }
    
    
    @IBAction private func openDocument(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        
        openPanel.title = "eXtractor"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        
        let modalresponse = openPanel.runModal()
        if modalresponse == .OK {
            if let url = openPanel.url {
                Singleton.sharedInstance()?.image.modify(withContentsOf: url)
                NSApp.windows.first?.title = url.lastPathComponent
                Singleton.sharedInstance()?.mainScene.checkForKnownFormats()
                
            }
        }
        
        updateAllMenus()
    }
    
    @IBAction private func importPalette(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        
        openPanel.title = "eXtractor"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        
        let modalresponse = openPanel.runModal()
        if modalresponse == .OK {
            if let url = openPanel.url {
                Singleton.sharedInstance()?.image.palette.load(withContentsOfFile: url.path)
            }
        }
    }
    
    @IBAction private func saveAs(_ sender: NSMenuItem) {
        let savePanel = NSSavePanel()
        
        savePanel.title = "eXtractor"
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(NSApp.windows.first?.title ?? "name").png"
        
        let modalresponse = savePanel.runModal()
        if modalresponse == .OK {
            if let url = savePanel.url {
                Singleton.sharedInstance()?.image.save(at: url)
            }
        }
    }
    
    @IBAction private func exportPalette(_ sender: NSMenuItem) {
        let savePanel = NSSavePanel()
        
        savePanel.title = "eXtractor"
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(NSApp.windows.first?.title ?? "name").act"
        
        let modalresponse = savePanel.runModal()
        if modalresponse == .OK {
            if let url = savePanel.url {
                Singleton.sharedInstance()?.image.palette.saveAsPhotoshopAct(atPath: url.path)
            }
        }
    }
    
    @IBAction private func imageWidth(_ sender: NSMenuItem) {
        Singleton.sharedInstance()?.image.setSize(CGSize(width: CGFloat(sender.tag), height: (Singleton.sharedInstance()?.image.size.height)!))
        updateAllMenus()
    }
    
    @IBAction private func imageHeight(_ sender: NSMenuItem) {
        Singleton.sharedInstance()?.image.setSize(CGSize(width: (Singleton.sharedInstance()?.image.size.width)!, height: CGFloat(sender.tag)))
        updateAllMenus()
    }
    
    @IBAction private func pixelArrangement(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            switch sender.tag {
            case 0: // Packed
                image.setPlaneCount(1)
                image.setBitsPerPixel(1)
                
            case 1: // Planar
                image.setPlaneCount(2)
                
                if let menu = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Planes")?.submenu {
                    if menu.item(withTag: 8)?.state == .on {
                        image.setBitsPerPixel(8) // bitsPerPlane!
                    } else {
                        image.setBitsPerPixel(16) // bitsPerPlane!
                    }
                }
            default:
                break
            }
        }
        
        updateAllMenus()
    }
    
    @IBAction func pixelFormat(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {

            switch sender.tag {
            case 555:
                image.pixelFormat = .RGB555
                
            case 565:
                image.pixelFormat = .RGB565
                
            case 5551:
                image.pixelFormat = .RGBA555
                
            case 1555:
                image.pixelFormat = .ARGB555

            default:
                image.pixelFormat = .RGB555
            }
            
        }
        updateAllMenus()
    }
    
    @IBAction func colors(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.setPlaneCount(1)
            image.setBitsPerPixel(UInt32(sender.tag))
            updateAllMenus()
        }
    }
    
    // NOTE: alphaPlane is also alphaChannel when in packed image mode.
    @IBAction func alphaPlane(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.alphaPlane = !image.alphaPlane
            if image.alphaPlane == true {
                image.maskPlane = false
            }
        }
        updateAllMenus()
    }
    
    // NOTE: maskPlane is also alphaChannel when in packed image mode.
    @IBAction func maskPlane(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.maskPlane = !image.maskPlane
            if image.maskPlane == true {
                image.alphaPlane = false
            }
        }
        updateAllMenus()
    }
    
    
    
    @IBAction private func tileWidth(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.setTileWithWidthOf(UInt(sender.tag), andHightOf: image.tileHeight)
        }
        updateAllMenus()
    }
    
    @IBAction private func tileHeight(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.setTileWithWidthOf(image.tileWidth, andHightOf: UInt(sender.tag))
        }
        updateAllMenus()
    }
    
    @IBAction func gamePalette(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.palette.game = !image.palette.game
            updateAllMenus()
        }
    }
    
    @IBAction func bigEdian(_ sender: NSMenuItem) {
        if let image = Singleton.sharedInstance()?.image {
            image.bigEndian = !image.bigEndian
            updateAllMenus()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateAllMenus() {
        if let image = Singleton.sharedInstance()?.image {
            // Size
            if let menu = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Size")?.submenu {
                if let width = menu.item(withTitle: "Width")?.submenu {
                    for item in width.items {
                        item.state = item.tag == Int(image.size.width) ? .on : .off
                    }
                }
                
                if let height = menu.item(withTitle: "Height")?.submenu {
                    for item in height.items {
                        item.state = item.tag == Int(image.size.height) ? .on : .off
                    }
                }
            }
            
            // Pixel Aspect Ratio
            if let menu = mainMenu.item(at: 3)?.submenu?.item(withTitle: "Pixel Aspect Ratio")?.submenu {
                if let item = menu.item(withTitle: "1:1") {
                    item.state = image.aspectRatio == 1.0 ? .on : .off
                }
                if let item = menu.item(withTitle: "2:1") {
                    item.state = image.aspectRatio == 2.0 ? .on : .off
                }
                if let item = menu.item(withTitle: "1:2") {
                    item.state = image.aspectRatio == 0.5 ? .on : .off
                }
            }
            
            // Grid
            if let menu = mainMenu.item(at: 3)?.submenu?.item(withTitle: "Grid")?.submenu {
                if let width = menu.item(withTitle: "Width")?.submenu {
                    for item in width.items {
                        let n = item.tag < 1 ? 1 : item.tag
                        item.state = n == image.tileWidth ? .on : .off
                        if image.planeCount > 1 {
                            item.isHidden = (image.bitsPerPixel == 16 && (item.tag == 8 || item.tag == 24)) ? true : false
                        } else {
                            item.isHidden = false
                        }
                    }
                }
                
                if let height = menu.item(withTitle: "Height")?.submenu {
                    for item in height.items {
                        let n = item.tag < 1 ? 1 : item.tag
                        item.state = n == image.tileHeight ? .on : .off
                    }
                }
            }
            
            // Gap
            if let menu = mainMenu.item(at: 3)?.submenu?.item(withTitle: "Gap")?.submenu {
                for item in menu.items {
                    item.state = item.tag == image.padding ? .on : .off
                }
            }
            
            //
            if let menu = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Find")?.submenu {
                if let menu = menu.item(withTitle: "Palette")?.submenu {
                    if let image = Singleton.sharedInstance()?.image {
                        menu.item(withTitle: "Game Palette")?.state = image.palette.game ? .on : .off
                    }
                }
            }
            
            // Big Edian
            if let item = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Big Edian") {
                item.state = image.bigEndian == true ? .on : .off
                item.isEnabled = image.bitsPerPixel == 16 ? true : false
            }
            
            // Pixel Arrangement
            if let menu = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Pixel Arrangement")?.submenu {
                if image.planeCount == 1 {
                    // Packed...
                    menu.item(withTitle: "Planar")?.state = .off
                    menu.item(withTitle: "Packed")?.state = .on
   
                    mainMenu.item(at: 2)?.submenu?.item(withTitle: "Color Depth")?.isEnabled = true
                    if let menu = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Color Depth")?.submenu {
                        menu.item(withTag: 1)?.state = image.bitsPerPixel == 1 ? .on : .off
                        menu.item(withTag: 2)?.state = image.bitsPerPixel == 2 ? .on : .off
                        menu.item(withTag: 4)?.state = image.bitsPerPixel == 4 ? .on : .off
                        menu.item(withTag: 8)?.state = image.bitsPerPixel == 8 ? .on : .off
                        menu.item(withTag: 16)?.state = image.bitsPerPixel == 16 ? .on : .off
                        menu.item(withTag: 24)?.state = image.bitsPerPixel == 24 ? .on : .off
                        menu.item(withTitle: "Alpha Channel")?.state = image.alphaPlane == true ? .on : .off
                    }
                    
                    mainMenu.item(at: 2)?.submenu?.item(withTitle: "Planes")?.isEnabled = false
                    
                } else {
                    // Planar...
                    menu.item(withTitle: "Planar")?.state = .on
                    menu.item(withTitle: "Packed")?.state = .off
                    
                    mainMenu.item(at: 2)?.submenu?.item(withTitle: "Color Depth")?.isEnabled = false
                    mainMenu.item(at: 2)?.submenu?.item(withTitle: "Planes")?.isEnabled = true
                    if let menu = mainMenu.item(at: 2)?.submenu?.item(withTitle: "Planes")?.submenu {
                        menu.item(withTag: 8)?.state = image.bitsPerPixel == 8 ? .on : .off
                        menu.item(withTag: 16)?.state = image.bitsPerPixel == 16 ? .on : .off
                        for n in 1...5 {
                            menu.item(withTag: n)?.state = image.planeCount == n ? .on : .off
                        }
                        menu.item(withTitle: "Alpha Plane")?.state = image.alphaPlane == true ? .on : .off
                        menu.item(withTitle: "Mask Plane")?.state = image.maskPlane == true ? .on : .off
                    
                    }
                }
                
                if let menu = menu.item(withTitle: "Pixel Format")?.submenu {
                    if let image = Singleton.sharedInstance()?.image {
                        menu.item(withTitle: "RGB555")?.state = image.pixelFormat == .RGB555 ? .on : .off
                        menu.item(withTitle: "RGB565")?.state = image.pixelFormat == .RGB565 ? .on : .off
                        menu.item(withTitle: "RGBA555")?.state = image.pixelFormat == .RGBA555 ? .on : .off
                        menu.item(withTitle: "ARGB555")?.state = image.pixelFormat == .ARGB555 ? .on : .off
                    }
                }
                if let image = Singleton.sharedInstance()?.image {
                    menu.item(withTitle: "Pixel Format")?.isEnabled = image.bitsPerPixel == 16 ? true : false
                }
            }
            
        }
    }
    
    
    
}
