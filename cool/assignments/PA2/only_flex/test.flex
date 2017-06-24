%option noyywrap
%{

#define INT_CONST 1
#define TYPEID 2
#define OBJ_ID 2
#define DARROW 4


%}

INT_CONST	[0-9]+
TYPEID		^[A-Z]+[A-Za-z0-9_]*
OBJ_ID		^[a-z]+[A-Za-z0-9_]*
DARROW      =>
STRING		\"[A-Za-z]+\"

%%
{INT_CONST}		{
					printf("INTEGER\n" );
				}
{DARROW}		{ 
					printf("DARROW\n");
				}
{TYPEID}		{ 
					printf("TYPEID\n");
				}
{OBJ_ID}		{	printf("OBJ_ID\n"); }
{STRING}		{	printf("STRING\n"); }
[\n]			{	printf("NEWLINE\n"); }
.				{ }

%%

int main(int argc, char *argv[]) {
	if (argc > 1) {
		yyin = fopen( argv[1], "r" );
	}
	
 	yylex();
}