# Fork Bomb

funcion llamada : por una mezcla entre que bash lo permite y que ayuda a que el inline sea mas criptico visualmente.

> :

el | es un pipe de linux

> return cmd1 ---> input cmd2

por tanto se ejecuta el mismo mecanismo que hace funcionar algo como

```bash
history | grep sudo
```

pero en este caso no hay nada que pasar realmente, pero si obligara al sistema a intentar retornar un 0 para indicar que completo la ejecucion

> (retorna cero) ==pipe== (retorna 0)

cosa que tendria que hacer... algun dia, porque si la unica logica de : es invocar : se tiene recursion pura y nada mas, asi que ahora tenemos un pipe recursivo, por facilidad () representa la ejecucion de :  === el mencanismo de pipe, asi que recursivamente...

> ()===()===()===()===()===()===()===()===()===()===()===()===()===()===()===()===().... infinitamente al no tener condicion de freno.

finalmente aparece el & que indica un fork y queda entonces en segundo plano...

>                        ( )
>                         |
> ( )===( )===( )===( )===|===( )===( )===( )===( )===( )...
> |     |     |     |         |     |     |     |     |
> ( )   ( )   ( )   ( )       ( )   ( )   ( )   ( )   ( )
> |     |     |     |         |     |     |     |     |
> ( )   ( )   ( )   ( )       ( )   ( )   ( )   ( )   ( )
> |     |     |     |         |     |     |     |     |
> .     .     .     .         .     .     .     .     .
> .     .     .     .         .     .     .     .     .
> .     .     .     .         .     .     .     .     .

recordando que en realidad hasta ahora llevamos solo una definicion de la funcion, seguida de su ejecucion

```bash
:() {
  : | : &
};
:
```

pero reacomodamos todo inline, porque esta genial ver algo tan criptico

```bash
:(){:|:&};:
```

y boom! acabas de matar al OS al detonar pipes encadenando invocaciones de pipes que invocan pipes que invocan pipes...
pero en cada nuevo pipe de hecho estas generando un fork!
