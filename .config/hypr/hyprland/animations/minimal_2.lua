-- Animation preset: Minimal-2
-- converted from animations/minimal-2.conf

hl.config({ animations = { enabled = true } })

hl.curve("quart", {
    type = "bezier",
    points = {{0.25, 1.0}, {0.5, 1.0}}
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 6.0,
    bezier = "quart",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 6.0,
    bezier = "quart",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 6.0,
    bezier = "quart",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 6.0,
    bezier = "quart",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 6.0,
    bezier = "quart",
})
