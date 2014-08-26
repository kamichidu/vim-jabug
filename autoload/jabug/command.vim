" The MIT License (MIT)
"
" Copyright (c) 2014 kamichidu
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
let s:save_cpo= &cpo
set cpo&vim

function! jabug#command#start()
    let define= {
    \   'comp':      'jabug#command#start_comp',
    \   'prompt':    'jabug#command#start_prompt',
    \   'submitted': 'jabug#command#start_submitted',
    \}

    call alti#init(define)
endfunction

function! jabug#command#start_comp(arg_lead, cmd_line, cursor_pos)
    let arginfo= alti#get_arginfo()

    if arginfo.ordinal == 1
    elseif arginfo.ordinal == 2
    endif

    return []
endfunction

function! jabug#command#start_prompt(arg_lead, cmd_line, cursor_pos)
    let arginfo= alti#get_arginfo()

    if arginfo.ordinal == 1
        return 'Input jvm args separated comma>>>'
    elseif arginfo.ordinal == 2
        return 'Input entry classname>>>'
    elseif arginfo.ordinal == 3
        return 'Input application args>>>'
    endif

    return ''
endfunction

function! jabug#command#start_submitted(input, last_state)
    call jabug#start([], '', [])
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
