let s:save_cpo= &cpo
set cpo&vim

let s:publisher= {
\ '__subscribers': {},
\}

function! s:_vital_loaded(V)
  let s:Sub= a:V.import('Event.Subscriber')
endfunction

function! s:_vital_depends()
  return ['Event.Subscriber']
endfunction

function! s:publisher.subscribe(event, expr)
  let subscriber= s:Sub.wrap(a:event, a:expr)
  let subscribers= get(self.__subscribers, a:event, [])

  let subscribers+= [subscriber]

  let self.__subscribers[a:event]= subscribers
endfunction

function! s:publisher.unsubscribe(event, expr)
  let subscriber= s:Sub.wrap(a:event, a:expr)
  let subscribers= get(self.__subscribers, a:event, [])

  let self.__subscribers[a:event]= filter(subscribers, '!v:val.equals(subscriber)')
endfunction

function! s:publisher.publish(event, ...)
  let subscribers= get(self.__subscribers, a:event, [])

  for subscriber in subscribers
      call subscriber.invoke({'event': a:event, 'data': a:000})
  endfor
endfunction

function! s:new()
  return deepcopy(s:publisher)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
" vim: tabstop=2 shiftwidth=2 expandtab
