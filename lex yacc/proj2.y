%{
#define Trace(t)        if(Opt_P) printf(t)
//#define YYSTYPE			char*
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

//#include "lex.yy.c"

int Opt_P = 1;
int linenum = 1;

int yylex();

/*SYMBOLTABLE*/

	typedef struct symbolTable sT;
	//typedef struct funcarg farg;
	struct symbolTable{
		int parent;//或者上一層symbolTable的index
		char name[200][20];//id名字的陣列200個,字串最長20字
		char tp[200][20];//存取型態的陣列
		int cst[200];//是否為常數變數
		int func[200];//若為function則存入argument型態
	};
	
	sT *create(int idpar){
		sT* st;
		st=(sT*)malloc(sizeof(sT));
		st->parent = idpar;
		int i;
		for(i=0;i<200;i++){//初始化symbolTable
			st->cst[i]=0;
			st->func[i]=0;
		}
		return st;
	}
	int lookup(char* str,sT* st){//尋找某variable
		int i;
		for(i=0;i<200;i++){
			//尋找name是否已存在table
			if(strcmp(st->name[i],str)==0)
				return i;
			
		}return -1;//沒找到就return -1
	}
	int insert(char* str,char* idtp,sT* st){//新增variable並回傳在table中的index
		//int k = lookup(str,st);
		//if(k==-1){//st裡面沒有這個字
			int i;
			for(i=0;i<200;i++){
				if(st->name[i][0]=='\0'){
					strcpy(st->name[i],str);
					strcpy(st->tp[i],idtp);
					return i;
				}
			}
		//}
		
	}
	void freest(sT* st){
		//free(st->parent);
		//free(st->name);
		//free(st->tp);
		free(st);
		//st = NULL;
	}
	sT *st0[20];
	void dump(){
		int i;
		for(i=0;i<20;i++){
			if(st0[i]){
				int k;
				printf("SymbolTable %d: \n",i);
				for(k=0;st0[i]->name[k][0]!='\0';k++){
					char* c;
					if(st0[i]->cst[k]==1)c="(const)"; else if(st0[i]->func[k]!=0) c="(func)"; else c=""; 
					printf("%s:%s%s, ",st0[i]->name[k],st0[i]->tp[k],c);
				}printf("\n");
			}
		}
	}
	//memset(st0->name, '\0', sizeof(char)*200*20);
	//sT *st0 = (sT*)malloc(sizeof(sT));
	
	/*紀錄function有哪些參數*/
	typedef struct functable{
		char fname[20];//函數名稱,最長20
		char argus[20][10];//允許每個function最多20個參數(存型態,長度10),
	}ftable;
	ftable *ft0[100];//允許最多100個function
	
	void showf(){//印出function table
		int i,j;
		printf("Function Table:\n");
		for(i=0;i<100;i++){
			if(ft0[i]!=NULL){
				printf("Function %d: %s\n",i,ft0[i]->fname);
				for(j=0;j<20;j++){
					if(ft0[i]->argus[j][0]!='\0'){
						printf("%d: %s, ",j,ft0[i]->argus[j]);
					}
				}printf("\n");
			}
		}
	}
	ftable* createf(char* funcname){//創建function table
		ftable* ft;
		ft = (ftable*)malloc(sizeof(ftable));
		strcpy(ft->fname,funcname);
		return ft;
	}
	
	void insertarg(ftable* ft,char* argname){
		int i;
		for(i=0;i<20;i++){
			if(ft->argus[i][0]=='\0'){
				strcpy(ft->argus[i],argname);
				return;
			}
		}
	}
	
	int curDfunc;//目前declare的function table
	//int curInvfunc;//目前invoke的function table
	int curArg;//目前在functable裡的arg index
	int curid;//目前所在 symbol table
	int curVoid;//目前function是否為void
	
%}

/*yacc跟lex溝通的union*/
%union{//SYMBOLTABLE裡面要存變數的值嗎 NO
	float floatv; /*Real型態表示法 a^b = ??? */
	int intv;
	int* arrv;
	char* strv;
	//sT sTable;
	
}



/* tokens */
%token SEMI PARENL PARENR COMMA COLON BRACKETL BRACKETR BRACEL BRACER PLUS MINUS MULTI DIVID EXP PERCENT LESS LESSEQ MORE MOREEQ EQ NOTEQ ASSIGN AND OR NOT BOOLEAN CONST DO ELSE END FOR FUNCTION IF IMPORT IN INTEGER LOCAL NIL PRINT PRINTLN REAL REPEAT RETURN STR THEN UNTIL WHILE READ
/*下面是token以及parse的回傳型態?*/
%type <strv> type
%type <strv> constexp
%type <strv> exp
%type <strv> invfunc

