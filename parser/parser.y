%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
void yyerror(const char *s);
int yylex(void);

#define MAX_VARIABLES 100
#define MAX_FUNCTIONS 100
#define MAX_PARAMETERS 10

//Estructura para variables
typedef struct {
    char *name;
    int value;
} Variable;

//Estructura para funciones
typedef struct {
    char *name;
    struct ASTNode **parameters; // Lista de parámetros como nodos
    int param_count;
    struct ASTNode *body;
} Function;

Variable variables[MAX_VARIABLES];
int var_count = 0;

Function functions[MAX_FUNCTIONS];
int func_count = 0;

typedef enum {
    NODE_TYPE_NUMBER,
    NODE_TYPE_IDENTIFIER,
    NODE_TYPE_BINARY_OP,
    NODE_TYPE_ASSIGN,
    NODE_TYPE_IF,
    NODE_TYPE_BLOCK,
    NODE_TYPE_PARAMETER,
    NODE_TYPE_RETURN,
    NODE_TYPE_PRINT,
    NODE_TYPE_WHILE,
    NODE_TYPE_FOR,
    NODE_TYPE_STRING,
    NODE_TYPE_FUNCTION,
    NODE_TYPE_CALL,
    NODE_TYPE_VARIABLE,
} ASTNodeType;

typedef struct ASTNode {
    ASTNodeType type;
    union {
        int value; // Para NODE_TYPE_NUMBER
        char *name; // Para NODE_TYPE_IDENTIFIER y otros que lo usen
        struct {
            struct ASTNode **parameters;
            int param_count;
        } parameter_list;
        struct {
            struct ASTNode *expression;
        } return_stmt;
        struct {
            struct ASTNode **args;
            int arg_count;
            char *name;
        } call;
        struct {
            char *name;
            struct ASTNode **parameters;
            int param_count;
            struct ASTNode *body;
        } function;
        struct {
            char *name;
            struct ASTNode *value;
        } assignment;
        struct {
            struct ASTNode *condition;
            struct ASTNode *true_block;
            struct ASTNode *false_block;
        } if_stmt;
        struct {
            struct ASTNode **statements;
            int statement_count;
        } block;
        struct {
            char op;
            struct ASTNode *left;
            struct ASTNode *right;
        } binary_op;
        struct ASTNode *expression; // Para NODE_TYPE_PRINT
        struct {
            struct ASTNode *condition;
            struct ASTNode *body;
        } while_stmt;
        struct {
            struct ASTNode *init;
            struct ASTNode *condition;
            struct ASTNode *increment;
            struct ASTNode *body;
        } for_stmt;
        char *string_value; // Para NODE_TYPE_STRING
    };
} ASTNode;
Function *get_function(const char *name);  // Declarar funciones
int evaluate_ast(ASTNode *node);
void free_ast(ASTNode *node);
void add_function(Function func);


int node_list_count(ASTNode **list) {
    int count = 0;
    while (list[count] != NULL) count++;
    return count;
}

Function *get_function(const char *name) {
    for (int i = 0; i < func_count; i++) {
        if (strcmp(functions[i].name, name) == 0) {
            return &functions[i];
        }
    }
    return NULL;
}

void add_function(Function func) {
    if (func_count >= MAX_FUNCTIONS) {
        fprintf(stderr, "Error: Número máximo de funciones alcanzado.\n");
        return;
    }
    functions[func_count++] = func;
}

// Creación de nodos para funciones y sus llamadas
ASTNode *create_function_node(char *name, ASTNode **parameters, int param_count, ASTNode *body) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_FUNCTION;
    node->function.name = strdup(name);
    node->function.parameters = parameters;
    node->function.param_count = param_count;
    node->function.body = body;
    return node;
}

ASTNode **create_node_list(ASTNode *first) {
    ASTNode **list = malloc(2 * sizeof(ASTNode *));
    list[0] = first;
    list[1] = NULL; // Terminador para el arreglo
    return list;
}

ASTNode **append_node_list(ASTNode **list, ASTNode *new_node) {
    int count = 0;
    while (list[count] != NULL) { // Calcula el tamaño actual de la lista
        count++;
    }
    list = realloc(list, (count + 2) * sizeof(ASTNode *)); // +1 para el nuevo nodo, +1 para NULL
    list[count] = new_node;
    list[count + 1] = NULL; // Actualiza el terminador
    return list;
}

