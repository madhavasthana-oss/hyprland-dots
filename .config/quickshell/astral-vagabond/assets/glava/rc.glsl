/* Astral-Vagabond glava overlay — transparent OpenGL bars, Ash palette.
   Loaded via XDG_CONFIG_HOME pointing at assets/ (this file lives in assets/glava/). */

#request mod bars

#request setfloating  true
#request setdecorated false
#request setfocused   false
#request setmaximized false

#request setopacity "native"
#request setmirror false
#request setversion 3 3
#request setshaderversion 330
#request settitle "astral-vagabond-glava"

/* Overridden at launch with the monitor's bottom strip. */
#request setgeometry 0 0 1920 240
#request setbg 00000000

#request setxwintype "normal"
#request addxwinstate "sticky"
#request addxwinstate "skip_taskbar"
#request addxwinstate "skip_pager"
#request addxwinstate "above"
#request addxwinstate "pinned"
#request setclickthrough true

#request setsource "auto"
#request setswap 1
#request setinterpolate true
#request setframerate 60
#request setfullscreencheck false
#request setprintframes false
#request setsamplesize 1024
#request setbufsize 4096
#request setsamplerate 22050
#request setforcegeometry false
#request setforceraised false
#request setbufscale 1