%token <strv> ID
%token <strv> CONSTINT
%token <strv> CONSTREAL
%token <strv> CONSTSTRING
%token <strv> TRUE
%token <strv> FALSE
%token <strv> VOID


/*優先順序?*/
%left OR
%left AND
%left NOT
%left NOTEQ MOREEQ LESSEQ EQ '>' '<'
%left '-' '+'
%left '*' '/' '%'
%right '^'
%nonassoc UMINUS





%%
program:	program declare| program stmt| 
{
	/*identifier semi????*/
	Trace("Reducing to program\n");
};



semi:		SEMI| 
{
	Trace("Reducing to semi\n");
};

block:		stmt semi block | declare semi block | 
{
	Trace("Reducing to block\n");
};

type:		BOOLEAN {
	$$ = "bool";
}| INTEGER {
	$$ = "int";
}| REAL {
	$$ = "real";
}| STR{
	$$ = "string";
};


argus:		type ID{
	//ID也要放入SYMBOL TABLE
	insert($2,$1,st0[curid]);
	//ID型態放入function table
	strcpy(ft0[curDfunc]->argus[curArg],$1);
	curArg++;
} subargus | ;

subargus:	','type ID{
	//ID也要放入SYMBOL TABLE
	insert($3,$2,st0[curid]);
	//ID型態放入function table
	strcpy(ft0[curDfunc]->argus[curArg],$2);
	curArg++;
} subargus | ;

constexp:	CONSTINT{
	$$ = "int";
} | CONSTREAL {
	$$ = "real";
}| CONSTSTRING {
	$$ = "string";
}| TRUE {
	$$ = "bool";
}| FALSE{
	$$ = "bool";
};

declare:	declarec | declarev | declarear | declarefunc | declarefuncv;
declarev:	type ID '=' constexp{/*同一區間重複declare同變數要error還warning???*/
	//檢查型態是否符合
	if(strcmp($1,$4)!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s.\n",linenum,$2,$1,$4);
	//printf("$1 = %s, $4 = %s\n",$1,$4);
	
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		insert($2,$1,st0[curid]);
	}
	Trace("reducing to declareV = const\n");
	
	
}|			type ID{
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		insert($2,$1,st0[curid]);
	}
	Trace("reducing to declareV\n");
	
};
declarear:	type ID '[' CONSTINT ']'{/*宣告陣列*/
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		insert($2,$1,st0[curid]);
	}
	Trace("reducing to declareArr\n");
}|			type ID '[' ID ']'{/*此id必須為CONST INTEGER*/
	if(st0[curid]->cst[lookup($4,st0[curid])]!=1 || strcmp(st0[curid]->tp[lookup($4,st0[curid])],"int")!=0){
		/*中括號內ID不是常數整數變數*/
		printf("Line %d: [Warning] size of array '%s' has non-const or non-integer type\n",linenum,$2);
	}
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		insert($2,$1,st0[curid]);
	}
	Trace("reducing to declareArr[ID]\n");
};

declarec:	CONST type ID '=' constexp
{
	//宣告常數變數
	/*檢查型態 print warning*/
	if(strcmp($2,$5)!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s\n",linenum,$3,$2,$5);
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Const\n");
		st0[curid]->cst[insert($3,$2,st0[curid])]=1;//插入ST並且將const設為1
	}
	
	
	Trace("Reducing to declareC\n");
};


declarefunc:	FUNCTION type ID{
	curArg = 0;
	curVoid = 0;
	int i;
	for(i=0;i<100;i++){
		if(ft0[i]==NULL){
			ft0[i] = createf($3);
			curDfunc = i;
			break;
		}
	}
} _push01 '(' argus ')' block END _pop01{/*PUSH & POP*/
	/*應該要記住function & 型態*/
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Function\n");
		st0[curid]->func[insert($3,$2,st0[curid])]=1;//插入ST並且將function設為1
	}
	
	Trace("reducing to declareFunc\n");
};
declarefuncv:	FUNCTION VOID ID{
	curArg = 0;
	curVoid = 1;
	int i;
	for(i=0;i<100;i++){
		if(ft0[i]==NULL){
			ft0[i] = createf($3);
			curDfunc = i;
			break;
		}
	}
} _push01 '(' argus ')' block END _pop01
{/*PUSH & POP*/
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Function\n");
		st0[curid]->func[insert($3,$2,st0[curid])]=1;//插入ST並且將function設為1
	}
	Trace("reducing to declareVoidFunc\n");
};