ASTNode *create_variable_node(char *name) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_VARIABLE;
    node->name = strdup(name);
    return node;
}

int create_variable(char *name) {
    // Verificar si la variable ya existe
    for (int i = 0; i < var_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            // Si ya existe, devolver su valor
            return variables[i].value;
        }
    }

    // Si no existe, agregar la nueva variable al arreglo
    if (var_count < 100) {
        variables[var_count].name = strdup(name);  // Copiar el nombre de la variable
        variables[var_count].value = 0;  // Inicializar el valor de la nueva variable a 0
        var_count++;
        return 0;  // Retornar el valor de la nueva variable (0 por defecto)
    } else {
        // Si el arreglo está lleno, retornar un valor especial (error)
        fprintf(stderr, "Error: No hay espacio suficiente para crear más variables.\n");
        return -1;
    }
}

ASTNode *create_call_node(char *name, ASTNode **args, int arg_count) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_CALL;
    node->call.name = strdup(name);
    node->call.args = args;
    node->call.arg_count = arg_count;
    return node;
}

// Creación de nodo para return
ASTNode *create_return_node(ASTNode *expression) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_RETURN;
    node->return_stmt.expression = expression;
    return node;
}

ASTNode *create_for_node(ASTNode *init, ASTNode *condition, ASTNode *increment, ASTNode *body) {
    
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_FOR;
    node->for_stmt.init = init;
    node->for_stmt.condition = condition;
    node->for_stmt.increment = increment;
    node->for_stmt.body = body;
    return node;
}

// Función para crear un nodo de número
ASTNode *create_number_node(int value) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_NUMBER;
    node->value = value;
    return node;
}

// Función para crear un nodo de identificador
ASTNode *create_identifier_node(char *name) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_IDENTIFIER;
    node->name = strdup(name);
    return node;
}

// Función para crear un nodo de operación binaria
ASTNode *create_binary_op_node(char op, ASTNode *left, ASTNode *right) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_BINARY_OP;
    node->binary_op.op = op;
    node->binary_op.left = left;
    node->binary_op.right = right;
    return node;
}

// Función para crear un nodo de asignación
ASTNode *create_assignment_node(char *name, ASTNode *value) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_ASSIGN;
    node->assignment.name = strdup(name);
    node->assignment.value = value;
    return node;
}

// Función para crear un nodo IF
ASTNode *create_if_node(ASTNode *condition, ASTNode *true_block, ASTNode *false_block) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_IF;
    node->if_stmt.condition = condition;
    node->if_stmt.true_block = true_block;
    node->if_stmt.false_block = false_block;
    return node;
}

// Función para crear un nodo de impresión
ASTNode *create_print_node(ASTNode *expression) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_PRINT;
    node->expression = expression;
    return node;
}

// Función para crear un nodo de bloque
ASTNode *create_block_node(ASTNode **statements, int count) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_BLOCK;
    node->block.statements = statements;
    node->block.statement_count = count;
    return node;
}

ASTNode *create_while_node(ASTNode *condition, ASTNode *body) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_WHILE;
    node->while_stmt.condition = condition;
    node->while_stmt.body = body;
    return node;
}

