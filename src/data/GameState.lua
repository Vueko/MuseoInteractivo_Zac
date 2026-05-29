-- src/data/GameState.lua
-- Estado global compartido de la campaña.
-- Los minijuegos escriben; MuseumScene y EndingScene leen.
local GS = {
    completed = {},   -- e.g. { mg_prehispanico = true }
    endingShown = false,
}
return GS
