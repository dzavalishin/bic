%{
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "tree.h"
#include "replparser.h"
#include "typename.h"
#define YY_NO_INPUT

static int colnum = 1;
static int linenum = 1;

#define REPL_USER_ACTION {repllloc.first_line = linenum;  \
        repllloc.first_column = colnum;                 \
        colnum=colnum+replleng;                         \
        repllloc.last_column=colnum - 1;                \
        repllloc.last_line = linenum;}


static char *sl_buf = NULL;

static void sl_begin(void)
{
    if (!sl_buf)
        sl_buf = malloc(1);

    sl_buf[0] = '\0';
}

static void sl_append_str(const char *s)
{
    char *buf, *oldbuf = sl_buf;
    buf = malloc(strlen(sl_buf) + strlen(s) + 1);
    buf[0] = '\0';
    strcat(buf, sl_buf);
    strcat(buf, s);
    sl_buf = buf;
    free(oldbuf);
}

static void sl_append_char(char c)
{
    char *s = malloc(2);
    s[0] = c;
    s[1] = '\0';
    sl_append_str(s);
    free(s);
}

static void lex_err(char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    exit(EXIT_FAILURE);
}

int replwrap(void) {
    return 1;
}
%}

%option prefix="repl" outfile="repllex.c"

L                               [a-zA-Z_]
D                               [0-9]
W                               [\ \t]
X                               [0-9A-F]

%x str_lit

%%
"__attribute__"[ \t]*"((".*"))" /* Ignore attributes */
"__restrict"                    /* Ignore builtin */
"__asm__"[ \t]*"(".*")"         /* Ignore asm stmts. */
"__extension__"                 /* Ignore gcc warning suppression
                                 * extension. */
"auto"				return AUTO;
"break"				return BREAK;
"case"				return CASE;
"char"				return CHAR;
"const"
"continue"			return CONTINUE;
"default"			return DEFAULT;
"do"				return DO;
"double"			return DOUBLE;
"else"				return ELSE;
"enum"				return ENUM;
"extern"			return EXTERN;
"float"				return FLOAT;
"for"				return FOR;
"goto"				return GOTO;
"if"				return IF;
"int"				return INT;
"long"				return LONG;
"register"			return REGISTER;
"return"			return RETURN;
"short"				return SHORT;
"signed"			return SIGNED;
"sizeof"			return SIZEOF;
"static"			return STATIC;
"struct"			return STRUCT;
"switch"			return SWITCH;
"typedef"			return TYPEDEF;
"union"				return UNION;
"unsigned"			return UNSIGNED;
"void"				return VOID;
"volatile"			return VOLATILE;
"while"				return WHILE;

{L}({L}|{D})*                   {repllval.string = strdup(repltext);
                                 if (is_typename(repltext))
                                     return TYPE_NAME;
                                 else
                                     return IDENTIFIER; }

-?[0-9]+                          mpz_init_set_str(repllval.integer, repltext, 10); return INTEGER;
-?[0-9]+\.[0-9]+                mpf_init_set_str(repllval.ffloat, repltext, 10); return FLOAT_CST;
0x{X}+                          repllval.string = strdup(repltext); return CONST_HEX;
\"                              { BEGIN str_lit; sl_begin(); }
<str_lit>[^\\"\n]*              { sl_append_str(repltext); }
<str_lit>\\n                    { sl_append_char('\n'); }
<str_lit>\\t                    { sl_append_char('\t'); }
<str_lit>\\[0-7]*               { sl_append_char(strtol(repltext+1, 0, 8)); }
<str_lit>\\[\\"]                { sl_append_char(repltext[1]); }
<str_lit>\"                     { repllval.string = strdup(sl_buf); BEGIN 0; return CONST_STRING; }
<str_lit>\\.                    { lex_err("bogus escape '%s' in string\n", repltext); }
<str_lit>\n                     { lex_err("newline in string\n"); }

[ \t\r]                         /* skip whitespace */
"\n"                            {linenum++; colnum = 1;}

"..."                           return ELLIPSIS;
"=="                            return EQUATE;
"!="                            return NOT_EQUATE;
"="                             return '=';
"("                             return '(';
")"                             return ')';
";"                             return ';';
","                             return ',';
"'"                             return '\'';
":"                             return ':';
"["                             return '[';
"]"                             return ']';
"."                             return '.';
"<="                            return LESS_OR_EQUAL;
">="                            return GREATER_OR_EQUAL;
"<"                             return '<';
">"                             return '>';
"!"                             return '!';
"+"                             return '+';
"-"                             return '-';
"*"                             return '*';
"/"                             return '/';
"%"                             return '%';
"{"                             return '{';
"}"                             return '}';
"&"                             return '&';
"<<"                            return SHIFT_LEFT;
">>"                            return SHIFT_RIGHT;
"++"                            return INC;
"--"                            return DEC;
"->"                            return PTR_ACCESS;

"&&"                            return BOOL_OP_AND;
"||"                            return BOOL_OP_OR;
%%