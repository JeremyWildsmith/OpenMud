parser grammar DmlParser; // tiny version

options { tokenVocab=DmlLexer; }

tokens { INDENT, DEDENT }

dml_module: 
    ( NEWLINE
    | object_binop_override_definition
    | object_unop_override_definition
    | object_augasn_override_definition
    | object_copyInto_override_definition
    | object_unopasn_override_definition
    | object_function_definition
    | variable_declaration
    | object_tree_definition
    )* EOF;

identifier_name
  : NAME
  | 'list'
  | 'oview'
  | 'view'
  | 'usr'
  | 'loc'
  | 'contents'
  | 'world'
  | 'loc'
  | 'spawn'
  ;

initializer_assignment: path=declaration_object_tree_path ASSIGNMENT expr;

//In DreamMaker, 'var' can declare variables, but it can also be the name
//of a root node in the object graph.
reference_object_operator_path: (FWD_SLASH identifier_name)* OPERATOR;
operator_object_tree_path: FWD_SLASH? reference_object_operator_path;

reference_object_tree_path: (identifier_name) (FWD_SLASH identifier_name)*;
declaration_object_tree_path: FWD_SLASH? reference_object_tree_path;
object_tree_path_expr: FWD_SLASH reference_object_tree_path;

//reference_object_tree_path: declaration_object_tree_path;

array_decl: (OPEN_BRACKET sz=expr? CLOSE_BRACKET);
array_decl_list: array_decl+;

concrete_array_decl: (OPEN_BRACKET idx=expr CLOSE_BRACKET);
concrete_array_decl_list: concrete_array_decl+;

implicit_typed_variable_declaration
  : (
        (
            (
                object_type=reference_object_tree_path |
                primitive_type=identifier_name
            )
            FWD_SLASH
        )? name=identifier_name array=array_decl_list?
    )
    (ASSIGNMENT assignment=expr)?
  ;

implicit_untyped_variable_declaration
  : (name=identifier_name array=array_decl_list? (AS primitive_type=identifier_name)?)
    (ASSIGNMENT assignment=expr)?
  ;

implicit_variable_declaration
  : (VAR FWD_SLASH)? implicit_typed_variable_declaration
  | VAR? implicit_untyped_variable_declaration
  ;

variable_declaration
  : VAR FWD_SLASH implicit_typed_variable_declaration
  | VAR implicit_untyped_variable_declaration
  ;

expr_lhs
  : lhs=identifier_name                    #expr_lhs_variable
  | expr_lhs (DOT | COLON) identifier_name #expr_lhs_property
  ;

array_expr_lhs
  : expr_lhs indexers=concrete_array_decl_list?;

//Object Tree Definitions
object_tree_definition
  : VAR (FWD_SLASH modifier=identifier_name)? vars_inner=object_tree_var_suite
  | scope=declaration_object_tree_path inner=object_tree_suite
  | scope=declaration_object_tree_path
  ;

object_tree_stmt
  : object_binop_override_definition
  | object_unop_override_definition
  | object_augasn_override_definition
  | object_copyInto_override_definition
  | object_unopasn_override_definition
  | object_function_definition
  | (
      (initializer_assignment | variable_declaration)
      NEWLINE
    )
  | object_tree_definition;

object_tree_suite: NEWLINE (INDENT object_tree_stmt+ DEDENT)?;
object_tree_var_suite: NEWLINE (INDENT ((initializer_assignment | implicit_variable_declaration | NAME) NEWLINE)+ DEDENT)? ;

//Function Definitions

object_function_definition: 
  name=declaration_object_tree_path parameters=parameter_list 
    (AS (identifier_name | object_tree_path_expr))? body=suite;

object_binop_override_definition:
  name=operator_object_tree_path operator=bin_op parameters=non_empty_parameter_list body=suite;  

object_unop_override_definition:
  name=operator_object_tree_path operator=un_op parameters=empty_parameter_list body=suite;  

object_unopasn_override_definition:
  name=operator_object_tree_path operator=un_op_asn parameters=parameter_list body=suite;  

object_augasn_override_definition:
  name=operator_object_tree_path operator=augAsnOp parameters=parameter_list body=suite;

object_copyInto_override_definition:
  name=operator_object_tree_path operator=COPYINTO_ASSIGNMENT parameters=parameter_list body=suite;

parameter_as_constraint
  : NULL
  | identifier_name
  ;

parameter_aslist: parameter_as_constraint (BITWISE_OR parameter_as_constraint)*;

constant_list: OPEN_PARENS CLOSE_PARENS;

