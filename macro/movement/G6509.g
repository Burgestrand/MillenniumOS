; G6509.g: ROTATION PROBE
;
; Guided probe cycle to measure workpiece rotation by probing
; 2 points on a single surface. The operator selects a surface
; direction, jogs to each position and the probe fires
; directly from where they are.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Require touch probe for rotation measurement
if { !global.mosFeatTouchProbe }
    abort { "Rotation probe requires a touch probe!" }

; Display description of rotation probe if not displayed this session
if { global.mosTM && !global.mosDD[9] }
    M291 P"This operation measures workpiece rotation by probing 2 points on a single surface. The angle between these points is used to calculate how far the workpiece is rotated from the machine axes." R"MillenniumOS: Rotation Probe" T0 S2
    M291 P"You will select a surface direction, then jog to each position in turn. The probe will fire directly from where you jog to." R"MillenniumOS: Rotation Probe" T0 S2
    M291 P"<b>CAUTION</b>: Jogging in RRF does <b>NOT</b> watch the probe status. Be careful!" R"MillenniumOS: Rotation Probe" T0 S2
    M291 P"<b>TIP</b>: Greater separation between the two probe points gives more accurate results." R"MillenniumOS: Rotation Probe" T0 S4 K{"Continue", "Cancel"} F0
    if { input != 0 }
        abort { "Rotation probe aborted!" }

    set global.mosDD[9] = true

; Make sure probe tool is selected
if { global.mosPTID != state.currentTool }
    T T{global.mosPTID}

var pID = { global.mosTPID }

; Select surface direction to probe
M291 P"Please select the surface to probe for rotation measurement.<br/><b>NOTE</b>: Surface names are relative to an operator standing at the front of the machine." R"MillenniumOS: Rotation Probe" T0 S4 F0 K{"Left","Right","Front","Back"}
var probeAxis = { input }

; Prompt for probe distance
M291 P"Please enter the max distance to probe towards the surface in mm." R"MillenniumOS: Rotation Probe" J1 T0 S6 F{global.mosCL}
if { result != 0 }
    abort { "Rotation probe aborted!" }

var probeDist = { input }
if { var.probeDist < 0 }
    abort { "Probe distance must not be negative!" }

; Jog to first position
M291 P"Please jog the probe to the <b>first</b> position near the surface, then press <b>OK</b>.<br/><b>CAUTION</b>: Jogging in RRF does <b>NOT</b> watch the probe status!" R"MillenniumOS: Rotation Probe" X1 Y1 Z1 T0 S3
if { result != 0 }
    abort { "Rotation probe aborted!" }

; Confirm probe direction before first probe
var dirSign = { (var.probeAxis == 0 || var.probeAxis == 2) ? "positive" : "negative" }
var dirAxis = { (var.probeAxis <= 1) ? "X" : "Y" }

if { global.mosTM }
    M291 P{"Probe will move in <b>" ^ var.dirSign ^ " " ^ var.dirAxis ^ "</b> for up to <b>" ^ var.probeDist ^ "</b> mm."} R"MillenniumOS: Rotation Probe" T0 S4 K{"Continue", "Cancel"} F0
    if { input != 0 }
        abort { "Rotation probe aborted!" }

; Probe P1 from current position in the selected direction
M5000 P0
if { var.probeAxis == 0 }
    G6512.1 I{var.pID} X{global.mosMI[0] + var.probeDist}
elif { var.probeAxis == 1 }
    G6512.1 I{var.pID} X{global.mosMI[0] - var.probeDist}
elif { var.probeAxis == 2 }
    G6512.1 I{var.pID} Y{global.mosMI[1] + var.probeDist}
elif { var.probeAxis == 3 }
    G6512.1 I{var.pID} Y{global.mosMI[1] - var.probeDist}

var p1 = { global.mosMI }

; Jog to second position
M291 P"Please jog the probe to the <b>second</b> position along the surface, then press <b>OK</b>.<br/><b>TIP</b>: Greater separation between points gives more accurate results." R"MillenniumOS: Rotation Probe" X1 Y1 Z1 T0 S3
if { result != 0 }
    abort { "Rotation probe aborted!" }

; Probe P2 from current position in the selected direction
M5000 P0
if { var.probeAxis == 0 }
    G6512.1 I{var.pID} X{global.mosMI[0] + var.probeDist}
elif { var.probeAxis == 1 }
    G6512.1 I{var.pID} X{global.mosMI[0] - var.probeDist}
elif { var.probeAxis == 2 }
    G6512.1 I{var.pID} Y{global.mosMI[1] + var.probeDist}
elif { var.probeAxis == 3 }
    G6512.1 I{var.pID} Y{global.mosMI[1] - var.probeDist}

var p2 = { global.mosMI }

; Call execution macro with probed positions
G6509.1 W{exists(param.W) ? param.W : null} H{var.probeAxis} J{var.p1[0]} K{var.p1[1]} L{var.p1[2]} X{var.p2[0]} Y{var.p2[1]} Z{var.p2[2]}