void free_ast(ASTNode *node) {
    if (node == NULL) return;
    // fprintf(stderr, "Liberando nodo de tipo: %d\n", node->type);

    switch (node->type) {
        case NODE_TYPE_NUMBER:
            break;
        case NODE_TYPE_IDENTIFIER:
            free(node->name);
            break;
        case NODE_TYPE_BINARY_OP:
            free_ast(node->binary_op.left);
            free_ast(node->binary_op.right);
            break;
        case NODE_TYPE_ASSIGN:
            free(node->assignment.name);
            free_ast(node->assignment.value);
            break;
        case NODE_TYPE_IF:
            free_ast(node->if_stmt.condition);
            free_ast(node->if_stmt.true_block);
            free_ast(node->if_stmt.false_block);
            break;
        case NODE_TYPE_BLOCK:
            for (int i = 0; i < node->block.statement_count; i++) {
                free_ast(node->block.statements[i]);
            }
            free(node->block.statements);
            break;
        case NODE_TYPE_PRINT:
            free_ast(node->expression);
            break;
        case NODE_TYPE_WHILE:
            free_ast(node->while_stmt.condition); // Liberar condición del while
            free_ast(node->while_stmt.body);      // Liberar cuerpo del while
            break;
        case NODE_TYPE_FOR:
            free_ast(node->for_stmt.init);
            free_ast(node->for_stmt.condition);
            free_ast(node->for_stmt.increment);
            free_ast(node->for_stmt.body);
            break;
        case NODE_TYPE_CALL:
        free(node->call.name);
        for (int i = 0; i < node->call.arg_count; i++) {
            free_ast(node->call.args[i]);
        }
    free(node->call.args);
    break;
        case NODE_TYPE_RETURN:
        free_ast(node->return_stmt.expression);
        break;
        case NODE_TYPE_FUNCTION:
        free(node->function.name);
        for (int i = 0; i < node->function.param_count; i++) {
            free_ast(node->function.parameters[i]);
        }
        free_ast(node->function.body);
        free(node->function.parameters);
        break;

        case NODE_TYPE_VARIABLE:
        free(node->name);
        break;

        case NODE_TYPE_STRING:
            free(node->string_value); // Liberar cadena
            break;

    
        default:
            fprintf(stderr, "Error: Unknown ASTNode type.\n", node->type);
            break;
    }
    free(node);
}

int get_variable_value(char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            return variables[i].value;
        }
    }
    return 0;
}

void set_variable_value(char *name, int value) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            variables[i].value = value; // Update existing variable
            return;
        }
    }
    // If the variable does not exist, add it to the list
    variables[var_count].name = strdup(name);
    variables[var_count].value = value;
    var_count++;
}

// Evaluación de funciones
int evaluate_function_call(ASTNode *call_node) {
    Function *func = get_function(call_node->call.name);
    fprintf(stderr, "Debug: La función '%s' esperaba %d argumentos y recibió %d.\n",
        call_node->call.name, func->param_count, call_node->call.arg_count);
    if (!func) {
        fprintf(stderr, "Error: Función '%s' no definida.\n", call_node->call.name);
        return 0;
    }
    if (func->param_count != call_node->call.arg_count) {
        fprintf(stderr, "Error: Número incorrecto de argumentos para '%s'.\n", func->name);
        return 0;
    }

    // Depuración: lista de argumentos
    // for (int i = 0; i < func->param_count; i++) {
    // fprintf(stderr, "Parámetro %d: %s\n", i, func->parameters[i]->name);
    // }
    
    // for (int i = 0; i < call_node->call.arg_count; i++) {
    //    fprintf(stderr, "  Argumento %d: %d\n", i, evaluate_ast(call_node->call.args[i]));
    // }

    // fprintf(stderr, "Debug: Evaluando llamada a '%s' con %d argumentos.\n", call_node->call.name, call_node->call.arg_count);

    // Evaluar argumentos y asignar a parámetros
    for (int i = 0; i < func->param_count; i++) {
        int arg_value = evaluate_ast(call_node->call.args[i]);
        set_variable_value(func->parameters[i]->name, arg_value);
    }

    // Ejecutar el cuerpo de la función
    return evaluate_ast(func->body);
}

