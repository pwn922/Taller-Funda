# Taller de Fundamentos: Creación de un Compilador para un Lenguaje Propio

## Documentación

### Variables

## Instrucciones de uso:

### Crear carpeta output

#### CMD

```
mkdir output
```

#### Powershell (Alternativa)

```
New-Item -ItemType Directory -Name output
```


### Generar el analizador léxico (Lexer): 

```
flex.exe -o .\output\lexer.yy.c .\lexer\lexer.l
```

### Generar el analizador sintáctico (Parser)

```
bison -d -o .\output\parser.tab.c .\parser\parser.y
```

### Generar el compilador

```
gcc -o .\bin\compiler.exe .\output\parser.tab.c .\output\lexer.yy.c
```

### Ejecutar compilador

#### CMD

```
.\bin\compilador.exe < .\tests\programa.txt
```

#### Powershell (Alternativa)

```
Get-Content .\tests\programa.txt | .\bin\compilador.exe
```

