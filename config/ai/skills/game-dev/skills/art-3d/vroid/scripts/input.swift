// Synthetic mouse/keyboard for macOS via CoreGraphics. Build: swiftc -O -o bin/input input.swift
// Needs Accessibility permission for the terminal app (System Settings > Privacy & Security > Accessibility).
import Foundation
import CoreGraphics
import ApplicationServices

func post(_ e: CGEvent?, _ ms: UInt32 = 25) { e?.post(tap: .cghidEventTap); usleep(ms * 1000) }
func pt(_ a: [String], _ i: Int) -> CGPoint { CGPoint(x: Double(a[i]) ?? 0, y: Double(a[i + 1]) ?? 0) }
func move(_ p: CGPoint) { post(CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)) }

func click(_ p: CGPoint, button: CGMouseButton = .left, count: Int64 = 1) {
    move(p)
    let (d, u): (CGEventType, CGEventType) = button == .left ? (.leftMouseDown, .leftMouseUp) : (.rightMouseDown, .rightMouseUp)
    for c in 1...count {
        let down = CGEvent(mouseEventSource: nil, mouseType: d, mouseCursorPosition: p, mouseButton: button)
        down?.setIntegerValueField(.mouseEventClickState, value: c)
        post(down, 40)
        let up = CGEvent(mouseEventSource: nil, mouseType: u, mouseCursorPosition: p, mouseButton: button)
        up?.setIntegerValueField(.mouseEventClickState, value: c)
        post(up, 60)
    }
}

func drag(_ a: CGPoint, _ b: CGPoint, steps: Int = 25) {
    move(a)
    post(CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: a, mouseButton: .left), 80)
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        post(CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: p, mouseButton: .left), 15)
    }
    post(CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: b, mouseButton: .left), 80)
}

func scroll(_ p: CGPoint, dx: Int32, dy: Int32) {
    move(p)
    post(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0), 60)
}

let keycodes: [String: CGKeyCode] = [
    "a":0,"s":1,"d":2,"f":3,"h":4,"g":5,"z":6,"x":7,"c":8,"v":9,"b":11,"q":12,"w":13,"e":14,"r":15,"y":16,"t":17,
    "1":18,"2":19,"3":20,"4":21,"6":22,"5":23,"=":24,"9":25,"7":26,"-":27,"8":28,"0":29,"]":30,"o":31,"u":32,"[":33,"i":34,"p":35,
    "return":36,"enter":36,"l":37,"j":38,"'":39,"k":40,";":41,"\\":42,",":43,"/":44,"n":45,"m":46,".":47,"tab":48,"space":49,"`":50,
    "delete":51,"backspace":51,"esc":53,"escape":53,"f1":122,"f2":120,"f3":99,"f4":118,"f5":96,"f6":97,"f7":98,"f8":100,"f9":101,"f10":109,"f11":103,"f12":111,
    "home":115,"pageup":116,"forwarddelete":117,"end":119,"pagedown":121,"left":123,"right":124,"down":125,"up":126,
]
func flags(_ mods: [String]) -> CGEventFlags {
    var f = CGEventFlags()
    for m in mods {
        switch m.lowercased() { case "cmd","command": f.insert(.maskCommand); case "shift": f.insert(.maskShift)
        case "alt","option": f.insert(.maskAlternate); case "ctrl","control": f.insert(.maskControl); default: break }
    }
    return f
}
func key(_ name: String, mods: [String]) {
    guard let code = keycodes[name.lowercased()] else { print("unknown key \(name)"); exit(2) }
    let f = flags(mods)
    let d = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true); d?.flags = f; post(d, 30)
    let u = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false); u?.flags = f; post(u, 30)
}
func type(_ text: String) {
    for ch in text.unicodeScalars {
        var u = [UniChar](String(ch).utf16)
        let d = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true); d?.keyboardSetUnicodeString(stringLength: u.count, unicodeString: &u); post(d, 12)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false); up?.keyboardSetUnicodeString(stringLength: u.count, unicodeString: &u); post(up, 12)
    }
}

/// Largest on-screen window of an app: prints "x y w h windowID"
func window(_ owner: String) {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { exit(1) }
    var best: (CGRect, Int)? = nil
    for w in list {
        guard let o = w[kCGWindowOwnerName as String] as? String, o.lowercased().contains(owner.lowercased()),
              (w[kCGWindowLayer as String] as? Int) == 0,
              let b = w[kCGWindowBounds as String] as? [String: Double], let id = w[kCGWindowNumber as String] as? Int else { continue }
        let r = CGRect(x: b["X"]!, y: b["Y"]!, width: b["Width"]!, height: b["Height"]!)
        if best == nil || r.width * r.height > best!.0.width * best!.0.height { best = (r, id) }
    }
    guard let (r, id) = best else { print("no window for \(owner)"); exit(1) }
    print("\(Int(r.minX)) \(Int(r.minY)) \(Int(r.width)) \(Int(r.height)) \(id)")
}

let a = CommandLine.arguments
guard a.count > 1 else { print("usage: input check|pos|move x y|click x y|dclick x y|rclick x y|drag x1 y1 x2 y2|scroll x y dx dy|key name [mods...]|type text|window app"); exit(2) }
switch a[1] {
case "check": print(AXIsProcessTrusted() ? "accessibility: OK" : "accessibility: DENIED - System Settings > Privacy & Security > Accessibility > enable your terminal app"); exit(AXIsProcessTrusted() ? 0 : 3)
case "pos": let p = CGEvent(source: nil)!.location; print("\(Int(p.x)) \(Int(p.y))")
case "move": move(pt(a, 2))
case "click": click(pt(a, 2))
case "dclick": click(pt(a, 2), count: 2)
case "rclick": click(pt(a, 2), button: .right)
case "drag": drag(pt(a, 2), pt(a, 4))
case "scroll": scroll(pt(a, 2), dx: Int32(a[4]) ?? 0, dy: Int32(a[5]) ?? 0)
case "key": key(a[2], mods: Array(a.dropFirst(3)))
case "type": type(a.dropFirst(2).joined(separator: " "))
case "window": window(a[2])
default: print("unknown command \(a[1])"); exit(2)
}
