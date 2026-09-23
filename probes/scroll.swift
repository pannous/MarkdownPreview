// Posts a scroll-wheel event (negative = down) to the given process, to test scroll preservation without UI scripting.
import CoreGraphics
let pid = pid_t(CommandLine.arguments[1])!
let lines = Int32(CommandLine.arguments[2])!
CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0)!.postToPid(pid)
