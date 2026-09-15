/* Overlay bars. COLOR / BAR_OUTLINE are painted at launch from
   colors/active-colors.json (Ash defaults here; wallust tints accent + textDim). */

#define C_LINE 0
#define BAR_WIDTH 8
#define BAR_GAP 4
#define BAR_OUTLINE #333333
#define BAR_OUTLINE_WIDTH 0
#define AMPLIFY 320
#define USE_ALPHA 1
#define GRADIENT_POWER 120.0
#define GRADIENT clamp(d / GRADIENT_POWER, 0.0, 1.0)
#define COLOR mix(#454545, #C8C8C8, GRADIENT)
#define DIRECTION 0
#define INVERT 0
#define FLIP 0
#define MIRROR_YX 0