stmt:		ID '=' exp{/*若ID是CONST variable則不能reassign*/
	/*檢查是否宣告過,若無則ERROR?? */
	int tmpt;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		if(lookup($1,st0[tmpt])!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
		
	}
	if(tmpt == -1){printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);}
	else{
		/*比較ID型態與ASSIGN的exp是否符合*/
		char* idtype;
		idtype = st0[tmpt]->tp[lookup($1,st0[tmpt])];
		if(strcmp(idtype,$3)!=0) printf("Line %d: [Warning] assignment makes %s from %s\n",linenum,idtype,$3);
		
		/*檢查是否constant*/
		if(st0[tmpt]->cst[lookup($1,st0[tmpt])] == 1){//是的話則error
			printf("Line %d: [Error] assignment of read-only variable '%s'\n",linenum,$1);
		}
	}
	
	
	Trace("Reducing to ID = exp\n");
};
stmt:		ID '[' exp ']' '=' exp{/*檢查型態是否符合*/
	if(strcmp($3,"int")!=0){
		printf("Line %d: [Error] index of array '%s' is not an integer\n",linenum,$1);
	}
	Trace("reducing to Arr = exp\n");
};
stmt:		PRINT exp{
	Trace("reducing to stmt: PRINT exp\n");
};
stmt:		PRINTLN exp{
	Trace("reducing to stmt: PRINTLN exp\n");
};
stmt:		READ exp{
	Trace("reducing to stmt: READ exp\n");
};
stmt:		RETURN{
	Trace("reducing to stmt: RETURN\n");
};
stmt:		RETURN exp{//檢查函式型態是否VOID
	
	if(curVoid==1){
		printf("Line %d: [Error] 'return' with a value in function returning 'void'\n",linenum);
	}
	Trace("reducing to stmt: RETURN exp\n");
};
stmt:		invfunc{/*??????*/
	
	Trace("reducing to stmt: invfunc\n");
};

invfunc:	ID '('{
	curArg = 0;
	int i=0;
	for(i=0;i<100;i++){//找function table
		if(strcmp(ft0[i]->fname,$1)==0)
			curDfunc = i;
			break;
	}printf("current invoke func %d at function table\n",curDfunc);
	if(i==100)Trace("Function not found in function table.\n");
	
} commaexp ')'{/*沒有參數的function????*/
	/*ID是否宣告過
	判斷是否為函數
	判斷參數是否符合調用函數
	引入函數 若為void則不能當作exp
	ask 若不為void可以作為statement????
	*/
	
	/*檢查是否宣告過,若無則ERROR */
	int tmpt;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		if(lookup($1,st0[tmpt])!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
		
	}
	if(tmpt == -1){printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);}
	else{
		/*檢查ID是否function*/
		int tmpfunc = st0[tmpt]->func[lookup($1,st0[tmpt])];
		if(tmpfunc!=1)
			printf("Line: %d, [Error] called object '%s' is not a function or function pointer\n",linenum,$1);
		else{
			
		}
	}
	$$=strdup(st0[tmpt]->tp[lookup($1,st0[tmpt])]);
	
	Trace("reducing to invfunc\n");
}|			ID '(' {
	curArg = 0;
	int i;
	for(i=0;i<100;i++){//找function table
		if(strcmp(ft0[i]->fname,$1)==0)
			curDfunc = i;
			break;
	}printf("current invoke func %d at function table\n",curDfunc);
	if(i==100)Trace("Function not found in function table.\n");
	
	for(i=0;i<100;i++){//找function table, 算參數數量
		if(ft0[curDfunc]->argus[i][0]=='\0')
			break;
	}
	if(i>0){
		printf("Line %d: [Error] too few arguments in function '%s'\n",linenum,ft0[curDfunc]->fname);
	}
} ')'{
	/*檢查是否宣告過,若無則ERROR */
	int tmpt;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		if(lookup($1,st0[tmpt])!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
		
	}
	if(tmpt == -1){printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);}
	else{
		/*檢查ID是否function*/
		int tmpfunc = st0[tmpt]->func[lookup($1,st0[tmpt])];
		if(tmpfunc!=1)
			printf("Line: %d, [Error] called object '%s' is not a function or function pointer\n",linenum,$1);
		else{
			
		}
	}
	$$=strdup(st0[tmpt]->tp[lookup($1,st0[tmpt])]);
	Trace("reducing to invfunc without arg\n");
};
commaexp:	exp{
	if(strcmp(ft0[curDfunc]->argus[curArg],$1)!=0){//型態是否對應
		printf("Line %d: [Warning] dismatch type in function '%s' at argu %d\n",linenum,ft0[curDfunc]->fname,curArg+1);
	}curArg++;
	int i;
	for(i=0;i<100;i++){//找function table, 算參數數量
		if(ft0[curDfunc]->argus[i][0]=='\0')
			break;
	}
	if(curArg<i){
		printf("Line %d: [Error] too few arguments in function '%s'\n",linenum,ft0[curDfunc]->fname);
	}else if(curArg>i){
		printf("Line %d: [Error] too many arguments in function '%s'\n",linenum,ft0[curDfunc]->fname);
	}
} | exp{
	if(strcmp(ft0[curDfunc]->argus[curArg],$1)!=0){
		printf("Line %d: [Warning] dismatch type in function '%s' at argu %d\n",linenum,ft0[curDfunc]->fname,curArg+1);
	}curArg++;
} ',' commaexp;



