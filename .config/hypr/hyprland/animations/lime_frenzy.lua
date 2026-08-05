-- Animation preset: LimeFrenzy
-- credit: https://github.com/xaicat/LimeFrenzy/
-- converted from animations/LimeFrenzy.conf

hl.config({ animations = { enabled = true } })

hl.curve("default", {
    type = "bezier",
    points = {{0.12, 0.92}, {0.08, 1.0}}
})
hl.curve("wind", {
    type = "bezier",
    points = {{0.12, 0.92}, {0.08, 1.0}}
})
hl.curve("overshot", {
    type = "bezier",
    points = {{0.18, 0.95}, {0.22, 1.03}}
})
hl.curve("liner", {
    type = "bezier",
    points = {{1.0, 1.0}, {1.0, 1.0}}
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5.0,
    bezier = "wind",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 6.0,
    bezier = "overshot",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4.0,
    bezier = "overshot",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4.0,
    bezier = "overshot",
    style = "slide",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4.0,
    bezier = "default",
    style = "popin",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 7.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 7.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 7.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 7.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 7.0,
    bezier = "default",
})
hl.animation({
    leaf = "fadeLayers",
    enabled = true,
    speed = 7.0,
    bezier = "default",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5.0,
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
    leaf = "borderangle",
    enabled = true,
    speed = 24.0,
    bezier = "liner",
    style = "loop",
})
