/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}
%option  yylineno
%x STRING DASH_COMMENT COMMENT STRING_ERROR


/*
 * Define names for regular expressions here.
 */
 
CLASS		?i:class
ELSE		?i:else
FI			?i:fi
IF			?i:if
IN			?i:in
INHERITS 	?i:inherits
LET 		?i:let
LOOP		?i:loop
POOL		?i:pool
THEN		?i:then
WHILE		?i:while
CASE		?i:case
ESAC		?i:esac
OF			?i:of
DARROW		=>
NEW			?i:new
ISVOID		?i:isvoid

CHAR		[A-Za-z]
DIGIT		[0-9]

INT_CONST	{DIGIT}+

FALSE		f(?i:alse)
TRUE		t(?i:rue)
TYPEID		[A-Z]+[A-Za-z0-9_]*
OBJECTID	[a-z]+[A-Za-z0-9_]*
ASSIGN		assign
NOT			?i:not
LE			le
ERROR		error
LET_STMT	let
WHITESPACE	[ \n\f\r\t\v]




%%

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  * escaped null char in a string
  *	long strings with escaped characters
  * null char in string [submission crashed on this input]
  * null and unescaped newline in string
  * unterminated string
  */
  
<INITIAL>\"					{ 
								strcpy(string_buf, "");
								BEGIN(STRING);
							}
<STRING>\"					{
								curr_lineno = yylineno;
								cool_yylval.symbol = stringtable.add_string(string_buf);
								BEGIN(INITIAL);
				    			return STR_CONST;
							}