/*以下statement都要push&pop symboltable*/

_push01: {
	/*PUSH symbolTable*/
	//Trace("Embedded Action: Push.\n");
	int i;
	int tmp;
	tmp = curid;
	for(i=0;i<20;i++){
		if(st0[i]==NULL){
			curid = i; st0[i] = create(tmp);
			break;
		}
	}
}

_pop01: {
	/*POP SymbolTable*/
	//Trace("Embedded Action: Pop\n");
	int tmp;
	tmp = curid;
	curid = st0[curid]->parent;
	freest(st0[tmp]);
	st0[tmp]=NULL;
}

stmt:		IF '(' exp ')' THEN  _push01 block END _pop01{//boolexp
	if(strcmp($3,"bool")!=0){
		printf("Line %d: [Error] 'if' condition is not boolean type\n",linenum);
	}
	Trace("reducing to stmt: IF THEN\n");
};

stmt:		IF '(' exp ')' THEN _push01 block ELSE block END _pop01{
	/*自己判斷exp是否為bool*/
	if(strcmp($3,"bool")!=0){
		printf("Line %d: [Error] 'if' condition is not boolean type\n",linenum);
	}
	Trace("reducing to stmt: IF ELSE\n");
};



stmt:		WHILE '(' exp ')' DO _push01 block END _pop01{//boolexp
	if(strcmp($3,"bool")!=0){
		printf("Line %d: [Error] 'while' condition is not boolean type\n",linenum);
	}
	Trace("reducing to stmt: WHILE\n");
};

stmt:		FOR ID '=' exp ',' exp DO _push01 block END _pop01{
	Trace("reducing to stmt: FOR\n");
};

/*ask 整數和實數間的運算加Warning*/
exp:		CONSTINT{
	$$=$1;
}|			CONSTREAL{
	$$=$1;
}|			TRUE{
	$$=$1;
}|			FALSE{
	$$=$1;
}|			CONSTSTRING{
	$$=$1;
}|'(' exp ')'{
	$$=$2;
}|			exp '+' exp{
	/*不同型態間的運算Warning*/
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=$1;
}|			exp '-' exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=$1;
}|			exp '*' exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=$1;
}|			exp '/' exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=$1;
}|			exp '%' exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=$1;
}|			exp '^' exp{
	$$=$1;
}|			'-' exp %prec UMINUS{
	$$=$2;
}|			exp '<' exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=strdup("bool");
}|			exp '>' exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=strdup("bool");
}|			exp LESSEQ exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=strdup("bool");
}|			exp MOREEQ exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=strdup("bool");
}|			exp EQ exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=strdup("bool");
}|			exp NOTEQ exp{
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	$$=strdup("bool");
}|			invfunc{/*若為void型態則不能當作exp*/
	//printf("invfunc type = %s\n",$1);
	if(strcmp($1,"void")==0){
		printf("Line %d: [Error] void value not ignored as it ought to be\n",linenum);
	}
	
}|			ID{/*回傳TYPE, 要檢查有沒有宣告過 'id' undeclared(first use in this function)*/
	/*檢查是否宣告過,若無則ERROR */
	int tmpt;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		if(lookup($1,st0[tmpt])!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
		
	}
	if(tmpt == -1){printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);}
	else{
		/*比較ID型態與ASSIGN的exp是否符合*/
		char* idtype;
		idtype = st0[tmpt]->tp[lookup($1,st0[tmpt])];
		$$=idtype;
	}
};			
















%%
//

yyerror(msg)
char *msg;
{
    fprintf(stderr, "%s\n", msg);
}

int main()
{
	
	st0[0] = create(-1);//宣告symboltable
	curid = 0;
	curDfunc = 0;
	curArg = 0;
	curVoid = 0;
	//curInvfunc = 0;
    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
	dump();
	showf();
	int i;
	for(i=0;i<20;i++){free(st0[i]);}
	printf("\n\n");
}

