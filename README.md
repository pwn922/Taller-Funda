# Taller de Fundamentos: Creación de un Compilador para un Lenguaje Propio

## Documentación

### Variables

## Instrucciones de uso:

### Generar el analizador léxico (Lexer): 

```
flex.exe -o .\lexer\lexer.yy.c .\lexer\lexer.l
```

### Generar el analizador sintáctico (Parser)

```
bison -d -o .\parser\parser.tab.c .\parser\parser.y
```

### Generar el compilador

```
gcc -o .\bin\compiler parser.tab.c lexer.yy.c
```

### Ejecutar compilador

```
.\bin\compiler.exe .\programa.txt
```