; G6509.1.g: ROTATION PROBE - EXECUTE
;
; Calculate workpiece rotation from two probed points on a
; single surface. Stores the rotation angle and optionally
; applies G68 rotation compensation.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

if { exists(param.W) && param.W != null && (param.W < 0 || param.W >= limits.workplaces) }
    abort { "Work Offset (W..) must be between 0 and " ^ limits.workplaces-1 ^ "!" }

if { !exists(param.J) || !exists(param.K) || !exists(param.L) }
    abort { "Must provide first probed position using J, K and L parameters!" }

if { !exists(param.X) || !exists(param.Y) || !exists(param.Z) }
    abort { "Must provide second probed position using X, Y and Z parameters!" }

if { !exists(param.H) || param.H < 0 || param.H > 3 }
    abort { "Must provide a valid surface direction (H...) between 0 and 3!" }

; Make sure probe tool is selected
if { global.mosPTID != state.currentTool }
    abort { "Must run T" ^ global.mosPTID ^ " to select the probe tool before probing!" }

; Increment the probe surface and point totals for status reporting
set global.mosPRST = { global.mosPRST + 1 }
set global.mosPRPT = { global.mosPRPT + 2 }

; Default workOffset to the current workplace number if not specified
var workOffset = { (exists(param.W) && param.W != null) ? param.W : move.workplaceNumber }
var wcsNumber = { var.workOffset + 1 }

; Reset stored rotation value
M5010 W{var.workOffset} R32

; Calculate deltas between probe points
var dX = { param.X - param.J }
var dY = { param.Y - param.K }

; Calculate rotation angle based on surface direction
; X-facing surfaces (Left=0, Right=1): surface runs along Y axis
;   Rotation = atan2(dX, dY) — deviation of X along Y
; Y-facing surfaces (Front=2, Back=3): surface runs along X axis
;   Rotation = atan2(dY, dX) — deviation of Y along X
var angle = { (param.H <= 1) ? degrees(atan2(var.dX, var.dY)) : degrees(atan2(var.dY, var.dX)) }

; Reduce angle to +/-45 degrees range
; Workpiece rotation should be small. If we get a large angle
; we are measuring the wrong quadrant.
while { var.angle > 45 }
    set var.angle = { var.angle - 90 }
while { var.angle < -45 }
    set var.angle = { var.angle + 90 }

; Store rotation angle
set global.mosWPDeg[var.workOffset] = { var.angle }

; Report probe results if requested
if { !exists(param.R) || param.R != 0 }
    M7601 W{var.workOffset}
    echo { "MillenniumOS: Probed rotation of " ^ var.angle ^ " degrees on WCS " ^ var.wcsNumber ^ "." }

; Offer to apply rotation compensation
M5011 W{var.workOffset}
