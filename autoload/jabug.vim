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
let s:Pub= s:V.import('Event.Publisher')
let s:L= s:V.import('Data.List')
let s:WL= s:V.import('Window.Layout')
unlet s:V

let s:publisher= s:Pub.new()

let s:jabug= {}

function! jabug#start(options, class, arguments)
    let cmd= ['jdb']

    let cmd+= a:options
    let cmd+= [a:class]
    let cmd+= a:arguments

    let jabug= deepcopy(s:jabug)

    let jabug.__process= s:PM.of(s:unique_id(), join(cmd, ' '))
    let jabug.__endpatterns= ['\s*>\s*', '\Cmain\[\d\+\]\s*']
    let jabug.__publisher= s:publisher

    if jabug.__process.is_new()
        call jabug.__process.reserve_wait(jabug.__endpatterns)
    endif

    " initialize buffer
    let jabug.__layout= s:WL.new()

    call jabug.__layout.apply(
    \   [
    \       {'id': 'source',  'bufname': '[source pane]',  'initializer': [jabug.initialize_source_pane, jabug]},
    \       {'id': 'command', 'bufname': '[command pane]', 'initializer': [jabug.initialize_command_pane, jabug]},
    \       {'id': 'info',    'bufname': '[info pane]',    'initializer': [jabug.initialize_info_pane, jabug]},
    \   ],
    \   {
    \       'layout': 'border',
    \       'west': {
    \           'layout': 'border',
    \           'north':  {'bufref': 'source',  'walias': 'source'},
    \           'center': {'bufref': 'command', 'walias': 'command', 'height': 1},
    \       },
    \       'east': {'bufref': 'info', 'walias': 'info', 'width': 0.5},
    \   }
    \)

    " initialize timer
    let s:save_updatetime= &updatetime
    let &updatetime= 100

    augroup jabug-timer
        autocmd!
        autocmd CursorHold,CursorHoldI * call s:on_idle()
        autocmd CursorHold * call feedkeys("g\<ESC>", 'n')
        autocmd CursorHoldI * call feedkeys("a\<BS>", 'n')
        autocmd TabEnter * call s:keep_updatetime('TabEnter')
        autocmd TabLeave * call s:keep_updatetime('TabLeave')
    augroup END

    let t:jabug= jabug
endfunction

function! s:on_idle()
    if has_key(t:, 'jabug')
        call t:jabug.on_idle()
    endif
endfunction

function! jabug#subscribe(event, expr)
    call s:publisher.subscribe(a:event, a:expr)
endfunction

function! jabug#unsubscribe(event, expr)
    call s:publisher.unsubscribe(a:event, a:expr)
endfunction

function! s:jabug.on_idle()
    if self.__process.is_idle()
        return
    endif

    let bulk= self.__process.go_bulk()
    if bulk.done
        let winnr= self.__layout.winnr('info')
        execute winnr 'wincmd w'

        %delete _
        0put=bulk.err
        0put=bulk.out
        wincmd p
    elseif bulk.fail
        call self.__process.shutdown()
        echomsg 'Bye!'
        windo bw%
    endif
endfunction

function! s:jabug.handle_command()
    let winnr= self.__layout.winnr('command')
    execute winnr 'wincmd w'

    call self.send(join(getline(1, '$'), ' '))
    %delete _
endfunction

function! s:jabug.start_input(k)
    let winnr= self.__layout.winnr('command')
    execute winnr 'wincmd w'

    if a:k ==# 'i' || a:k ==# 'I'
        startinsert
    elseif a:k ==# 'a' || a:k ==# 'A'
        startinsert!
    else
        startinsert
    endif
endfunction

function! s:jabug.send(command)
    call self.__process.reserve_writeln(a:command)
    call self.__process.reserve_read(self.__endpatterns)
endfunction

function! s:jabug.initialize_source_pane()
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted readonly filetype=jabug-source

    nnoremap <buffer><silent> i :<C-U>silent<Space>call<Space>t:jabug.start_input('i')<CR>
    nnoremap <buffer><silent> I :<C-U>silent<Space>call<Space>t:jabug.start_input('I')<CR>
    nnoremap <buffer><silent> a :<C-U>silent<Space>call<Space>t:jabug.start_input('a')<CR>
    nnoremap <buffer><silent> A :<C-U>silent<Space>call<Space>t:jabug.start_input('A')<CR>

    call self.__publisher.publish('open_source_pane')
endfunction

function! s:jabug.initialize_command_pane()
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted filetype=jabug-command

    nnoremap <buffer><silent> <CR> :<C-U>silent<Space>call<Space>t:jabug.handle_command()<CR>

    call self.__publisher.publish('open_command_pane')
endfunction

function! s:jabug.initialize_info_pane()
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted readonly filetype=jabug-info

    nnoremap <buffer><silent> i :<C-U>silent<Space>call<Space>t:jabug.start_input('i')<CR>
    nnoremap <buffer><silent> I :<C-U>silent<Space>call<Space>t:jabug.start_input('I')<CR>
    nnoremap <buffer><silent> a :<C-U>silent<Space>call<Space>t:jabug.start_input('a')<CR>
    nnoremap <buffer><silent> A :<C-U>silent<Space>call<Space>t:jabug.start_input('A')<CR>

    call self.__publisher.publish('open_info_pane')
endfunction

function! s:unique_id()
    if !exists('s:id_sequence')
        let s:id_sequence= 0
    endif
    let s:id_sequence+= 1
    return s:id_sequence
endfunction

function! s:jabug_tabpagenrs()
    let tabpagenrs= []
    for tabpagenr in range(1, tabpagenr('$'))
        if !empty(gettabvar(tabpagenr, 'jabug', {}))
            let tabpagenrs+= [tabpagenr]
        endif
    endfor
    return tabpagenrs
endfunction

function! s:keep_updatetime(event)
    let in_jabug_tabpage= s:L.has(s:jabug_tabpagenrs(), tabpagenr())

    if a:event ==# 'TabLeave' && in_jabug_tabpage
        let &updatetime= s:save_updatetime
    elseif a:event ==# 'TabEnter' && in_jabug_tabpage
        let s:save_updatetime= &updatetime
        let &updatetime= 100
    endif
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
