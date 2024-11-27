%{
#include "parser.tab.h"
#include <string.h> //Para strdup
%}

%%

"var"         { return VAR; }
"if"          { return IF; }
"else"        { return ELSE; }
"print"       { return PRINT; }
"true"        { return TRUE; }
"false"       { return FALSE; }
"while"       { return WHILE; }
"for"         { return FOR; }
"function"    { return FUNCTION; }  // Nuevo token para definir funciones
"return"      { return RETURN; }    // Nuevo token para retornar valores

[0-9]+        { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z_0-9]*   { yylval.sval = strdup(yytext); return IDENTIFIER; }

"=="          { return EQUAL; }
"!="          { return NOT_EQUAL; }
"<"           { return LESS; }
">"           { return GREATER; }
"<="          { return LESS_EQUAL; }
">="          { return GREATER_EQUAL; }
"="           { return ASSIGN; }
"("           { return '('; }
")"           { return ')'; }
"{"           { return '{'; }
"}"           { return '}'; }
";"           { return ';'; }

[ \t\n]+      { /* Ignorar espacios en blanco */ }
.             { return yytext[0]; }  // Devolver cualquier carácter no reconocido

%%

int yywrap() {
    return 1;
}