int evaluate_ast(ASTNode *node) {
    if (node == NULL) {
        return 0; // Retorna 0 si el nodo es NULL.
    }

    // fprintf(stderr, "Evaluando nodo de tipo: %d\n", node->type);

    switch (node->type) {
        case NODE_TYPE_NUMBER:
            return node->value;

        case NODE_TYPE_IDENTIFIER:
            return get_variable_value(node->name);

        case NODE_TYPE_BINARY_OP: {
            int left_value = evaluate_ast(node->binary_op.left);
            int right_value = evaluate_ast(node->binary_op.right);
            switch (node->binary_op.op) {
                case '+': return left_value + right_value;
                case '-': return left_value - right_value;
                case '*': return left_value * right_value;
                case '/':
                    if (right_value == 0) {
                        fprintf(stderr, "Error: División por cero.\n");
                        return 0;
                    }
                    return left_value / right_value;
                case '=': return left_value == right_value;
                case '!': return left_value != right_value;
                case '<': return left_value < right_value;
                case '>': return left_value > right_value;
                case 'l': return left_value <= right_value;
                case 'g': return left_value >= right_value;
                default:
                    fprintf(stderr, "Error: Operador desconocido '%c'.\n", node->binary_op.op);
                    return 0;
            }
        }


        case NODE_TYPE_ASSIGN: {
            int value = evaluate_ast(node->assignment.value);
            set_variable_value(node->assignment.name, value);
            return value;
        }

        case NODE_TYPE_VARIABLE:
            return get_variable_value(node->name);
        
        case NODE_TYPE_FUNCTION:
            // fprintf(stderr, "Error: Evaluación directa de una función no implementada.\n");
            return 0;

        case NODE_TYPE_IF: {
            int condition_value = evaluate_ast(node->if_stmt.condition);
            if (condition_value) {
                return evaluate_ast(node->if_stmt.true_block);
            } else {
                return evaluate_ast(node->if_stmt.false_block);
            }
        }

        case NODE_TYPE_WHILE: {
            int result = 0;
            while (evaluate_ast(node->while_stmt.condition)) {
                result = evaluate_ast(node->while_stmt.body);
            }
            return result;
        }

        case NODE_TYPE_FOR: {
            evaluate_ast(node->for_stmt.init);
            
            int result = 0;
            while (evaluate_ast(node->for_stmt.condition)) {
                result = evaluate_ast(node->for_stmt.body); // Ejecutar el cuerpo del bucle
                evaluate_ast(node->for_stmt.increment); // Ejecutar la actualización
            }
            return result;
        }

        case NODE_TYPE_BLOCK: {
            int result = 0;
            for (int i = 0; i < node->block.statement_count; i++) {
                result = evaluate_ast(node->block.statements[i]);
            }
            return result;
        }

        case NODE_TYPE_CALL:
            return evaluate_function_call(node);
        case NODE_TYPE_RETURN:
            return evaluate_ast(node->return_stmt.expression);

        default:
            fprintf(stderr, "Error: Tipo de nodo desconocido.\n", node->type);
            return 0;
    }
}

void execute_ast(ASTNode *node) {
    if (node == NULL) return;

    switch (node->type) {
        case NODE_TYPE_ASSIGN:
            set_variable_value(node->assignment.name, evaluate_ast(node->assignment.value));
            break;

        case NODE_TYPE_IF:
            if (evaluate_ast(node->if_stmt.condition)) {
                execute_ast(node->if_stmt.true_block);
            } else if (node->if_stmt.false_block) {
                execute_ast(node->if_stmt.false_block);
            }
            break;

        case NODE_TYPE_PRINT:
            printf("%d\n", evaluate_ast(node->expression));
            break;

        case NODE_TYPE_BLOCK:
            for (int i = 0; i < node->block.statement_count; i++) {
                execute_ast(node->block.statements[i]);
            }
            break;

        case NODE_TYPE_WHILE: {
            while (evaluate_ast(node->while_stmt.condition)) {
                execute_ast(node->while_stmt.body);
            }
            break;
        }

        case NODE_TYPE_FOR: {
            execute_ast(node->for_stmt.init); // Ejecutar inicialización
            while (evaluate_ast(node->for_stmt.condition)) { // Evaluar condición
                execute_ast(node->for_stmt.body); // Ejecutar cuerpo
                execute_ast(node->for_stmt.increment); // Ejecutar incremento
            }
            break;
        }

        default:
            break;
    }
}

%}

%union {
    int ival;
    char *sval;
    struct ASTNode *node;
    struct ASTNode **node_list;
}

%token <sval> IDENTIFIER
%token <ival> NUMBER
%token FUNCTION RETURN
%token WHILE FOR IF ELSE PRINT TRUE FALSE VAR
%token EQUAL NOT_EQUAL LESS GREATER LESS_EQUAL GREATER_EQUAL ASSIGN SET LEFT_ARROW

%type <node> expression line block statement_list program function_decl call
%type <node_list> args

