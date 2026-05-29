-- src/data/CampaignData.lua
-- Fuente única de toda la narrativa de la campaña.
local D = {}

D.chapters = {

    mg_prehispanico = {
        opening = {
            "Zacatecas, siglo II a.C.\n\nMucho antes de que llegara cualquier explorador europeo, el norte de Mesoamérica era territorio de pueblos que conocían cada cerro, cada veta de roca y cada corriente de agua.",
            "Los Zacatecos, Caxcanes y Guachichiles no eran civilizaciones sedentarias. Eran guerreros y cazadores que dominaban un territorio árido que nadie más podía sostener.",
            "Cuando llegaron los primeros españoles al norte, encontraron una resistencia que duró cinco décadas.\n\nLa Guerra Chichimeca (1550–1600) fue el conflicto armado más prolongado entre pueblos indígenas y fuerzas europeas en América del Norte.",
            "Defiende tu aldea. No como símbolo, sino como lo que era:\nel único hogar que estos pueblos habían conocido.\n\n• Mueve a tu HÉROE con ← → (o A/D)\n• ESPACIO para lanzar tu lanza\n• CLIC IZQUIERDO para construir TORRES (costo: 5 oro)\n• ¡Sobrevive a las 3 oleadas para ganar!",
        },
        quote = {
            speaker = "Guerrero Zacateco, ~1550",
            text    = "No peleamos por odio al extranjero.\nPeleamos porque esta tierra tiene un nombre\nque solo nosotros pronunciamos correctamente.",
        },
        bridge = "Los españoles no ganaron esta tierra por fuerza sola. Entraron por acuerdos, por traiciones y por algo más poderoso que las armas: la plata que dormía en las montañas.\n\nAlguien tendría que ir a buscarla.",
    },

    mg_conquista = {
        opening = {
            "1546. Juan de Tolosa, soldado vasco al servicio de la Corona, recorre el norte de la Nueva España con un puñado de hombres y guías indígenas aliados del occidente.",
            "El 8 de septiembre de 1546, al pie del Cerro de la Bufa, Tolosa encontró lo que buscaba: vetas de plata de una riqueza sin precedente.\n\nEn dos años, ese cerro daría nombre a una de las ciudades más importantes del continente.",
            "La fundación de Zacatecas no fue obra de un solo hombre.\nCuatro capitanes — Tolosa, Cristóbal de Oñate, Diego de Ibarra y Baltazar Temiño — formaron la sociedad que extraería la plata.\n\nFue un negocio antes de ser una ciudad.",
            "Explora las cuevas.\nEncuentra la veta de plata antes de que se agoten los recursos de la expedición.\n\n• Muévete con WASD o las flechas\n• Llega a la veta marcada antes de que el tiempo termine",
        },
        quote = {
            speaker = "Juan de Tolosa, ~1548",
            text    = "Vine buscando riqueza para la Corona.\nEncontré una tierra que no se deja tener:\nsolo se comparte.",
        },
        bridge = "La plata encontrada cambió todo. Pero extraerla requería algo que ningún explorador traía consigo: miles de manos.\n\nY esas manos tendrían un precio que la historia tardó mucho en reconocer.",
    },

    mg_mineria = {
        opening = {
            "Siglos XVI–XVII. El Real de Minas de Zacatecas se convirtió en la segunda ciudad más importante de la Nueva España.\n\nSu plata financiaba guerras en Europa, flotas en el Atlántico y catedrales en ambos continentes.",
            "El método de patio, desarrollado en Pachuca en 1554 por Bartolomé de Medina y adoptado en Zacatecas hacia 1562, permitía separar la plata del mineral mezclándola con mercurio.\n\nEra más eficiente. También era venenoso.",
            "Los trabajadores eran indígenas bajo el sistema de repartimiento, africanos esclavizados y mestizos libres. Todos construyeron la misma ciudad.\n\nMuy pocos aparecen en los registros históricos.",
            "Administra la mina.\nExtrae el mineral, gestiona tus trabajadores, envía plata a la Corona.\n\n• CLIC en los botones + / − para asignar trabajadores\n• Llena la cuota de plata antes de que acabe el tiempo",
        },
        quote = {
            speaker = "Trabajador de las minas de Zacatecas, ~1600",
            text    = "Bajamos al cerro cada mañana sin saber si volveríamos.\nLa plata sube.\nNosotros, no siempre.",
        },
        bridge = "Tres siglos de extracción construyeron una ciudad, una clase mercante y también un resentimiento profundo.\n\nPara 1810, Zacatecas era rica y desigual. Esa combinación tiene un solo destino posible.",
    },

    mg_independencia = {
        opening = {
            "21 de septiembre de 1810. Las noticias del Grito de Dolores llegaron a Zacatecas cinco días después de que Hidalgo las pronunciara.\n\nLa ciudad se dividió: quienes querían mantener el orden colonial y quienes ya no podían.",
            "Los insurgentes no tenían ejército regular. Operaban con mensajeros, con redes de contactos, con información que viajaba de mano en mano por caminos vigilados.\n\nCada mensaje entregado era una victoria invisible.",
            "Hidalgo pasó personalmente por Zacatecas buscando armas y aliados hacia el norte.\n\nNo todos lo recibieron como héroe. La Independencia nunca fue un movimiento unánime.",
            "Eres un mensajero insurgente. Los caminos están vigilados.\nEntrega los mensajes antes de ser descubierto.\n\n• Muévete con WASD o las flechas\n• Evita el campo de visión de las patrullas\n• Llega a los tres puntos de entrega marcados",
        },
        quote = {
            speaker = "Mensajero insurgente, Zacatecas, ~1813",
            text    = "No cargo armas.\nCargo palabras.\nY en tiempos así, las palabras son más peligrosas.",
        },
        bridge = "La Independencia llegó en 1821, pero la paz no vino con ella.\n\nUn siglo después, las mismas preguntas sobre tierra, poder y dignidad explotarían de nuevo — esta vez con cañones en el Cerro de la Bufa.",
    },

    mg_revolucion = {
        opening = {
            "23 de junio de 1914. El general Francisco Villa y su División del Norte enfrentan el último gran bastión del ejército de Victoriano Huerta.\n\nZacatecas, por su posición estratégica, era la llave hacia la Ciudad de México.",
            "Villa desobedeció las órdenes de Venustiano Carranza y atacó con toda su División.\n\nEl general Felipe Ángeles, artillero formado en las escuelas militares de Fontainebleau y Mailly (Francia), diseñó el plan: rodear la ciudad desde todos los flancos al mismo tiempo.",
            "24 cañones. Ataque simultáneo desde el norte, el sur y el oriente.\n\nEl Cerro de la Bufa — el mismo cerro donde todo comenzó en 1546 — sería el último reducto federal.\n\nEn 8 horas, la ciudad cayó. Más de 6,000 soldados federales murieron en ese día.",
            "Coordina la artillería y la infantería.\nToma las posiciones del ejército federal una por una.\n\n• CLIC en una posición para asignarle tropas\n• Presiona ATACAR cuando estés listo\n• El Cerro de la Bufa es el objetivo final",
        },
        quote = {
            speaker = "General Felipe Ángeles, 1914",
            text    = "Una batalla bien pensada no se gana con más sangre, sino con menos.\nEl cerro cayó porque entendimos el terreno —\nel mismo que los Zacatecos defendieron trescientos años antes.",
        },
        bridge = "El cerro que vio llegar a Tolosa, que sostuvo las minas coloniales, que escuchó los mensajes insurgentes, ahora era libre.\n\nO al menos, eso creían.",
    },
}

D.ending = {
    title = "Zacatecas: Cinco siglos, una identidad",
    paragraphs = {
        "Cinco períodos. Cinco grupos de personas que vivieron en el mismo territorio, a veces en conflicto, a veces en colaboración, siempre transformándose mutuamente.\n\nLa identidad zacatecana no viene de un solo origen. Viene de todos ellos.",
        "Los Zacatecos nombraron la tierra.\nLos exploradores la abrieron.\nLos mineros la sostuvieron.\nLos insurgentes la reclamaron.\nLos revolucionarios la disputaron.\n\nCada uno dejó algo: una palabra, una técnica, una forma de ver el cerro.",
        "La historia regional no es un conjunto de héroes y villanos.\nEs un proceso en curso.\n\nConocerla no sirve para enorgullecerse.\nSirve para entender de dónde venimos\ny qué decidimos hacer con eso.",
    },
}

return D
