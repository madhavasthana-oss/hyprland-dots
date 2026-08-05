-- Animation preset: Diablo-2
-- credit: https://github.com/Itz-Abhishek-Tiwari
-- converted from animations/diablo-2.conf

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

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 7.0,
    bezier = "wind",
    style = "popin",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 7.0,
    bezier = "overshot",
    style = "popin",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5.0,
    bezier = "overshot",
    style = "popin",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 6.0,
    bezier = "overshot",
    style = "slide",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 5.0,
    bezier = "default",
    style = "popin",
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
    leaf = "borderangle",
    enabled = true,
    speed = 30.0,
    bezier = "liner",
    style = "loop",
})