%left EQUAL NOT_EQUAL LESS GREATER LESS_EQUAL GREATER_EQUAL
%left '+' '-'
%left '*' '/'

%start program

%%

program:
    /* vacío */ { /* No se crea un AST para un programa vacío */ }
    | program line {
        execute_ast($2);
        free_ast($2);
    }
    | function_decl { /* Nueva regla para funciones */ }
;

line:
    VAR IDENTIFIER ';' { $$ = create_variable_node($2); }
    | SET IDENTIFIER ';' { $$ = create_variable_node($2); }
    | VAR IDENTIFIER ASSIGN expression ';' { $$ = create_assignment_node($2, $4); }
    | IDENTIFIER ASSIGN expression ';' { $$ = create_assignment_node($1, $3); }
    | SET IDENTIFIER LEFT_ARROW expression ';' { $$ = create_assignment_node($2, $4); }
    | call ';' { execute_ast($1); free_ast($1); }
    | RETURN expression ';' { $$ = create_return_node($2); }
    | IF '(' expression ')' block
      {
          $$ = create_if_node($3, $5, NULL); // Caso sin bloque else
      }
    | IF '(' expression ')' block ELSE block
      {
          $$ = create_if_node($3, $5, $7); // Caso con bloque else
      }
    | WHILE '(' expression ')' block
      {
          $$ = create_while_node($3, $5);
      }
    | FOR '(' VAR IDENTIFIER ASSIGN expression ';' expression ';' IDENTIFIER ASSIGN expression ')' block {
        ASTNode *init = create_assignment_node($4, $6); 
        ASTNode *increment = create_assignment_node($4, $12);
        $$ = create_for_node(init, $8, increment, $14);
    }
    | PRINT '(' expression ')' ';' { $$ = create_print_node($3); }
;

block:
    '{' statement_list '}' { $$ = create_block_node($2->block.statements, $2->block.statement_count); }
;

statement_list:
    line  {
        $$ = (ASTNode *)malloc(sizeof(ASTNode));
        $$->type = NODE_TYPE_BLOCK;
        $$->block.statements = (ASTNode **)malloc(sizeof(ASTNode *));
        $$->block.statements[0] = $1;
        $$->block.statement_count = 1;
    }
    | statement_list line  {
        int count = $1->block.statement_count;
        $1->block.statements = (ASTNode **)realloc($1->block.statements, sizeof(ASTNode *) * (count + 1));
        $1->block.statements[count] = $2;
        $1->block.statement_count++;
        $$ = $1;
    }
;

expression:
    NUMBER  { $$ = create_number_node($1); }
    | IDENTIFIER  { $$ = create_identifier_node($1); }
    | call { $$ = $1; }
    | expression '+' expression   { $$ = create_binary_op_node('+', $1, $3); }
    | expression '-' expression   { $$ = create_binary_op_node('-', $1, $3); }
    | expression '*' expression   { $$ = create_binary_op_node('*', $1, $3); }
    | expression '/' expression   { $$ = create_binary_op_node('/', $1, $3); }
    | expression EQUAL expression { $$ = create_binary_op_node('=', $1, $3); }
    | expression NOT_EQUAL expression { $$ = create_binary_op_node('!', $1, $3); }
    | expression LESS expression  { $$ = create_binary_op_node('<', $1, $3); }
    | expression GREATER expression { $$ = create_binary_op_node('>', $1, $3); }
    | expression LESS_EQUAL expression { $$ = create_binary_op_node('l', $1, $3); }
    | expression GREATER_EQUAL expression { $$ = create_binary_op_node('g', $1, $3); }
    | '(' expression ')'   { $$ = $2; }
;

function_decl:
    FUNCTION IDENTIFIER '(' args ')' block {
        $$ = create_function_node($2, $4, node_list_count($4), $6);
        Function func = { strdup($2), $4, node_list_count($4), $6 };
        add_function(func);
    }
;

call:
    IDENTIFIER '(' args ')' {
        $$ = create_call_node($1, $3, node_list_count($3));
    }
;

args:
    expression { $$ = create_node_list($1); }
    | args ',' expression { $$ = append_node_list($1, $3); }
;

%%

// Manejo de errores
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

// Función principal
int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yyparse();
    return 0;
}