/* �ק鷺�e
symbolTable�s�W���e: type�H��content
�NsymbolTable���iyacc�ɮ�
�s�W����rREAD


*/


	/*========= definition ==========*/
%{	
	/*C code*/
	//#include<stdio.h>
	
	#include"y.tab.h"
	#define LIST strcat(buf,yytext) //���buffer��
	//#define token(t) {LIST; printf("<%s>\n",t);} 
	#define token(t) {LIST;}
	//���buffer�̨æL�X��token
	#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);}
	//���token?
	//#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s);}
	#define tokenString(t,s) {LIST;}
	//�r��token?
	#define strLIST strcat(strbuf,yytext)
	
	
	extern int linenum;//1��0
	char buf[256];//����{���X 
	char strbuf[256];
	//extern struct symbolTable;
	extern struct symbolTable *st0[20];
	extern int curid;
	
%}
/* �o�̧i�Dflex�u�nŪ����J���ɮס]���ݭn��L�ɮס^%option noyywrap*/

%x STRING
%x COMMENT

newL \n|\r\n
%%
	/***=========== rules ============***/


"("		{token("(");return '(';}
")"		{token(")");return ')';}
","		{token(",");return ',';}
":"		{token(":");return ':';}
";"		{token(";");return ';';}
"["		{token("[");return '[';}
"]"		{token("]");return ']';}

"{"		{token("{");return '{';}
"}"		{token("}");return '}';}

"+"		{token("+");return '+';}
"-"		{token("-");return '-';}
"*"		{token("*");return '*';}
"/"		{token("/");return '/';}
"^"		{token("^");return '^';}
"%"		{token("%");return '%';}
"<"		{token("<");return '<';}
"<="	{token("<=");return LESSEQ;}
">"		{token(">");return '>';}
>=		{token(">=");return MOREEQ;}
==		{token("==");return EQ;}
~=		{token("~=");return NOTEQ;}
=		{token("=");return '=';}
and		{token("AND");return AND;}
or		{token("OR");return OR;}
not		{token("NOT");return NOT;}
do		{token("DO");return DO;}
else	{token("ELSE");return ELSE;}
end		{token("END");return END;}
for		{token("FOR");return FOR;}
if		{token("IF");return IF;}
import	{token("IMPORT");return IMPORT;}
in		{token("IN");return IN;}
local	{token("LOCAL");return LOCAL;}
nil		{token("NIL");return NIL;}
print	{token("PRINT");return PRINT;}
println	{token("PRINTLN");return PRINTLN;}
repeat	{token("REPEAT");return REPEAT;}
return	{token("RETURN");return RETURN;}
then	{token("THEN");return THEN;}
until	{token("UNTIL");return UNTIL;}
while	{token("WHILE");return WHILE;}
read	{token("READ"); return READ;/*proj2�s�W*/}

const	{token("CONST");return CONST;}
function	{token("FUNCTION");return FUNCTION;}

void	{token("VOID"); yylval.strv = strdup("void");return VOID;}
boolean	{token("BOOLEAN"); yylval.strv = strdup("bool"); return BOOLEAN;}
integer	{token("INTEGER"); yylval.strv = strdup("int"); return INTEGER;}
real	{token("REAL"); yylval.strv = strdup("real"); return REAL;}
string	{token("STRING"); yylval.strv = strdup("string"); return STR;}

true	{token("TRUE"); yylval.strv = strdup("1"); return TRUE;}
false	{token("FALSE"); yylval.strv = strdup("0"); return FALSE;}


[a-zA-Z][0-9a-zA-Z]*	{
							//identifier, symbolTable
							token("id");
							int i;
							/* //SYMBOLTABLE
							if(st0[0]==NULL){
								st0[0] = create();
								//st0=(sT*)malloc(sizeof(sT));
							}*/
							
							/*
							for(i=0;i<200;i++){
								if(st0[0]->name[i][0]=='\0'){
									//�Y���Ū��a��N��token��i�h
									//printf("DEBUG yyleng=%d",yyleng);
									
									strcpy(st0[0]->name[i],yytext);
									break;
								}
								//�M��name�O�_�w�s�btable
								if(strcmp(st0[0]->name[i],yytext)==0)
										break;
								
							}
							insert(yytext,st0[0]);*/
							yylval.strv = strdup(yytext);
							return ID;
							
						}
0|[1-9][0-9]*	{
					tokenString("constInt",yytext);
					yylval.strv = strdup(yytext);
					return CONSTINT;
				}
[+-]?(0|[1-9][0-9]*)\.[0-9]+((\^[+-]?[0-9]+)?)	{
	tokenString("constReal",yytext);
	yylval.strv = strdup("real");
	return CONSTREAL;}



\"		{
			LIST;
			BEGIN STRING;
		}

<STRING>\"\"	{
					//�r�ꤤ���޸�
					//tokenString("string: ","\"");
					LIST;
					strcat(strbuf,"\"");
				}
<STRING>\"	{
				//����
				tokenString("string",strbuf); 
				//printf("string %s\n",buf);
				yylval.strv = strdup(strbuf);//�^�Ǧr��??????????
				strbuf[0]='\0';
				BEGIN 0;
				return CONSTSTRING;
			}
<STRING>[^"]*	{	
					//eat the string body 
					LIST;
					strcat(strbuf,yytext);
				}
				
				
"/*"		{
				LIST;
				
				BEGIN COMMENT;
			}
<COMMENT>\n|\r\n	{
						//�@�檺����
				
						printf("%d: %s\n",linenum,buf);
						buf[0]='\0';
						linenum++;	
					}

<COMMENT>[^(\n|\r\n)]	{
					LIST;
				}

<COMMENT>"*/"	{
					LIST;
					BEGIN 0;
				}				

				
				
				
				


"//"	{
			//������(���w���@�檺����)
			char c = input();
			char cbuf[256];
			cbuf[0]='\0';
			cbuf[0]='/';
			cbuf[1]='/';
			int i = 2;
			//printf("single line comment.\n");
			while(c != '\n'&&c!='\r'&&c!=EOF){
				cbuf[i]=c;
				c=input();
				i++;
			}
			strcat(buf,cbuf);
			printf("%d: %s\n",linenum,buf);
			//buf[0]='\0';
			for(i=0;i<256;i++){
				buf[i]='\0';
				cbuf[i]='\0';
			}
			if(c=='\r')c=input();
			if(c=='\n')linenum++;
		}


\n|\r\n	{//====windows���欰\r\n==========�ɮ׵������Ӥ]�n���@��
			//LIST;
			printf("%d: %s\n",linenum,buf);
			linenum++;
			buf[0] = '\0';
			int i;
			for(i=0;i<256;i++){
				buf[i]='\0';
			}
		}
[ \t]*	{LIST;}

<<EOF>>	{
			LIST;
			printf("%d: %s\n",linenum,buf);
			//linenum++;
			buf[0] = '\0';
			/*
			printf("Symbol Table: \n");
				int k;
				for(k=0;st0[0]->name[k][0]!='\0';k++){
					printf("%s, ",st0[0]->name[k]);
				}printf("\n");
			*/
			//dump();
			return 0;
		}

.		{
		LIST;
		//printf("%d:%s\n",linenum,buf);
		printf("bad character: %s\n",yytext);
		//exit(-1);
		}





%%
/*========== C code ===========*/
/*
int main(void){
	yylex();
	//printf("No. of line: %d\n",linenum);
	return 0;
}
*/