parameter_constraint_set
  : SET_IN USR DOT CONTENTS                      #parameter_constraint_set_usr_contents
  | SET_IN USR DOT LOC                               #parameter_constraint_set_usr_loc
  | SET_IN USR DOT GROUP                         #parameter_constraint_set_usr_group
  | SET_IN OVIEW OPEN_PARENS (arg=NUMBER)? CLOSE_PARENS       #parameter_constraint_set_oview
  | SET_IN VIEW  OPEN_PARENS (arg=NUMBER)? CLOSE_PARENS       #parameter_constraint_set_view
  | SET_IN LIST args=argument_list                #parameter_constraint_set_list_list_eval
  | SET_IN WORLD                                  #parameter_constraint_set_inworld
  ;

parameter
  : (VAR FWD_SLASH)? ((object_ref_type=reference_object_tree_path | primitive_type=identifier_name) FWD_SLASH?)? (name=identifier_name (ASSIGNMENT init=expr)? (AS as_constraints=parameter_aslist)? set_constraints=parameter_constraint_set? )
  | (name=identifier_name (ASSIGNMENT init=expr)?)
  ;
  
empty_parameter_list: OPEN_PARENS CLOSE_PARENS ;
non_empty_parameter_list: OPEN_PARENS (parameter (COMMA parameter)*)+ CLOSE_PARENS ;
parameter_list: OPEN_PARENS (parameter (COMMA parameter)*)? CLOSE_PARENS ;
argument_list_item: (arg_name=identifier_name ASSIGNMENT)? expr ;
argument_list: OPEN_PARENS (argument_list_item (COMMA argument_list_item)*)? CLOSE_PARENS ;
//Code Blocks

stmt: simple_stmt | compound_stmt;

simple_stmt: small_stmt NEWLINE;

return_stmt: RETURN ret=expr?;
small_stmt
  : new_call_implicit
  | variable_declaration
  | flow_stmt
  | prereturn_assignment
  | expr
  | return_stmt
  | set_src_statement
  | config_statement
  | del_statement
  ;


new_call_implicit:
  dest=identifier_name ASSIGNMENT NEW FWD_SLASH? arglist=argument_list?
  ;

del_statement: DEL target=expr;
read_statement: l=expr OP_RIGHT_SHIFT r=expr_lhs;

config_statement: SET cfg_key=identifier_name ASSIGNMENT cfg_value=expr;

set_src_statement
    : SRC_SET_IN USR DOT CONTENTS            # set_src_contents
    | SRC_SET_IN USR DOT LOC                   # set_src_loc
    | SRC_SET_IN USR DOT GROUP                 # set_src_group
    | SRC_SET_IN OVIEW OPEN_PARENS (arg=NUMBER)? CLOSE_PARENS # set_src_oview
    | SRC_SET_IN VIEW OPEN_PARENS (arg=NUMBER)? CLOSE_PARENS  # set_src_view
    | SRC_SET_IN USR                       # set_src_user
    ;

    
basic_assignment: dest=expr_lhs ASSIGNMENT src=expr;
copyinto_assignment: dest=expr_lhs COPYINTO_ASSIGNMENT src=expr;

array_basic_assignment: dest=array_expr_lhs asn_idx=concrete_array_decl ASSIGNMENT src=expr;
array_copyinto_assignment: dest=array_expr_lhs asn_idx=concrete_array_decl  COPYINTO_ASSIGNMENT src=expr;

augAsnOp
  : OP_ADD_ASSIGNMENT
  | OP_SUB_ASSIGNMENT
  | OP_MULT_ASSIGNMENT
  | OP_DIV_ASSIGNMENT
  | OP_MOD_ASSIGNMENT
  | OP_INT_MOD_ASSIGNMENT
  | OP_OR_ASSIGNMENT
  | OP_AND_ASSIGNMENT
  | OP_XOR_ASSIGNMENT
  | OP_LEFT_SHIFT_ASSIGNMENT
  | OP_RIGHT_SHIFT_ASSIGNMENT
  ;

prereturn_assignment: DOT ASSIGNMENT src=expr;
augmented_assignment: dest=expr_lhs op=augAsnOp
  src=expr;

array_augmented_assignment: dest=array_expr_lhs asn_idx=concrete_array_decl op=augAsnOp
  src=expr;

unop_asn_expr
  : unop=un_op_asn inner=expr_lhs #expr_unary_pre
  | inner=expr_lhs unop=un_op_asn #expr_unary_post
  ;

expr_complex
  : new_call_explicit
  | self_call
  | super_call
  | method_call
  | static_call
  | augmented_assignment
  | copyinto_assignment
  | basic_assignment
  | array_augmented_assignment
  | array_copyinto_assignment
  | array_basic_assignment
  | instance_call
  | unop_asn_expr
  ;
  
new_call_operand
  : l=expr_lhs OPEN_BRACKET r=expr CLOSE_BRACKET #new_call_arridx_operand
  | expr_eval=expr_lhs #new_call_expr_eval
  | object_tree_path_expr #new_call_type_literal
  ;

