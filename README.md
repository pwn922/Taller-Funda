# Documentación: Taller de Fundamentos - Creación de un Compilador para un Lenguaje Propio

## Herramientas Utilizadas

### Bison

Bison es una herramienta diseñada para generar analizadores sintácticos en lenguajes de programación. Básicamente, transforma una descripción formal de la gramática de un lenguaje en código en C, que se encarga de analizar texto y verificar si cumple con las reglas definidas. 

Bison recibe una entrada, que es un archivo de gramática con extensión `.y`, donde escribimos las reglas sintácticas que debe seguir el compilador. Y entrega una salida, que corresponde a un archivo C que implementa el parser, que puede integrarse con otras partes del compilador para procesar el código.

### Flex

Flex es un generador de analizadores léxicos. Es una herramienta que convierte una descripción de patrones (expresiones regulares) en código C capaz de analizar cadenas y reconocer tokens del lenguaje fuente.

Flex recibe una entrada, que es un archivo con extensión `.l` que contiene las expresiones regulares para definir los tokens. Y entrega una salida que es un archivo C que implementa el análisis léxico.

### GCC (GNU Compiler Collection)

GCC es el compilador estándar para lenguajes como C y C++, y es utilizado para compilar el código generado por Bison y Flex. En este proyecto, GCC se utiliza para compilar los archivos generados por Bison y Flex en un ejecutable.

## Descripción del Lenguaje

### Variables

Las variables se declaran utilizando la palabra clave `var` seguida de un nombre de variable y un valor inicial.

```
var x = 10;
var y = x - 5;
```

#### Sintaxis personalizada

También es posible declarar variables utilizando una sintaxis diferente. La nueva sintaxis emplea la palabra clave `set` junto con el nombre de la variable, el operador `<-`, y el `valor`:

```
set c <- 5;
print(c);
```


### Condiciones

El lenguaje permite evaluar condiciones lógicas utilizando if y else. Estas estructuras condicionales permiten ejecutar diferentes bloques de código según si la condición evaluada es verdadera o falsa.

```
var a = 10;
var b = 20;
var mayor = 0;
var menor = 0;

if (a > b) {
    mayor = a;
    menor = b;
} else {
    mayor = b;
    menor = a;
}
print(mayor);
print(menor);
```

### Bucles

Los bucles permiten repetir bloques de código mientras se cumplan ciertas condiciones. El lenguaje admite los bucles while y for para manejar iteraciones.

#### While

El bucle `while` ejecuta un bloque de código repetidamente mientras la condición especificada sea verdadera. 

```
var x = 0;
while (x < 10) {
    print(x);
    x = x + 1;
}
```

### for

El bucle `for` permite iterar un número conocido de veces, especificando en una sola línea la inicialización de la variable, la condición para continuar, y la actualización tras cada iteración.

```
for (var j = 0; j < 5; j = j + 1) {
    print(j);
}
```

### Funciones

Las funciones son bloques de código reutilizables que permiten organizar y simplificar el desarrollo. En el lenguaje, una función se define utilizando la palabra clave `function`, seguida del nombre de la función, parámetros entre paréntesis, y el bloque de código entre llaves.

```
function suma(a, b) {
    return a + b;
}
var resultado;
resultado = suma(5, 7);
print(resultado);
```

## Fases del Compilador

### Análisis Léxico (Flex)

Se uso Flex para desarrollar el analizador léxico en un archivo `lexer.l` donde se definieron las expresiones regulares para reconocer los tokens del lenguaje. El analizador léxico genera un archivo en C que realiza este análisis.

El archivo `lexer.l` tiene una estructura dividida en tres secciones principales:

1. Definiciones: Aquí se declaran macros o patrones comunes que serán utilizados posteriormente.
2. Reglas: Se definen las expresiones regulares y se asocian con las acciones que el analizador debe realizar al encontrar coincidencias.
3. Código C adicional (opcional): Se puede incluir código auxiliar en C que será necesario para el análisis o para la interacción con otras partes del compilador.

### Análisis Sintáctico (Bison)

Se uso Bison para definir la gramática del lenguaje en un archivo `parser.y` y generar un analizador sintáctico. Este analizador produce un árbol de sintaxis abstracta (AST). Cada nodo del árbol corresponde a una construcción del lenguaje, como expresiones, declaraciones o sentencias. 

El archivo `parser.y` tiene una estructura dividida en varias secciones:

1. Definición de la gramática: Aquí se definen las reglas de producción que determinan cómo se forman las construcciones del lenguaje, como asignaciones, condicionales, bucles, etc. Estas reglas procesan las entradas y las convierten en nodos del AST.
2. Representación del AST: El AST se representa mediante la estructura ASTNode, que puede tener varios tipos de nodos, incluyendo:
    - Nodo de número: Representa valores numéricos constantes.
    - Nodo de identificador: Representa nombres de variables.
    - Nodo de operación binaria: Representa operaciones matemáticas o lógicas.
    - Nodo de asignación: Representa una asignación de valor a una variable.
    - Nodo condicional (`if`): Representa sentencias condicionales con soporte para `else`
    - Nodo de bucle `while`: Representa un bucle condicional
    - Nodo de bucle `for`: Representa un bucle con inicialización, condición e incremento.
    - Nodo de bloque: Representa un conjunto de sentencias agrupadas.
    - Nodo de impresión: Representa una sentencia de impresión (`print`)
    - Nodo de función: Representa la declaración de funciones.
        - Nodo de llamada a función: Representa una invocación de función
        - Nodo de retorno: Representa una sentencia return con una expresión opcional.
    - Funciones de creación de nodos: Varias funciones, como `create_for_node`, `create_number_node`, `create_identifier_node`, `create_function_node`, entre otras, son utilizadas para crear nuevos nodos en el AST.
3. Gestión de memoria: Cada nodo del AST es asignado dinámicamente con malloc, y se ha implementado la función `free_ast` para liberar recursivamente todos los nodos del AST, evitando pérdidas de memoria.
4. Evaluación de expresiones: La función `evaluate_ast` evalúa recursivamente el AST, interpretando las expresiones representadas por cada nodo. Esta función maneja nodos de tipo número, identificador, operaciones binarias, asignaciones y estructuras de control como `if`, `while` y `for`. Además, soporta operaciones básicas como suma, resta, multiplicación, división, comparaciones (`==`, `!=`, `>`, `<`) y operaciones lógicas.
5. Gestión de variables: Se utiliza un arreglo global variables para almacenar los nombres de las variables y sus valores correspondientes. Las funciones `get_variable_value` y `set_variable_value` se encargan de gestionar el acceso y la actualización de las variables.
6. Ejecución: La función `execute_ast` se encarga de ejecutar las sentencias del AST, procesando asignaciones, sentencias de impresión, condicionales, bucles y bloques de código.
7. Grammática de Bison: En el archivo `parser.y`, Bison define la gramática y cómo se deben parsear las entradas para construir los nodos del AST.
8. Programa: La regla principal procesa las líneas del programa.

## Instrucciones de uso:

### Crear carpeta output

```
mkdir output && mkdir bin
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
gcc -o .\bin\compilador.exe .\output\parser.tab.c .\output\lexer.yy.c
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

