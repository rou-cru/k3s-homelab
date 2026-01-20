# Diseño de Networking

El manejo de red requiere un entendimiento y manejo cuidadosos en el proyecto dada las implicaciones de un posible atacante y el colosal blast radious que se tendria si existe una brecha explicita explotable. 
No se debe dejar nada a interpretacion y no se debe dejar nada al asar, se debe diseñar con la seguridad en mente y implementarlo pensando en que la operacion diaria si bien debe ser simple, 
tambien en caso de un incidente de seguridad debe ser facil reaccionar para bloquear al atacante y mitigar daños de inmediato.

Se manejara una infraestructura en varias capaz que proveera caminos especificos segun las condiciones requeridas, 
pero se bloqueara cualquier otro escenario por seguridad. Se debe analizar posibles caminos alternos no planificados para asegurarse de que en efecto,
tenemos ya el diseño de red final, de existir caminos que puedan ser usados por un atacante hay que replantear el diseño.

A continuacion se describen los escenarios y como se espera resolverlos con el diseño de red.

## Networking entre Nodos

Problema: Los nodos pueden estar en distintas ubicaciones geograficas, con multiples contextos de red distintos y en muchos casos no podemos o no debemos 
          alterar nada respecto a esa red donde esta el nodo.

Solucion: Tailscale permite atravesar routers residenciales y dar una salida estandar que es usable tambien para nodos desde un Cloud provider. 
          Adicionalmente nos permite aplanar la red fisica del cluster al generar una "LAN" con el mesh de tailscale.
          Como ventaja adicional tambien es posible usar tailscale para generar acceso controlado y seguro desde cualquier ubicacion a todo personal
          autorizado para gestion de la red o el cluster, incluyendo accesos regulares desde equipos especificos agregados a la red o en caso de alguna emergencia
          es posible agregar SSH desde el mismo website de tailscale para usuarios autorizados.

Notas: Hasta donde se sabe, esto movera el trafico entre locaciones de forma encriptada, por lo que no hay riesgos de sniff en red local o ISPs demasiado intrusivos. 

## Networking interno del cluster

Problema: Con una red como la generada por tailscale tenemos conexion entre nodos pero kubernetes necesita al CNI para abstraerlo y manejar internamente el trafico.
Solucion: Cilium es por lejos el CNI mas avanzado, completo y eficiente que se conoce al momento de este diseño, por lo que es la eleccion de CNI.
          Aporta no solo el CNI base, permite mejor manejo de network policies, eBPF, observabilidad, gateway api y demas temas de networking interno en un ecosistema perfectamente unificado por lo que reduce la carga operativa y mejora el rendimiento de red, sin generar friccion con el uso de tailscale como metodo para mover el trafico entre nodos.
Notas: Cilium no debe permitir interaccion con LAN para ningun workload, sin embargo si que se requiere acceso a internet, debe confirmarse que esto se implementa correctamente para garantizar que no se esta creando una brecha hacia LAN de un nodo comprometido.
         

## Websites, dashboards y trafico simple HTTP/HTTPS

Problema: 

1. Se debe atravesar las limitaciones de un ISP de manera simple y estandar para el cluster
2. Se debe asumir que DDNS no es factible dada las diferencias de red que buscamos solventar con tailscale, asumir DDNS obligaria a romper la abstraccion ya lograda
3. Al ser una exposicion a internet que llega hasta un pod o mas, es por mucho una brecha latente si no se maneja adecuadamente.
4. Al ser un punto de acceso "libre" al cluster, ademas de ser encontrado facilmente(de hecho, se promociona activamente!), es el primer punto donde se espera posible actividad maliciosa que comprometa al cluster.

Solucion: 

1. Cloudflared creando 1 unico tunel el cual redirige todo trafico al gateway para delegar a Cilium el networking interno. Su funcion es unicamente atravesar ISPs entre el cliente y el cluster sin manipular puertos o cualquier otra limitante.
2. Gateway API + HTTPRoutes permitira un control de que esta expuesto intencionalmente de manera nativa, explicita y controlada. Cilium podra localizar el service adecuado, enrutar por tailscale al nodo correcto y devolver el trafico al tunel para su exposicion. Con esto, todo el manejo de red se puede integrar a los Helm Charts de cada workload expuesto para aprovechar el tunel de cloudflare sin conocimiento alguno de la topologia de red fisica y de una manera estandarizada dentro del cluster.