new_call_explicit:
  NEW type_hint_eval=new_call_operand? FWD_SLASH? arglist=argument_list?
  ;

self_call:
  DOT argument_list
  ;

super_call:
  OP_SUPER argument_list
  ;

method_call:
  name=identifier_name argument_list;

instance_call:
  expr_lhs (DOT | COLON) name=identifier_name argument_list;

static_call:
  object_tree_path_expr argument_list;


forlist_stmt
  : FOR OPEN_PARENS iter_var=identifier_name SET_IN collection=expr CLOSE_PARENS suite #forlist_list_recycle_in
  | FOR OPEN_PARENS bag=variable_declaration SET_IN collection=expr CLOSE_PARENS suite #forlist_decl_in
  | FOR OPEN_PARENS VAR path=object_tree_path_expr CLOSE_PARENS suite #forlist_list_in
  ;

for_stmt:
  FOR OPEN_PARENS
    initilizer=basic_assignment SEMICOLON
    loop_test=expr SEMICOLON
    update=expr
  CLOSE_PARENS;

flow_stmt: break_stmt | continue_stmt;
break_stmt: BREAK;
continue_stmt: CONTINUE;

compound_stmt: for_stmt | forlist_stmt | if_stmt | do_while_stmnt | while_stmt | switch_stmnt | spawn_stmt;

switch_numset
  : NUMBER (COMMA NUMBER)*
  ;

switch_range
  : from_range=NUMBER TO to_range=NUMBER
  ;

switch_constraint
  : switch_numset
  | switch_range
  | expr
  ;

switch_case
  : (IF OPEN_PARENS switch_constraint CLOSE_PARENS suite)
  ;

switch_stmnt: SWITCH OPEN_PARENS expr CLOSE_PARENS NEWLINE INDENT
  switch_case+
  (ELSE else_suite=suite)?
  DEDENT
  ;

if_stmt: IF OPEN_PARENS test=expr CLOSE_PARENS pass=suite (ELSE IF OPEN_PARENS elif_test=expr CLOSE_PARENS elif_pass=suite)* (ELSE else_pass=suite)?;
spawn_stmt: SPAWN OPEN_PARENS delay=expr CLOSE_PARENS run=suite;

do_while_stmnt: DO suite DEDENT WHILE OPEN_PARENS expr CLOSE_PARENS NEWLINE INDENT;

while_stmt: WHILE OPEN_PARENS expr CLOSE_PARENS suite;
suite
  : simple_stmt #suite_single_stmt
  | NEWLINE INDENT stmt+ DEDENT #suite_multi_stmt
  | NEWLINE #suite_empty;

bit_op: (OP_LEFT_SHIFT | OP_RIGHT_SHIFT | CARET |  BITWISE_OR | AMP);
mul_op: (OP_POWER | PERCENT | STAR | FWD_SLASH | INT_PERCENT);
arith_op: (PLUS | MINUS );
cmp_op: (GT | LT | OP_GE | OP_LE | OP_EQ | OP_EQUIV | OP_NE);
logic_op: (OP_OR | OP_AND | SET_IN);
bin_op: logic_op | cmp_op | bit_op | arith_op;
un_op: (MINUS | BANG | TILDE);
un_op_asn: ( OP_INC | OP_DEC );

list_expr:
  LIST OPEN_PARENS (expr (COMMA expr)*)? CLOSE_PARENS;

null_expr: NULL;

expr
 : null_expr #expr_null
 | ISTYPE OPEN_PARENS varname=identifier_name (COMMA typename=expr)? CLOSE_PARENS #expr_istype_local
 | ISTYPE OPEN_PARENS varname=expr_lhs (COMMA typename=expr)? CLOSE_PARENS #expr_istype_property
 | object_tree_path_expr # expr_type
 | l=expr OPEN_BRACKET r=expr CLOSE_BRACKET #expr_index
 | list_expr #expr_list_literal
 | unop=un_op inner=expr #expr_unary
 | expr_lhs #expr_lhs_stub
 | expr (DOT | COLON) identifier_name #expr_property
 | literal=NUMBER  #expr_int_literal
 | literal=DECIMAL #expr_dec_literal
 | OPEN_PARENS inner=expr CLOSE_PARENS #expr_grouped
 | expr INTERR expr COLON expr #expr_turnary
 | expr_complex #expr_stmnt_stub
 | STRING #expr_string_literal
 | RESOURCE #expr_resource_identifier
 | left=expr op=mul_op right=expr #expr_mul_binary
 | left=expr op=arith_op right=expr #expr_arith_binary
 | left=expr op=cmp_op right=expr #expr_cmp_binary
 | left=expr op=bit_op right=expr #expr_bit_binary
 | left=expr op=logic_op right=expr #expr_logic_binary
;