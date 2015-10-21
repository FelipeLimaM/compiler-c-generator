%{
#include <stdio.h>
#include <stdlib.h>
#include <vector>

using namespace std;

#define TAM_IDENT 100
enum Tipo { NONE, LOGICO, INTEIRO, REAL, CARACTER, REGISTRO };
struct IDENT {
	char lexema[TAM_IDENT];
	Tipo type;
};

extern int yylex ();
extern void yyerror (const char *);
extern FILE* output;
extern vector<IDENT> tabela;
vector<char*> pilha;

char PR_ALGORITMO_C[] = "#include <stdio.h>\n#include <stdlib.h>\n\n";
char MACROS_C[] = "#define RESTO(x,y) (x%y)\n#define ABS(x) (x >= 0 ? x:-x)\n#define TRUNCA(x) ((int) (x/1))\n\n";
char PR_INICIO_C[] = "int main (int argc, char* argv[]) {\n";
char PR_FIM_ALGO_C[] = "return 0;\n}\n";

char PR_LOGICO_C[] = "int ";
char PR_INTEIRO_C[] = "int ";
char PR_REAL_C[] = "double ";
char PR_CARACTER_C[] = "char ";

char PR_SE_C[] = "if (";
char PR_ENTAO_C[] = ") {\n";
char PR_SENAO_C[] = "} else {\n";
char PR_FIM_C[] = "}\n";

char PR_ENQUANTO_C[] = "while (";
char PR_REPITA_C[] = "do {\n";
char PR_ATE_C[] = "} while (!";
char PR_FIM_REPITA_C[] = ");\n";
char PR_PARA_C[] = "for (";



void put(const char* buffer) {
	fprintf(output, "%s", buffer);
}

char getType(const char* var) {
	// TODO tabela de símbolos
	return 's';
}

void makeprintf() {
	for(int i = 0; i < pilha.size(); i++) {
		if (pilha[i][0] == '"') {
			fprintf(output, "printf(%s);\n", pilha[i]);
		} else {
			fprintf(output, "printf(\"%%%c\", %s);\n", getType(pilha[i]), pilha[i]);
		}
	}
	pilha.clear();
}

char *int_to_char(int num) {
	static char buffer[33];
	snprintf(buffer, sizeof(buffer), "%d", num);
	return buffer;
}
%}

%union {
	int integer;
	char *string;
	double real;
}

// Ativa as mensagens de erro sintático
%error-verbose

// Declaração dos tokens utilizados no compilador

%token <string> IDENTIFICADOR CONST_LIT
%token <integer> NUM_INTEIRO
%token <real> NUM_REAL

%token <string> OP_ATRIB OP_ARIT_MULT OP_ARIT_DIV OP_ARIT_ADI OP_ARIT_SUB OP_ARIT_EXPO OP_ARIT_RAD

%token <string> OP_REL_IGUAL OP_REL_NAOIGUAL OP_REL_MAIOR OP_REL_MAIORIGUAL OP_REL_MENOR OP_REL_MENORIGUAL

%token <string> OP_LOG_NAO OP_LOG_AND OP_LOG_OR

%token <string> PONTO VIRGULA PONTO_VIRGULA DOIS_PONTOS ABRE_COL FECHA_COL ABRE_PAR FECHA_PAR ASPAS


%token <string> PR_ALGORITMO PR_INICIO PR_FIM_ALGO
%token <string> PR_LOGICO PR_INTEIRO PR_REAL PR_CARACTER PR_REGISTRO
%token <string> PR_LEIA PR_ESCREVA
%token <string> PR_SE PR_ENTAO PR_SENAO PR_FIM_SE
%token <string> PR_PARA PR_ATE PR_PASSO PR_FACA PR_FIM_PARA PR_ENQTO PR_FIM_ENQTO PR_REPITA PR_ABS PR_TRUNCA PR_RESTO PR_DECLARE

%token <string> PR_FUNCAO PR_ENTRADA PR_SAIDA PR_FIM_FUNCAO PR_PROCMTO PR_FIM_PROCMTO

%type <string> algo l_var l_vrs exp_a term_a fat_a

%type <string> var
// Não-terminal inicial
%start algo

%%

// Definição das produções da gramática

algo:		PR_ALGORITMO { put(PR_ALGORITMO_C); put(MACROS_C); } IDENTIFICADOR procs PR_INICIO { put(PR_INICIO_C); } decl cmds PR_FIM_ALGO { put(PR_FIM_ALGO_C); };

decl:		PR_DECLARE l_ids DOIS_PONTOS tipo PONTO_VIRGULA decl {}
		|	PR_DECLARE error PONTO_VIRGULA decl { printf("Declaration error, ignoring variable.\n\n"); }
		|	%empty {};


l_ids:		IDENTIFICADOR comp lids {};

lids:		VIRGULA l_ids {}
		|	%empty {};

comp:		ABRE_COL dim FECHA_COL {}
		|	ABRE_COL error FECHA_COL { printf("Bad dimension.\n\n"); }
		|	%empty {};

dim:		NUM_INTEIRO PONTO PONTO NUM_INTEIRO dims {};

