local C = {}
 
C.W  = 1280
C.H  = 720
 
C.COLOR = {
    NEGRO          = {0.04, 0.03, 0.05, 1},
    BEIGE_PERGAMINO= {0.94, 0.88, 0.72, 1},
    CAFE_OSCURO    = {0.22, 0.13, 0.07, 1},
 
    CANTERA_ROSA   = {0.82, 0.55, 0.47, 1},
    CANTERA_GRIS   = {0.60, 0.57, 0.54, 1},
    ORO_PLATA      = {0.85, 0.75, 0.30, 1},
    PLATA          = {0.78, 0.78, 0.80, 1},
    ROJO_SANGRE    = {0.60, 0.08, 0.08, 1},
 
    BLANCO         = {1,    1,    1,    1},
    NEGRO_UI       = {0,    0,    0,    0.75},
    AMARILLO_HUD   = {1.00, 0.85, 0.20, 1},
    VERDE_MENU     = {0.15, 0.55, 0.25, 1},
    TRANSPARENTE   = {0,    0,    0,    0},
}
 
C.PLAYER_SPEED     = 160
C.INTERACT_RADIUS  = 72
 
C.HINT_INTERACT = "[E] / [Enter] para interactuar"
C.HINT_BACK = "[Esc] para regresar"
 
C.PERIODS = {
    { id = "mg_prehispanico",  label = "Prehispanico",         year = "~200 a.C. – 1546",   color = {0.55, 0.35, 0.15, 1} },
    { id = "mg_conquista",     label = "Conquista y Colonia",  year = "1546 – 1700",        color = {0.50, 0.20, 0.10, 1} },
    { id = "mg_mineria",       label = "Época de la Plata",    year = "1546 – 1821",        color = {0.70, 0.70, 0.72, 1} },
    { id = "mg_independencia", label = "Independencia",        year = "1810 – 1867",        color = {0.15, 0.45, 0.20, 1} },
    { id = "mg_revolucion",    label = "Revolución Mexicana",  year = "1910 – 1920",        color = {0.60, 0.08, 0.08, 1} },
}
 
return C