%{
#define Trace(t)        if(Opt_P) printf(t)
//#define YYSTYPE			char*
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

//#include "lex.yy.c"

int Opt_P = 0;
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
		int valuei[200];//存const值
		int values[200][50];//存const字串
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
	
	//=====================Proj3===========================
	FILE *fp;
	int lcount;//Label counter
	extern FILE* yyin;
	char filename[20];//紀錄去掉.lua之後的檔名
	/*
	void showfile(FILE* fp){
		char c;
		printf("File: \n");
		while(fscanf(fp,"%c",&c)!=EOF){
			printf("%c",c);
		}
	}*/
%}

/*yacc跟lex溝通的union*/
%union{//SYMBOLTABLE裡面要存變數的值嗎 NO
	//float floatv; /*Real型態表示法 a^b = ??? */
	//int intv;
	//int* arrv;
	char* strv;
	//sT sTable;
	
}



/* tokens */
%token SEMI PARENL PARENR COMMA COLON BRACKETL BRACKETR BRACEL BRACER PLUS MINUS MULTI DIVID EXP PERCENT LESS LESSEQ MORE MOREEQ EQ NOTEQ ASSIGN AND OR NOT BOOLEAN CONST DO ELSE END FOR FUNCTION IF IMPORT IN INTEGER LOCAL NIL PRINT PRINTLN REAL REPEAT RETURN STR THEN UNTIL WHILE READ
/*下面是token以及parse的回傳型態?*/
%type <strv> type

%type <strv> oconst
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
program:	declare semi program| {
	//==========================1st stmt bytecode
	fprintf(fp,"method public static void main(java.lang.String[])\n");
	fprintf(fp,"max_stack 15\nmax_locals 15\n{\n");
	
}stmt semi subprogram| {
	fprintf(fp,"method public static void main(java.lang.String[])\n");
	fprintf(fp,"max_stack 15\nmax_locals 15\n{\nreturn\n}\n");
	Trace("Reducing to program\n");
};

subprogram:	stmt subprogram| {
	//==========================last stmt bytecode
	fprintf(fp,"return\n}\n");
}

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
	//=========local變數 bytecode ============
	char* tmptype;
	tmptype = strdup($1);
	if(strcmp(tmptype,"bool")==0){
		tmptype=strdup("boolean");
	}else if(strcmp(tmptype,"string")==0){
		tmptype=strdup("java.lang.String");
	}
	fprintf(fp,"%s",tmptype);
} subargus | ;

subargus:	','type ID{
	//ID也要放入SYMBOL TABLE
	insert($3,$2,st0[curid]);
	//ID型態放入function table
	strcpy(ft0[curDfunc]->argus[curArg],$2);
	curArg++;
	//===========local變數 bytecode ========================
	char* tmptype;
	tmptype = strdup($2);
	if(strcmp(tmptype,"bool")==0){
		tmptype=strdup("boolean");
	}else if(strcmp(tmptype,"string")==0){
		tmptype=strdup("java.lang.String");
	}
	fprintf(fp,",%s",tmptype);
} subargus | ;



oconst:		CONSTREAL{//不需要存值的variable
	$$="real";
}|	CONSTSTRING{
	$$="string";
}|	TRUE{
	$$="bool";
}|	FALSE{
	$$="bool";
};

