let s:save_cpo= &cpo
set cpo&vim

let s:subscriber= {
\ '__type':  0,
\ '__expr':  '',
\ '__event': '',
\}

function! s:_invoke_string(event) dict
  let expr= substitute(self.__expr, '\<v:val\>', string(a:event.data), 'g')
  execute expr
endfunction

function! s:_invoke_dict(event) dict
  call call(self.__expr[self.__event], a:event.data, self)
endfunction

function! s:_invoke_funcref(event) dict
  call call(self.__expr, a:event.data)
endfunction

function! s:subscriber.equals(subscriber)
  return (self.__type == a:subscriber.__type) && (self.__expr == a:subscriber.__expr)
endfunction

function! s:wrap(event, expr)
  let subscriber= deepcopy(s:subscriber)

  if type(a:expr) == type('')
    let subscriber.__type=  type('')
    let subscriber.__expr=  a:expr
    let subscriber.__event= a:event
    let subscriber.invoke=  function('s:_invoke_string')
  elseif type(a:expr) == type({})
    if !has_key(a:expr, a:event)
      throw printf("vital: Event.Subscriber: No such function `%s'", a:event)
    endif

    let subscriber.__type=  type({})
    let subscriber.__expr=  deepcopy(a:expr)
    let subscriber.__event= a:event
    let subscriber.invoke=  function('s:_invoke_dict')
  elseif type(a:expr) == type(function('tr'))
    let subscriber.__type=  type(function('tr'))
    let subscriber.__expr=  a:expr
    let subscriber.__event= a:event
    let subscriber.invoke=  function('s:_invoke_funcref')
  else
    throw 'vital: Event.Subscriber: Unsupported subscriber type'
  endif

  return subscriber
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
