" Vim/Neovim syntax for the Aria financial-contract DSL (Sibelius).
" Reference grammar: Sibelius/AriaParser.cpp + AriaSpec.md.

if exists("b:current_syntax")
  finish
endif

syntax case match

" --- Comments ----------------------------------------------------------------
syntax match ariaFinComment "--.*$" contains=@Spell

" --- Strings -----------------------------------------------------------------
syntax region ariaFinString start=+"+ skip=+\\"+ end=+"+ contains=ariaFinEscape
syntax match  ariaFinEscape "\\." contained

" --- ISO dates (YYYY-MM-DD) --------------------------------------------------
syntax match ariaFinDate "\<\d\{4}-\d\{2}-\d\{2}\>"

" --- Keywords ----------------------------------------------------------------
syntax keyword ariaFinDeclaration contract
syntax keyword ariaFinBinding     let var
syntax keyword ariaFinControl     when for in schedule period

syntax keyword ariaFinConstant true false

" --- Combinators (core contract building blocks) ----------------------------
syntax keyword ariaFinCombinator zero one give and or scale anytime until
syntax keyword ariaFinCombinator cond cash_flow on barrier terminate autocall

" --- Barrier directions -----------------------------------------------------
syntax keyword ariaFinBarrierDir up_in up_out down_in down_out

" --- Builtin functions (call sites) -----------------------------------------
syntax match ariaFinBuiltin "\<\(spot\|rate\|fxrate\|daycount\|discount\|max\|min\|abs\|exp\|log\|running_max\|running_min\|prev\|is_holiday\|smooth_step\|credit_event\|survival\|credit_leg\|sum\|prod\|len\)\>\ze("

" --- Numbers -----------------------------------------------------------------
syntax match ariaFinFloat   "\<[0-9]\+\.[0-9]\+\([eE][+-]\?[0-9]\+\)\?\>"
syntax match ariaFinInteger "\<[0-9]\+\>"

" --- Type annotation `name : type` ------------------------------------------
syntax match ariaFinType "\(:\s*\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"

" --- Contract name in declaration -------------------------------------------
syntax match ariaFinContractName "\(\<contract\s\+\)\@<=[A-Z][a-zA-Z0-9_]*"

" --- Operators ---------------------------------------------------------------
syntax match ariaFinPipe      "|>"
syntax match ariaFinUpdate    ":="
syntax match ariaFinRange     "\.\."
syntax match ariaFinOpLogic   "&&\|||\|!"
syntax match ariaFinOpCompare "==\|!=\|<=\|>=\|<\|>"
syntax match ariaFinOpAssign  "="
syntax match ariaFinOpArith   "[+\-*/^%]"

" --- Highlight links ---------------------------------------------------------
highlight default link ariaFinComment           Comment
highlight default link ariaFinString            String
highlight default link ariaFinEscape            SpecialChar
highlight default link ariaFinDate              Special
highlight default link ariaFinDeclaration       Structure
highlight default link ariaFinBinding           Keyword
highlight default link ariaFinControl           Repeat
highlight default link ariaFinConstant          Constant
highlight default link ariaFinCombinator        Type
highlight default link ariaFinBarrierDir        Constant
highlight default link ariaFinBuiltin           Function
highlight default link ariaFinFloat             Float
highlight default link ariaFinInteger           Number
highlight default link ariaFinType              Type
highlight default link ariaFinContractName      Title
highlight default link ariaFinPipe              Operator
highlight default link ariaFinUpdate            Operator
highlight default link ariaFinRange             Operator
highlight default link ariaFinOpLogic           Operator
highlight default link ariaFinOpCompare         Operator
highlight default link ariaFinOpAssign          Operator
highlight default link ariaFinOpArith           Operator

let b:current_syntax = "aria_fin"
