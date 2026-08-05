-- Animation preset: Diablo-1
-- credit: https://github.com/Itz-Abhishek-Tiwari
-- converted from animations/diablo-1.conf

hl.config({ animations = { enabled = true } })

hl.curve("default", {
    type = "bezier",
    points = {{0.05, 0.9}, {0.1, 1.05}}
})
hl.curve("wind", {
    type = "bezier",
    points = {{0.05, 0.9}, {0.1, 1.05}}
})
hl.curve("overshot", {
    type = "bezier",
    points = {{0.13, 0.99}, {0.29, 1.08}}
})
hl.curve("liner", {
    type = "bezier",
    points = {{1.0, 1.0}, {1.0, 1.0}}
})
hl.curve("bounce", {
    type = "bezier",
    points = {{0.4, 0.9}, {0.6, 1.0}}
})
hl.curve("snappyReturn", {
    type = "bezier",
    points = {{0.4, 0.9}, {0.6, 1.0}}
})
hl.curve("slideInFromRight", {
    type = "bezier",
    points = {{0.5, 0.0}, {0.5, 1.0}}
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5.0,
    bezier = "snappyReturn",
    style = "slidevert",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 5.0,
    bezier = "snappyReturn",
    style = "slidevert right",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5.0,
    bezier = "snappyReturn",
    style = "slide",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 6.0,
    bezier = "bounce",
    style = "slide",
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 5.0,
    bezier = "bounce",
    style = "slidevert right",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 10.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 10.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 10.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 10.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 10.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeLayers",
    enabled = true,
    speed = 10.0,
    bezier = "default",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7.0,
    bezier = "overshot",
    style = "slidevert",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 1.0,
    bezier = "liner",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4.0,
    bezier = "bounce",
    style = "slidevert right",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 30.0,
    bezier = "liner",
    style = "loop",
})
