" Vim/Neovim syntax for the Aria strategy DSL (gpu-backtest).
" Reference grammar: bt-dsl crate.

if exists("b:current_syntax")
  finish
endif

syntax case match

" --- Comments ----------------------------------------------------------------
syntax match  ariaStratComment      "--.*$"  contains=@Spell
syntax match  ariaStratCommentSlash "//.*$"  contains=@Spell
syntax region ariaStratCommentBlock start=+/\*+ end=+\*/+ contains=@Spell

" --- Strings -----------------------------------------------------------------
syntax region ariaStratString start=+"+ skip=+\\"+ end=+"+ contains=ariaStratEscape
syntax match  ariaStratEscape "\\." contained

" --- Keywords ----------------------------------------------------------------
syntax keyword ariaStratDeclaration signal strategy
syntax keyword ariaStratBinding     let var
syntax keyword ariaStratControl     when if else

syntax keyword ariaStratConstant true false

" --- Builtin functions (only at call sites) ----------------------------------
syntax match ariaStratBuiltin "\<\(sma\|ema\|cross_up\|cross_down\|run_max\|run_min\|prev\|stdev\|zscore\|percentile\|abs\|max\|min\|exp\|log\|linreg_slope\|hurst\)\>\ze("

" --- Order actions (call sites) ---------------------------------------------
syntax match ariaStratAction "\<\(buy\|sell\|flatten\|limit_buy\|limit_sell\|vwap\)\>\ze("

" --- Numbers -----------------------------------------------------------------
syntax match ariaStratFloat   "\<[0-9]\+\.[0-9]\+\([eE][+-]\?[0-9]\+\)\?\>"
syntax match ariaStratFloat   "\.[0-9]\+\([eE][+-]\?[0-9]\+\)\?\>"
syntax match ariaStratInteger "\<[0-9]\+\([eE][+-]\?[0-9]\+\)\?\>"

" --- Type annotation `name : type` ------------------------------------------
syntax match ariaStratType "\(:\s*\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"

" --- Strategy / signal name in declaration ----------------------------------
syntax match ariaStratStratName "\(\<strategy\s\+\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"
syntax match ariaStratSigName   "\(\<signal\s\+\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"

" --- Operators ---------------------------------------------------------------
syntax match ariaStratPipe     "|>"
syntax match ariaStratUpdate   ":="
syntax match ariaStratArrow    "->"
syntax match ariaStratOpLogic  "&&\|||\|!"
syntax match ariaStratOpCompare "==\|!=\|<=\|>=\|<\|>"
syntax match ariaStratOpAssign "="
syntax match ariaStratOpArith  "[+\-*/^%]"

" --- Highlight links ---------------------------------------------------------
highlight default link ariaStratComment       Comment
highlight default link ariaStratCommentSlash  Comment
highlight default link ariaStratCommentBlock  Comment
highlight default link ariaStratString        String
highlight default link ariaStratEscape        SpecialChar
highlight default link ariaStratDeclaration   Structure
highlight default link ariaStratBinding       Keyword
highlight default link ariaStratControl       Repeat
highlight default link ariaStratConstant      Constant
highlight default link ariaStratBuiltin       Function
highlight default link ariaStratAction        Statement
highlight default link ariaStratFloat         Float
highlight default link ariaStratInteger       Number
highlight default link ariaStratType          Type
highlight default link ariaStratStratName     Title
highlight default link ariaStratSigName       Identifier
highlight default link ariaStratPipe          Operator
highlight default link ariaStratUpdate        Operator
highlight default link ariaStratArrow         Operator
highlight default link ariaStratOpLogic       Operator
highlight default link ariaStratOpCompare     Operator
highlight default link ariaStratOpAssign      Operator
highlight default link ariaStratOpArith       Operator

let b:current_syntax = "aria_strat"
