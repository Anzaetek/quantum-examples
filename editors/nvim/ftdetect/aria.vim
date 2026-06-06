" Aria multi-dialect filetype detection.
" Routing precedence (highest first):
"   1. modeline `-- aria: <variant>` on line 1
"   2. extension (.ahdl -> hdl)
"   3. workspace path token (/quantum/, /Sibelius/, /gpu-backtest/, /fpga-meta-compiler/)
"   4. content sniff (qreg/circuit, contract/cash_flow, signal/strategy)
"   5. fallback for .aria: aria_strat
"
" `.fs` is special: vim's built-in filetype.vim claims it as F# before our
" ftdetect runs. We force aria_fin only when we have strong evidence
" (modeline or /Sibelius/ path); otherwise we leave the existing detection
" alone so genuine F# files keep their highlighting.

function! s:DetectAria() abort
  let l:path = expand('%:p')
  let l:ext  = expand('%:e')

  " 1. Modeline on line 1 — always wins, force-override.
  let l:line1 = getline(1)
  let l:m = matchlist(l:line1, '^\s*--\s*aria:\s*\(strat\|quantum\|hdl\|fin\)\>')
  if !empty(l:m)
    execute 'setlocal filetype=aria_' . l:m[1]
    return
  endif

  " 2. Extension.
  if l:ext ==# 'ahdl'
    setlocal filetype=aria_hdl
    return
  endif

  " For .fs: only force-override if path is under Sibelius (genuine Aria/Finesmith).
  if l:ext ==# 'fs'
    if l:path =~# '/Sibelius/'
      setlocal filetype=aria_fin
    endif
    return
  endif

  " From here on we're handling .aria — always override.
  if l:ext !=# 'aria'
    return
  endif

  " 3. Workspace path token.
  if l:path =~# '/quantum/'
    setlocal filetype=aria_quantum
    return
  endif
  if l:path =~# '/Sibelius/'
    setlocal filetype=aria_fin
    return
  endif
  if l:path =~# '/fpga-meta-compiler/'
    setlocal filetype=aria_hdl
    return
  endif
  if l:path =~# '/gpu-backtest/'
    setlocal filetype=aria_strat
    return
  endif

  " 4. Content sniff (first 200 lines).
  let l:head = join(getline(1, min([200, line('$')])), "\n")
  if l:head =~# '\v<(circuit|qreg|observable)>'
    setlocal filetype=aria_quantum
    return
  endif
  if l:head =~# '\v<(contract|cash_flow)>'
    setlocal filetype=aria_fin
    return
  endif
  if l:head =~# '\v<(module|pipeline|systolic)>'
    setlocal filetype=aria_hdl
    return
  endif
  if l:head =~# '\v<(signal|strategy)>'
    setlocal filetype=aria_strat
    return
  endif

  " 5. Fallback for unrouted .aria.
  setlocal filetype=aria_strat
endfunction

augroup AriaFiletypeDetect
  autocmd!
  autocmd BufRead,BufNewFile *.aria,*.ahdl,*.fs call s:DetectAria()
augroup END