<STRING>\\b					{
								curr_lineno = yylineno;
								if (strlen(string_buf) + 1 >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								strcat(string_buf, "\b");							
							}
<STRING>\\t					{
								curr_lineno = yylineno;
								if (strlen(string_buf) + 1 >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								strcat(string_buf, "\t");
							}							
<STRING>\\n					{
								curr_lineno = yylineno;
								if (strlen(string_buf) + 1 >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								strcat(string_buf, "\n");
							}
<STRING>\\f					{
								curr_lineno = yylineno;
								if (strlen(string_buf) + 1 >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								strcat(string_buf, "\f");
							}
<STRING>\\.					{
								curr_lineno = yylineno;
								if (strlen(string_buf) + 1 >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								// printf("escaped char: %s\n", yytext);
								strcat(string_buf, yytext + 1);
							}							
<STRING>\\\n				{
								curr_lineno = yylineno;
								if (strlen(string_buf) + 1 >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								strcat(string_buf, "\n");
							}		
<STRING>\n					{
								curr_lineno = yylineno;
								cool_yylval.error_msg = "Unterminated string constant";
								BEGIN(INITIAL);
								return ERROR;
							}							
<STRING>\\\x00				{
								curr_lineno = yylineno;
								cool_yylval.error_msg = "String cannot contain escaped null byte";
								BEGIN(STRING_ERROR);
								return ERROR;								
							}
<STRING>\x00				{
								curr_lineno = yylineno;
								cool_yylval.error_msg = "String contains null character";
								BEGIN(STRING_ERROR);
								return ERROR;								
							}


<STRING>[^"\\\n\x00]+		{
								curr_lineno = yylineno;
								if (strlen(string_buf) + strlen(yytext) >= MAX_STR_CONST) {
									cool_yylval.error_msg = "String constant too long";
									BEGIN(STRING_ERROR);
									return ERROR;
								}
								// printf("yytext: %s\n", yytext + 1);
								strcat(string_buf, yytext);								
							}
<STRING><<EOF>>				{
								curr_lineno = yylineno;
								cool_yylval.error_msg = "String cannot contain EOF";
								BEGIN(INITIAL);
								return ERROR;
							}
<STRING_ERROR>\n			{
								BEGIN(INITIAL);
							}							
<STRING_ERROR>\"			{
								BEGIN(INITIAL);
							}
<STRING_ERROR>\\\n			{
								// do nothing
							}							
<STRING_ERROR>[^"\n]		{
								// do nothing
							}
<STRING_ERROR><<EOF>>		{
								BEGIN(INITIAL);
							}																					


 /*
  * COMMENTS
  */							

<INITIAL>--					{								
								curr_lineno = yylineno;
								BEGIN(DASH_COMMENT);
							}
<DASH_COMMENT>\n			{								
								curr_lineno = yylineno;
								BEGIN(INITIAL);
							}
<DASH_COMMENT><<EOF>>		{		
								printf("EOF dash_comment");						
								curr_lineno = yylineno;
								BEGIN(INITIAL);
								
							}
<DASH_COMMENT>[^\n]+		{
								printf("dash_comment\n");
								// DO nothing								
							}

<INITIAL>(\(\*)				{
								curr_lineno = yylineno;
								BEGIN(COMMENT);
							}
<INITIAL>(\*\))				{
								curr_lineno = yylineno;
								cool_yylval.error_msg = "Unmatched *)";
								BEGIN(INITIAL);
							}
<COMMENT>(\*\))|(\n)		{
								curr_lineno = yylineno;
								BEGIN(INITIAL);
							}
<COMMENT>[^\n]				{
								
							}

							
 /*
  * KEYWORDS
  */
							

<INITIAL>{CLASS}      		{ curr_lineno = yylineno; return CLASS; }
<INITIAL>{ELSE}				{
								curr_lineno = yylineno;
								return ELSE;
							}
<INITIAL>{FI}				{
								curr_lineno = yylineno;
								return FI;
							}
<INITIAL>{IF}				{
								curr_lineno = yylineno;
								return IF;
							}
<INITIAL>{IN}				{
								curr_lineno = yylineno;
								return IN;
							}
<INITIAL>{INHERITS}			{
								curr_lineno = yylineno;
								return INHERITS;
							}
<INITIAL>{LET}				{
								curr_lineno = yylineno;
								return LET;
							}
<INITIAL>{LOOP}				{
								curr_lineno = yylineno;
								return LOOP;
							}
<INITIAL>{POOL}				{
								curr_lineno = yylineno;
								return POOL;
							}
<INITIAL>{THEN}				{
								curr_lineno = yylineno;
								return THEN;
							}
<INITIAL>{WHILE}			{
								curr_lineno = yylineno;
								return WHILE;
							}
<INITIAL>{CASE}				{
								curr_lineno = yylineno;
								return CASE;
							}
<INITIAL>{ESAC}				{
								curr_lineno = yylineno;
								return ESAC;
							}
<INITIAL>{OF}				{
								curr_lineno = yylineno;
								return OF;
							}
<INITIAL>{NEW}				{
								curr_lineno = yylineno;
								return NEW;
							}
<INITIAL>{ISVOID}				{
								curr_lineno = yylineno;
								return ISVOID;
							}
<INITIAL>{TRUE}				{
								curr_lineno = yylineno;
								cool_yylval.boolean = true;
								return BOOL_CONST;
							}
<INITIAL>{FALSE}			{
								curr_lineno = yylineno;
								cool_yylval.boolean = false;
								return BOOL_CONST;
							}							
<INITIAL>{TYPEID}			{ 
								curr_lineno = yylineno;
								cool_yylval.symbol = stringtable.add_string(yytext);
								return TYPEID;
							}
<INITIAL>{OBJECTID}			{ 
								curr_lineno = yylineno;
								cool_yylval.symbol = stringtable.add_string(yytext);
								return OBJECTID; 
							}								
<INITIAL>{ASSIGN}			{
								curr_lineno = yylineno;
								return ASSIGN;
							}
<INITIAL>{NOT}				{
								curr_lineno = yylineno;
								return NOT;
							}
<INITIAL>{LE}				{
								curr_lineno = yylineno;
								return LE;
							}
<INITIAL>{ERROR}			{
								curr_lineno = yylineno;
								return ERROR;
							}																																			
<INITIAL>{LET_STMT}			{
								curr_lineno = yylineno;
								return LET_STMT;
							}																																			


<INITIAL>{INT_CONST}		{ 
								curr_lineno = yylineno;
								cool_yylval.symbol = inttable.add_string(yytext);
								return INT_CONST; 
							}
							
							
							
<INITIAL>{DARROW}			{ curr_lineno = yylineno; return DARROW; }
<INITIAL>"<-"		    {  curr_lineno = yylineno;  return ASSIGN;    } 	
<INITIAL>"+" 			{  curr_lineno = yylineno;  return int('+');  }
<INITIAL>"/"		    {  curr_lineno = yylineno;  return int('/');  }
<INITIAL>"-"			{  curr_lineno = yylineno;  return int('-');  }
<INITIAL>"*"			{  curr_lineno = yylineno;  return int('*');  }
<INITIAL>"="		    {  curr_lineno = yylineno;  return int('=');  }
<INITIAL>"<"		    {  curr_lineno = yylineno;  return int('<');  }
<INITIAL>"<="			{  curr_lineno = yylineno;  return LE;        }
<INITIAL>"."		    {  curr_lineno = yylineno;  return int('.');  }
<INITIAL>"~"			{  curr_lineno = yylineno;  return int('~');  }
<INITIAL>","			{  curr_lineno = yylineno;  return int(',');  }
<INITIAL>";"			{  curr_lineno = yylineno;  return int(';');  }
<INITIAL>":"			{  curr_lineno = yylineno;  return int(':');  }
<INITIAL>"("			{  curr_lineno = yylineno;  return int('(');  }
<INITIAL>")"		    {  curr_lineno = yylineno;  return int(')');  }
<INITIAL>"@"			{  curr_lineno = yylineno;  return int('@');  }
<INITIAL>"{"			{  curr_lineno = yylineno;  return int('{');  }
<INITIAL>"}"			{  curr_lineno = yylineno;  return int('}');  }

<INITIAL>{WHITESPACE}		{}




<INITIAL>.					{ 
								curr_lineno = yylineno;
								cool_yylval.error_msg = yytext;
								return ERROR;
							}




 /*
  *  The multiple-character operators.
  */

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */





%%
