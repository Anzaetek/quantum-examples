" Vim/Neovim syntax for the Aria HDL DSL (fpga-meta-compiler).
" Reference grammar: fpga-meta-compiler/DSL_SYNTAX.md.

if exists("b:current_syntax")
  finish
endif

syntax case match

" --- Comments ----------------------------------------------------------------
syntax match ariaHdlComment "--.*$" contains=@Spell

" --- Annotations -------------------------------------------------------------
syntax match ariaHdlAnnotation      "@\(clock_freq\|reset\|enable\|pragma\|hint\|target\)\>"
syntax match ariaHdlAnnotationOther "@[a-zA-Z_][a-zA-Z0-9_]*"

" --- Strings -----------------------------------------------------------------
syntax region ariaHdlString start=+"+ skip=+\\"+ end=+"+ contains=ariaHdlEscape
syntax match  ariaHdlEscape "\\." contained

" --- Keywords ----------------------------------------------------------------
syntax keyword ariaHdlDeclaration module pipeline systolic struct enum
syntax keyword ariaHdlBinding     const let var fn
syntax keyword ariaHdlControl     when match if else forall in stage
syntax keyword ariaHdlStream      stream fifo approx pe
syntax keyword ariaHdlFormal      assert assume cover
syntax keyword ariaHdlTemporal    always never eventually next
syntax keyword ariaHdlFlowDir     left right up down accumulate flow

syntax keyword ariaHdlConstant true false

" --- Concrete primitive types -----------------------------------------------
syntax keyword ariaHdlTypeBuiltin fp64 fp32 fp16 bf16 fp8e4m3 fp8e5m2 bit

" --- Parameterized types: int<...>, fix<...>, stream<...> -------------------
syntax match ariaHdlTypeParam "\<\(int\|uint\|bits\|fix\|ufix\|float\|mx\|stream\)\>\ze\s*<"

" --- Builtin functions ------------------------------------------------------
syntax match ariaHdlBuiltin "\<\(sin\|cos\|tan\|sqrt\|exp\|log\|abs\|floor\|ceil\|min\|max\|read\|write\)\>\ze("

" --- Numbers (with `_` digit separators, hex, sci) --------------------------
syntax match ariaHdlHex     "\<0x[0-9a-fA-F][0-9a-fA-F_]*\>"
syntax match ariaHdlFloat   "\<[0-9][0-9_]*\.[0-9][0-9_]*\([eE][+-]\?[0-9]\+\)\?\>"
syntax match ariaHdlInteger "\<[0-9][0-9_]*\([eE][+-]\?[0-9]\+\)\?\>"

" --- Type annotation `name : type` ------------------------------------------
syntax match ariaHdlType "\(:\s*\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"

" --- Module/pipeline name in declaration ------------------------------------
syntax match ariaHdlModuleName "\(\<\(module\|pipeline\|systolic\|struct\|enum\)\s\+\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"

" --- Operators ---------------------------------------------------------------
syntax match ariaHdlPipe      "|>"
syntax match ariaHdlUpdate    ":="
syntax match ariaHdlArrow     "->"
syntax match ariaHdlRange     "\.\."
syntax match ariaHdlOpLogic   "&&\|||\|!"
syntax match ariaHdlOpCompare "==\|!=\|<=\|>=\|<\|>"
syntax match ariaHdlOpAssign  "="
syntax match ariaHdlOpArith   "[+\-*/^%]"

" --- Highlight links ---------------------------------------------------------
highlight default link ariaHdlComment           Comment
highlight default link ariaHdlAnnotation        PreProc
highlight default link ariaHdlAnnotationOther   PreProc
highlight default link ariaHdlString            String
highlight default link ariaHdlEscape            SpecialChar
highlight default link ariaHdlDeclaration       Structure
highlight default link ariaHdlBinding           StorageClass
highlight default link ariaHdlControl           Repeat
highlight default link ariaHdlStream            Statement
highlight default link ariaHdlFormal            Special
highlight default link ariaHdlTemporal          Special
highlight default link ariaHdlFlowDir           Statement
highlight default link ariaHdlConstant          Constant
highlight default link ariaHdlTypeBuiltin       Type
highlight default link ariaHdlTypeParam         Type
highlight default link ariaHdlBuiltin           Function
highlight default link ariaHdlHex               Number
highlight default link ariaHdlFloat             Float
highlight default link ariaHdlInteger           Number
highlight default link ariaHdlType              Type
highlight default link ariaHdlModuleName        Title
highlight default link ariaHdlPipe              Operator
highlight default link ariaHdlUpdate            Operator
highlight default link ariaHdlArrow             Operator
highlight default link ariaHdlRange             Operator
highlight default link ariaHdlOpLogic           Operator
highlight default link ariaHdlOpCompare         Operator
highlight default link ariaHdlOpAssign          Operator
highlight default link ariaHdlOpArith           Operator

let b:current_syntax = "aria_hdl"