dims:		VIRGULA dim {}
		|	%empty {};

tipo:		PR_LOGICO {}
		|	PR_CARACTER {}
		|	PR_INTEIRO {}
		|	PR_REAL {}
		|	IDENTIFICADOR {}
		|	reg {};

reg:		PR_REGISTRO ABRE_PAR decl FECHA_PAR {};

cmds:		PR_LEIA { pilha.clear(); } l_var cmds {}
		|	PR_ESCREVA { pilha.clear(); } l_var { makeprintf(); } cmds {}
		|	IDENTIFICADOR OP_ATRIB exp cmds {}
		|	IDENTIFICADOR error cmds { printf("Bad attribution.\n\n"); }
		|	PR_SE { put(PR_SE_C); } cond PR_ENTAO { put(PR_ENTAO_C); } cmds sen PR_FIM_SE { put(PR_FIM_C); } cmds {}
		
		|	PR_PARA { put(PR_PARA_C); } IDENTIFICADOR { put($3); } OP_ATRIB { put(" = "); } exp_a PR_ATE { put("; "); put($3); } exp_a PR_PASSO NUM_INTEIRO { put("; "); put($3); put(" = "); put($3); put(" + "); put(int_to_char($12)); } PR_FACA { put(PR_ENTAO_C); } cmds PR_FIM_PARA { put(PR_FIM_C); } cmds {} // -> PR_INTEIRO para exp_a: inicio e fim do para-passo definido por expressão algébrica.
		
		|	PR_ENQTO { put(PR_ENQUANTO_C); } cond { put(PR_ENTAO_C); } cmds PR_FIM_ENQTO { put(PR_FIM_C); } cmds {}
		|	PR_REPITA { put(PR_REPITA_C); } cmds PR_ATE { put(PR_ATE_C); } cond { put(PR_FIM_REPITA_C); } cmds {}
		| 	IDENTIFICADOR ABRE_PAR { pilha.clear(); } l_var FECHA_PAR cmds {}
		|	%empty {};

l_var:		var { pilha.push_back($1); } l_vrs
		|	CONST_LIT { pilha.push_back($1); } l_vrs;

l_vrs:		VIRGULA l_var {}
		|	%empty {};

var:		IDENTIFICADOR ind {};

ind:		ABRE_COL exp_a FECHA_COL ind {}
		|	PONTO IDENTIFICADOR ind {}
		|	%empty {};

sen:		PR_SENAO { put(PR_SENAO_C); } cmds {}
		|	%empty {};

// Adicionado o "procs" no final das produções e a palavra vazia, permitindo várias declarações
procs:		PR_FUNCAO IDENTIFICADOR PR_ENTRADA { pilha.clear(); } l_var PR_SAIDA { pilha.clear(); } l_var decl cmds PR_FIM_FUNCAO procs {}
		|	PR_PROCMTO IDENTIFICADOR PR_ENTRADA { pilha.clear(); } l_var decl cmds PR_FIM_PROCMTO procs {}
		|	PR_FUNCAO error PR_FIM_FUNCAO procs { printf("On FUNCAO definition. ignoring...\n\n"); }
		|	PR_PROCMTO error PR_FIM_PROCMTO procs { printf("On PROCMTO definition. ignoring...\n\n"); }
		|	%empty {};

exp:		exp_l {}
		|	exp_a {};

exp_a:		term_a muldiv exp_a {}
		|	term_a {};

term_a:		fat_a adisub term_a {}
		|	fat_a {};

fat_a:		exp_a OP_ARIT_EXPO exp_a {}
		|	exp_a OP_ARIT_RAD exp_a {}
		|	ABRE_PAR exp_a FECHA_PAR {}
		|	func ABRE_PAR { pilha.clear(); } l_var FECHA_PAR {}
		|	var {}
		|	NUM_INTEIRO {}
		|	NUM_REAL {};

muldiv:		OP_ARIT_MULT {}
		|	OP_ARIT_DIV {};

adisub:		OP_ARIT_ADI {}
		|	OP_ARIT_SUB {};

func:		PR_ABS { put("ABS"); }
		|	PR_TRUNCA { put("TRUNCA"); }
		|	PR_RESTO { put("RESTO"); }
		|	IDENTIFICADOR {} // Nova produção para "func": uma chamada de função feita pelo programador

exp_l:		rel op_log exp_l {}
		|	OP_LOG_NAO ABRE_PAR rel FECHA_PAR {}
		| 	rel {};

rel:		fat_r op_rel fat_r {};

fat_r:		fat_a {}
		|	CONST_LIT {};

op_log:		OP_LOG_AND {}
		|	OP_LOG_OR {};

op_rel:		OP_REL_IGUAL {}
		|	OP_REL_NAOIGUAL {}
		|	OP_REL_MAIOR {}
		|	OP_REL_MAIORIGUAL {}
		|	OP_REL_MENOR {}
		|	OP_REL_MENORIGUAL {};

cond:		ABRE_PAR exp_l FECHA_PAR {}
		|	ABRE_PAR error FECHA_PAR { printf("Bad condition.\n\n"); };