declare:	declarec | declarev | declarear | declarefunc | declarefuncv;
declarev:	type ID '=' CONSTINT{/*===================b============*/
	//檢查型態是否符合
	int tmpi;
	if(strcmp($1,"int")!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s.\n",linenum,$2,$1,"int");
	//printf("$1 = %s, $4 = %s\n",$1,$4);
	
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		tmpi = insert($2,$1,st0[curid]);
	}
	Trace("reducing to declareV = constINT\n");
	
	//===================寫入jasm  =====================
	if(curid == 0){//如果是global variable
		fprintf(fp,"field static %s %s = %s\n",$1,$2,$4);
	}else{//若是local variable
		fprintf(fp,"sipush %s\n",$4);
		fprintf(fp,"istore %d\n",tmpi);
	}
}| type ID '=' oconst{/*同一區間重複declare同變數要error還warning???*/
	//檢查型態是否符合
	if(strcmp($1,$4)!=0) {
		printf("Line %d: [Warning] '%s' initialization makes %s from %s.\n",linenum,$2,$1,$4);
		yyerror("initialization type error!!\n");
	}
	//printf("$1 = %s, $4 = %s\n",$1,$4);
	
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		insert($2,$1,st0[curid]);
	}
	Trace("reducing to declareV = const\n");
	
	//=======不須寫入jasm (********)
};

