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

let s:V= vital#of('jabug')
let s:PM= s:V.import('ProcessManager')
let s:BM= s:V.import('Vim.BufferManager')
unlet s:V

let s:active_jabugs= []

let s:jabug= {}

function! jabug#start(options, class, arguments)
    let cmd= ['jdb']

    let cmd+= a:options
    let cmd+= [a:class]
    let cmd+= a:arguments

    let jabug= deepcopy(s:jabug)

    let jabug.__process= s:PM.of(s:unique_id(), join(cmd, ' '))
    let jabug.__endpatterns= ['\s*>\s*']

    if jabug.__process.is_new()
        call jabug.__process.reserve_wait(jabug.__endpatterns)
    endif

    " initialize buffer
    let jabug.__buffers= {
    \   'source':  s:BM.new({'range': 'tabpage'}),
    \   'command': s:BM.new({'range': 'tabpage'}),
    \   'info':    s:BM.new({'range': 'tabpage'}),
    \}

    call jabug.__buffers.source.open('[source pane]', {'opener': 'new'})
    only

    call jabug.__buffers.command.open('[command pane]', {'opener': 'botright new'})
    resize 5
    nnoremap <buffer><silent> <CR> :<C-U>silent<Space>call<Space>jabug#handle_command()<CR>

    call jabug.__buffers.info.open('[info pane]', {'opener': 'botright vnew'})

    call jabug.__buffers.command.move()

    " initialize timer
    augroup jabug-timer
        autocmd!
        autocmd CursorHold,CursorHoldI * call jabug#on_idle()
    augroup END

    let s:active_jabugs+= [jabug]
endfunction

function! jabug#on_idle()
    for jabug in s:active_jabugs
        call jabug.on_idle()
    endfor
endfunction

function! jabug#handle_command()
    for jabug in s:active_jabugs
        call jabug.handle_command()
    endfor
endfunction

function! s:jabug.on_idle()
    if self.__process.is_idle()
        return
    endif

    let bulk= self.__process.go_bulk()
    if bulk.done && self.__buffers.info.move()
        %delete _
        0put=bulk.err
        0put=bulk.out
        wincmd p
    endif
endfunction

function! s:jabug.handle_command()
    if !self.__buffers.command.is_managed(bufnr('%'))
        return
    endif

    call self.send(join(getline(1, '$'), ' '))
    %delete _
endfunction

function! s:jabug.send(command)
    call self.__process.reserve_writeln(a:command)
    call self.__process.reserve_read(self.__endpatterns)
endfunction

function! s:unique_id()
    if !exists('s:id_sequence')
        let s:id_sequence= 0
    endif
    let s:id_sequence+= 1
    return s:id_sequence
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