Notas: 
- Cloudflare usara el tunel para subdominios *.roura.xyz
- Es critico asegurar que la comunicacion externa va directo al gateway y el gateway no aceptara mas que subdominios coherentes(un pod algo.com no deberia poder exponer dado que no es subdominio de roura.xyz y este es por ahora el unico dominio autorizado)
- Cloudflare provee capaz de seguridad previas a la llegada al cluster, pero hay que validar que no se genere problemas operativos para la exposicion autorizada debido a esto
- El workload puede ser una brecha en si mismo, por lo que un camino de red seguro hasta el no garantiza que no se tengan problemas si el workload da acceso al cluster que pueda ser explotado por un atacante para escapar del contenedor.
- Hay que plantear reglas de red para que Cilium no permita que un pod expuesto a internet y que ha sido comprometido intente actuar a nivel de red arbitrariamente 
- Esta fuera del scope de este diseño, pero se recomienda considerar la relacion exposicion/permisos de la carga para evitar que un contenedor comprometido pueda darse su propio acceso de red adicional.
- Por regla general, un workload expuesto bajo este metodo no debe tener acceso al host a ningun nivel o forma, tampoco privilegios. si requiere persistencia debe ser un volumen definido explicitamente para ello. se recomienda el uso de gVisor para toda carga que se exponga bajo este modo como barrera de seguridad adicional ante un incidente.

## Networking Akash

Problema: Akash requiere explicitamente el uso de una IP publica y apertura de puertos para incorporarse a su red de proveedores, esto es un requisito critico para poder operar.
Solucion:

1. Se plantea el uso de un VPS que provea el cumplimiento de requisitos de Akash
2. El VPS debe incorporarse al cluster usando la red Tailscale del cluster.
3. El VPS sera tratado como un router de uso restringido para el cluster, solo el trafico explicitamente permitido podra pasar por el para exposicion
4. Se colocara un Ingress Nginx el cual sera el punto de entrada al cluster utilizando la red del proveedor de VPS para saltar la limitacion de IP publica por lo que la IP del VPS es la IP de proveedor en Akash
5. No debe existir colision o traslapes entre este ingress y el gateway, el ingress sera reservado unicamente para Akash. De existir otro caso con la necesidad de IP publica, puertos o ambas, se creara un segundo Ingress para ello.

Notas: 
- Se considera que por simplicidad operativa sumado al manejo de acceso, lo mejor es asociar un ingress a un namespace y bloquear toda comunicacion que se intente hacia un namespace distinto al asociado con el ingress que esta exponiendo la carga.
- Es importante monitorear el uso de red que atraviesa el ingress para evitar problemas de costos.
- Las cargas asociadas al ingress deberan ejecutarse con gVisor
- No se tiene claro aun como sera la relacion de exposicion para las cargas que provienen de Akash, todas tendran exposicion?
- No se dara acceso host o privilegios a ninguna carga que provenga de Akash, esto es completamente independiente de la necesidad de gVisor(principalmente porque existe la posibilidad que algun workload pudiera ser incompatible, aun se requiere mas informacion sobre esto)
- No se ha definido el VPS y por tanto no se conocen otras implicaciones de red a nivel de seguridad

## Otros escenarios posibles

Idealmente cada escenario adicional tendria que ser completamente definido para garantizar el diseño seguro, sin embargo como referencia general se considera que:

- Si es compatible con el tunel de cloudflare, se usara ese Gateway asociado.
- Si se requiere exposicion incompatible con Cloudflare, se debe usar el VPS.
- En caso de usar el VPS como punto de salida para casos distintos al de Akash, se debera crear un segundo Gateway dedicado unicamente al trafico por VPS
- Al igual que en otros casos, un workload que puede ser accedido fuera del cluster debe usar gVisor, no recibir privilegios, no tener acceso alguno al Host y ser vigilado en cuanto a uso de red desde la perspectiva del VPS por control de costos.

## WARNINGS

- Por cuestion de necesidad operativa se dara consideracion especial al uso de exposicion para workloads que estan ejecutandose en el nodo master
- Se debe proveer afinidad en nodos distintos al master para minimizar su uso cuando sea posible
- Esto son consideraciones de precaucion al no contar con mas nodos, pero se espera que progresivamente el cluster cresca y en algun punto se implemente un taint para evitar exposicion desde el nodo master de manera directa.

## WARNINGS critico: mineros

- Existen cargas de mineria y estas estan en el nodo master. Estas deben ser protegidas a toda costa al ser la ruta principal para lograr control total de parte de un atacante.
Toda actividad no autorizada explicitamente que involucre a estos pods debe ser bloqueada y por regla general un workload expuesto no esta autorizado.
- Los mineros tienen privilegio, acceso al host a nivel red y volumenes que se relacionan directamente a directorios del OS del nodo. Comprometer estos contenedores por un ataque externo es comprometer el cluster entero al poder acceder al OS del master y las multiples redes locales que esten asociadas a cada nodo como efecto secundario de la red tailscale, este es por mucho el peor escenario detectado en el analisis y representa un blast radious superior al 100% de produccion al involucrar la posibilidad de regalar caminos a redes que no controlamos.
- Dado que los mineros no tienen razon alguna para comunicarse ademas mas que con su pool(desde hostNetwork), en principio la unica comunicacion por fuera del namespace seria la de observabilidad. Se entiende que la automatizacion futura para escalamientos a 0 o regresar a 1 no requiere interaccion de red alguna con el pod ya que es gestionado a traves de la API y no de manera directa.