declarev:	type ID{//=====================================
	if(lookup($2,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert\n");
		insert($2,$1,st0[curid]);
	}
	//================寫bytecode========================
	//printf("DEBUG $1 = %s, curid = %d\n",$1,curid);
	if(strcmp($1,"int")==0 && curid==0){//若是整數且是global variable則寫入jasm
		fprintf(fp,"field static int %s\n",$2);
	}else{//不是整數 或者 不是global都不寫bytecode
		
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

declarec:	CONST type ID '=' CONSTINT
{
	//=================================存const值在symbol Table==========
	//宣告常數變數
	/*檢查型態 print warning*/
	int tmpi;//存index
	if(strcmp($2,"int")!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s\n",linenum,$3,$2,"int");
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Const\n");
		tmpi = insert($3,$2,st0[curid]);
		st0[curid]->cst[tmpi]=1;//插入ST並且將const設為1
		st0[curid]->valuei[tmpi]=atoi($5);//存值
	}
	
	
	Trace("Reducing to declareC\n");
}|			CONST type ID '=' CONSTSTRING
{
	//宣告常數變數
	/*檢查型態 print warning*/
	int tmpi;
	if(strcmp($2,"string")!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s\n",linenum,$3,$2,"string");
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Const\n");
		tmpi = insert($3,$2,st0[curid]);
		st0[curid]->cst[tmpi]=1;//插入ST並且將const設為1
		strcpy(st0[curid]->values[tmpi],$5);
	}
	
	
	Trace("Reducing to declareC\n");
}|			CONST type ID '=' TRUE
{
	//=================================存const值在symbol Table==========
	//宣告常數變數
	/*檢查型態 print warning*/
	int tmpi;//存index
	if(strcmp($2,"bool")!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s\n",linenum,$3,$2,"bool");
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Const\n");
		tmpi = insert($3,$2,st0[curid]);
		st0[curid]->cst[tmpi]=1;//插入ST並且將const設為1
		st0[curid]->valuei[tmpi]=1;//存值
	}
	
	
	Trace("Reducing to declareC\n");
}|			CONST type ID '=' FALSE
{
	//=================================存const值在symbol Table==========
	//宣告常數變數
	/*檢查型態 print warning*/
	int tmpi;//存index
	if(strcmp($2,"bool")!=0) printf("Line %d: [Warning] '%s' initialization makes %s from %s\n",linenum,$3,$2,"bool");
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Const\n");
		tmpi = insert($3,$2,st0[curid]);
		st0[curid]->cst[tmpi]=1;//插入ST並且將const設為1
		st0[curid]->valuei[tmpi]=0;//存值
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
	//===========函式 bytecode=============
	fprintf(fp,"method public static %s %s(",$2,$3);
	
} _push01 '(' argus ')' {//================bytecode
	fprintf(fp,")\nmax_stack 15\nmax_locals 15\n{\n");
}block END _pop01{/*PUSH & POP*/
	/*應該要記住function & 型態*/
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Function\n");
		st0[curid]->func[insert($3,$2,st0[curid])]=1;//插入ST並且將function設為1
	}
	//====================bytecode
	fprintf(fp,"}\n");
	Trace("reducing to declareFunc\n");
};
declarefuncv:	FUNCTION VOID ID{//=============函式bytecode==================
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
	//===========函式 bytecode=============
	fprintf(fp,"method public static void %s(",$3);
	
} _push01 '(' argus ')'{//================bytecode
	fprintf(fp,")\nmax_stack 15\nmax_locals 15\n{\n");
} block END _pop01
{/*PUSH & POP*/
	if(lookup($3,st0[curid])!=-1){/*同一區間重複DECLARE*/
		printf("Line %d: [Warning] redeclaration of '%s' with no linkage.\n",linenum,$2);
	}else{
		/*放入symbol table*/
		//Trace("Action: Insert Function\n");
		st0[curid]->func[insert($3,$2,st0[curid])]=1;//插入ST並且將function設為1
	}
	//======================bytecode
	fprintf(fp,"}\n");
	Trace("reducing to declareVoidFunc\n");
};

stmt:		ID '=' exp{//======================存值(unfinished)================

	/*若ID是CONST variable則不能reassign*/
	/*檢查是否宣告過,若無則ERROR?? */
	int tmpt;//所在table
	int tmpi;//在table中的index
	char* idtype;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		tmpi = lookup($1,st0[tmpt]);
		if(tmpi!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
		
	}
	if(tmpt == -1){
		printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);
	}
	else{
		/*比較ID型態與ASSIGN的exp是否符合*/
		idtype = st0[tmpt]->tp[lookup($1,st0[tmpt])];
		if(strcmp(idtype,$3)!=0) printf("Line %d: [Warning] assignment makes %s from %s\n",linenum,idtype,$3);
		
		/*檢查是否constant*/
		if(st0[tmpt]->cst[lookup($1,st0[tmpt])] == 1){//是的話則error
			printf("Line %d: [Error] assignment of read-only variable '%s'\n",linenum,$1);
		}
		//=============取值==================
		if(tmpt==0){//若是global
			fprintf(fp,"putstatic %s %s.%s\n",idtype,filename,$1);
		}else{
			fprintf(fp,"istore %d\n",tmpi);
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
stmt:		PRINT{
	fprintf(fp,"getstatic java.io.PrintStream java.lang.System.out\n");
} exp{
	char* tmps;//暫存字串
	if(strcmp($3,"string")==0){//辨別型態
		tmps = strdup("java.lang.String");
	}else if(strcmp($3,"int")==0){
		tmps = strdup("int");
	}else if(strcmp($3,"bool")==0){
		tmps = strdup("boolean");
	}else{//UNABLE to print real or other type
	}
	fprintf(fp,"invokevirtual void java.io.PrintStream.print(%s)\n",tmps);
	
	Trace("reducing to stmt: PRINT exp\n");
};
stmt:		PRINTLN{
	fprintf(fp,"getstatic java.io.PrintStream java.lang.System.out\n");
} exp{
	char* tmps;//暫存字串
	if(strcmp($3,"string")==0){//辨別型態
		tmps = strdup("java.lang.String");
	}else if(strcmp($3,"int")==0){
		tmps = strdup("int");
	}else if(strcmp($3,"bool")==0){
		tmps = strdup("boolean");
	}else{//UNABLE to print real or other type
	}
	fprintf(fp,"invokevirtual void java.io.PrintStream.println(%s)\n",tmps);
	
	Trace("reducing to stmt: PRINTLN exp\n");
};
stmt:		READ exp{
	Trace("reducing to stmt: READ exp\n");
};
stmt:		RETURN{
	fprintf(fp,"return\n");
	Trace("reducing to stmt: RETURN\n");
};
stmt:		RETURN exp{//檢查函式型態是否VOID
	
	if(curVoid==1){
		printf("Line %d: [Error] 'return' with a value in function returning 'void'\n",linenum);
	}
	fprintf(fp,"ireturn\n");//===============bytecode
	Trace("reducing to stmt: RETURN exp\n");
};
stmt:		invfunc{/*??????*/
	
	Trace("reducing to stmt: invfunc\n");
};

/*以下statement都要push&pop symboltable*/


stmt:		IF '(' exp ')' _ifbyte01 THEN _push01 block _pop01 ELSE{//=============bytecode
	fprintf(fp,"goto Lexit%d\n",lcount+1);
	fprintf(fp,"Lfalse%d:\n",lcount);
} _push01 block _pop01 END {
	/*自己判斷exp是否為bool*/
	if(strcmp($3,"bool")!=0){
		printf("Line %d: [Error] 'if' condition is not boolean type\n",linenum);
	}
	//======================bytecode
	fprintf(fp,"Lexit%d:\n",lcount+1);
	lcount = lcount+2;
	Trace("reducing to stmt: IF ELSE\n");
}|			IF '(' exp ')' _ifbyte01 THEN  _push01 block END _pop01{//boolexp
	if(strcmp($3,"bool")!=0){
		printf("Line %d: [Error] 'if' condition is not boolean type\n",linenum);
	}
	fprintf(fp,"Lfalse%d:\n",lcount);
	lcount = lcount+1;
	Trace("reducing to stmt: IF THEN\n");
};



stmt:		WHILE {//=======bytecode
	fprintf(fp,"Lbegin%d:\n",lcount);
	lcount = lcount+1;
}'(' exp ')' {//============bytecode
	fprintf(fp,"ifeq Lexit%d\n",lcount);
	lcount = lcount+1;
}DO _push01 block END _pop01{//boolexp
	if(strcmp($4,"bool")!=0){
		printf("Line %d: [Error] 'while' condition is not boolean type\n",linenum);
	}
	//======================bytecode
	fprintf(fp,"goto Lbegin%d\n",lcount-4);//要減4因為exp加了2 判斷又加了2
	fprintf(fp,"Lexit%d:\n",lcount-1);//減4加3 同上
	//lcount = lcount+2;
	Trace("reducing to stmt: WHILE\n");
};

stmt:		FOR ID '=' exp ',' exp DO _push01 block END _pop01{
	Trace("reducing to stmt: FOR\n");
};


_ifbyte01: 
{
	//==============bytecode
	fprintf(fp,"ifeq Lfalse%d\n",lcount);
	//lcount = lcount+1;//最後再加
}; 
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
};

_pop01: {
	/*POP SymbolTable*/
	//Trace("Embedded Action: Pop\n");
	int tmp;
	tmp = curid;
	curid = st0[curid]->parent;
	freest(st0[tmp]);
	st0[tmp]=NULL;
};

invfunc:	ID '('{
	curArg = 0;
	int i=0;
	for(i=0;i<100;i++){//找function table
		if(strcmp(ft0[i]->fname,$1)==0)
			curDfunc = i;
			break;
	}//printf("current invoke func %d at function table\n",curDfunc);
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
	int tmpi;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		tmpi = lookup($1,st0[tmpt]);
		if(tmpi!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
	}
	if(tmpt == -1){printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);}
	else{
		/*檢查ID是否function*/
		int tmpfunc = st0[tmpt]->func[tmpi];
		if(tmpfunc!=1)
			printf("Line: %d, [Error] called object '%s' is not a function or function pointer\n",linenum,$1);
		else{
			
		}
	}
	$$=strdup(st0[tmpt]->tp[lookup($1,st0[tmpt])]);
	
	//====================bytecode
	char* tmptype;
	tmptype = strdup(st0[tmpt]->tp[tmpi]);
	if(strcmp(tmptype,"string")==0){
		tmptype = strdup("java.lang.String");
	}else if(strcmp(tmptype,"bool")==0){
		tmptype = strdup("boolean");
	}
	char tmparg[20]="";
	int i;
	for(i=0;ft0[curDfunc]->argus[i+1][0]!='\0';i++){
		strcat(tmparg,ft0[curDfunc]->argus[i]);
		strcat(tmparg,",");
	}strcat(tmparg,ft0[curDfunc]->argus[i]);
	fprintf(fp,"invokestatic %s %s.%s(%s)\n",tmptype,filename,$1,tmparg);
	
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





/*ask 整數和實數間的運算加Warning*/
exp:		CONSTINT{//==========================存值=========
	$$=strdup("int");
	fprintf(fp,"sipush %s\n",$1);
}|			CONSTREAL{
	$$=strdup("real");
}|			TRUE{
	fprintf(fp,"iconst_1\n");
	$$=strdup("bool");
}|			FALSE{
	fprintf(fp,"iconst_0\n");
	$$=strdup("bool");
}|			CONSTSTRING{
	fprintf(fp,"ldc \"%s\"\n",$1);
	$$=strdup("string");
}|'(' exp ')'{
	$$=$2;
}|			exp '+' exp{//=========================
	/*不同型態間的運算Warning*/
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"iadd\n");
	$$=$1;
}|			exp '-' exp{//=========================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	$$=$1;
}|			exp '*' exp{//=========================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"imul\n");
	$$=$1;
}|			exp '/' exp{//=========================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"idiv\n");
	$$=$1;
}|			exp '%' exp{//=========================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"irem\n");
	$$=$1;
}|			exp '^' exp{
	$$=$1;
}|			'-' exp %prec UMINUS{//=========================
	fprintf(fp,"ineg\n");
	$$=$2;
}|			exp '<' exp{//===========bytecode判斷式 未完成==============
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	fprintf(fp,"iflt L%d\n",lcount);
	fprintf(fp,"iconst_0\n");
	fprintf(fp,"goto L%d\n",lcount+1);
	fprintf(fp,"L%d: iconst_1\n",lcount);
	fprintf(fp,"L%d:\n",lcount+1);
	lcount = lcount + 2;
	$$=strdup("bool");
}|			exp '>' exp{//===========bytecode判斷式==============
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	fprintf(fp,"ifgt L%d\n",lcount);
	fprintf(fp,"iconst_0\n");
	fprintf(fp,"goto L%d\n",lcount+1);
	fprintf(fp,"L%d: iconst_1\n",lcount);
	fprintf(fp,"L%d:\n",lcount+1);
	lcount = lcount + 2;
	$$=strdup("bool");
}|			exp LESSEQ exp{//===========bytecode判斷式==============
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	fprintf(fp,"ifle L%d\n",lcount);
	fprintf(fp,"iconst_0\n");
	fprintf(fp,"goto L%d\n",lcount+1);
	fprintf(fp,"L%d: iconst_1\n",lcount);
	fprintf(fp,"L%d:\n",lcount+1);
	lcount = lcount + 2;
	$$=strdup("bool");
}|			exp MOREEQ exp{//===========bytecode判斷式==============
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	fprintf(fp,"ifge L%d\n",lcount);
	fprintf(fp,"iconst_0\n");
	fprintf(fp,"goto L%d\n",lcount+1);
	fprintf(fp,"L%d: iconst_1\n",lcount);
	fprintf(fp,"L%d:\n",lcount+1);
	lcount = lcount + 2;
	$$=strdup("bool");
}|			exp EQ exp{//===========bytecode判斷式==============
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	fprintf(fp,"ifeq L%d\n",lcount);
	fprintf(fp,"iconst_0\n");
	fprintf(fp,"goto L%d\n",lcount+1);
	fprintf(fp,"L%d: iconst_1\n",lcount);
	fprintf(fp,"L%d:\n",lcount+1);
	lcount = lcount + 2;
	$$=strdup("bool");
}|			exp NOTEQ exp{//===========bytecode判斷式==============
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"isub\n");
	fprintf(fp,"ifne L%d\n",lcount);
	fprintf(fp,"iconst_0\n");
	fprintf(fp,"goto L%d\n",lcount+1);
	fprintf(fp,"L%d: iconst_1\n",lcount);
	fprintf(fp,"L%d:\n",lcount+1);
	lcount = lcount + 2;
	$$=strdup("bool");
}|			exp NOT exp{//========================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"ixor\n");
	$$=strdup("bool");
}|			exp AND exp{//=========================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"iand\n");
	$$=strdup("bool");
}|			exp OR exp{//============================
	if(strcmp($1,$3)!=0){printf("Line %d: [Warning] operation between different types %s and %s\n",linenum,$1,$3);}
	fprintf(fp,"ior\n");
	$$=strdup("bool");
}|			invfunc{/*若為void型態則不能當作exp*/
	//printf("invfunc type = %s\n",$1);
	if(strcmp($1,"void")==0){
		printf("Line %d: [Error] void value not ignored as it ought to be\n",linenum);
	}
	
}|			ID{/*回傳TYPE, 要檢查有沒有宣告過 'id' undeclared(first use in this function)*/
	/*檢查是否宣告過,若無則ERROR */
	int tmpt;//SYMBOL table
	int tmpi;//在symbol table中的index
	char* idtype;
	//printf("CurID = %d, Parent = %d\n",curid,st0[curid]->parent);
	for(tmpt=curid;tmpt!=-1;tmpt=st0[tmpt]->parent){
		tmpi = lookup($1,st0[tmpt]);
		if(tmpi!=-1){
			/*若有找到ID*/ 
			//printf("find '%s' at SymbolTable %d\n",$1,tmpt);
			break;
		}
		
	}
	if(tmpt == -1){printf("Line %d: [Error] '%s' undeclared (first use in this function)\n",linenum,$1);}
	else{
		/*比較ID型態與ASSIGN的exp是否符合*/
		idtype = st0[tmpt]->tp[tmpi];
		$$=idtype;
	}
	
	//==================EXP取值(class名稱必須跟檔名一樣???????)=====================
	//printf("DEBUG: tmpt = %d\n",tmpt);
	if(st0[tmpt]->cst[tmpi]==1){//若是const則直接從symbol table中取值
		if(strcmp(idtype,"int")==0){
			fprintf(fp,"sipush %d\n",st0[tmpt]->valuei[tmpi]);
		}else if(strcmp(idtype,"bool")==0){
			fprintf(fp,"iconst_%d\n",st0[tmpt]->valuei[tmpi]);
		}else if(strcmp(idtype,"string")==0){
			fprintf(fp,"ldc \"%s\"\n",st0[tmpt]->values[tmpi]);
		}
	}else{//若不是const
		if(tmpt == 0){//若是global
			fprintf(fp,"getstatic %s %s.%s\n",idtype,filename,$1);
		}else{//若是local
			fprintf(fp,"iload %d\n",tmpi);
		}
	}

};			
















%%
//

yyerror(msg)
char *msg;
{
    fprintf(stderr, "%s\n", msg);
}

int main(int argc, char** argv)
{
	int i;
	st0[0] = create(-1);//宣告symboltable
	curid = 0;
	curDfunc = 0;
	curArg = 0;
	curVoid = 0;
	//curInvfunc = 0;
	//========Proj3========
	yyin = fopen(argv[1],"r");
	//擷取檔名
	
	sscanf(argv[1],"%[^.]",filename);//FK SSCANF
	printf("filename = %s\n",filename);
	char jfile[20] = "";
	strcat(jfile,filename);strcat(jfile,".jasm");//建立檔名一樣的jasm檔
	fp = fopen(jfile,"w");
	//fp = fopen("proj3.jasm","w");
	if(!fp){printf("Failed to open source file.\n");}
	lcount = 1;
	//CLASS名稱
	fprintf(fp,"class %s\n{\n",filename);
    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
	dump();
	showf();
	//int i;
	for(i=0;i<20;i++){free(st0[i]);}
	printf("\n");
	//showfile(fp);
	
	fprintf(fp,"}\n");
	fclose(fp);
	
	//printf("argc = %d\n",argc);
	//printf("argv0 = %s\n",argv[0]);
	//printf("argv1 = %s\n",argv[1]);
}

