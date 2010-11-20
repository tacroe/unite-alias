let s:save_cpo = &cpo
set cpo&vim

if !exists('g:unite_source_alias_aliases')
  let g:unite_source_alias_aliases = {}
endif

let s:default_sources = {}

function! unite#sources#alias#define()
  return s:make_aliases()
endfunction

function! s:make_aliases()
  let l:aliases = []
  for [key, params] in items(g:unite_source_alias_aliases)
    let l:args = (type(params.args) == type([])) ? params.args : [params.args]
    let l:alias = {
          \   'name': key,
          \   'source__source': params.source,
          \   'source__args': l:args,
          \ }

    function! l:alias.gather_candidates(args, context)
      let l:source = s:get_source(self.source__source)
      if empty(l:source)
        return []
      endif
      let l:originals = l:source.gather_candidates(self.source__args, a:context)
      let l:candidates = []
      for l:candidate in l:originals
        let l:candidate.source = self.name
        call add(l:candidates, l:candidate)
      endfor
      return l:candidates
    endfunction

    call add(l:aliases, l:alias)
  endfor
  return l:aliases
endfunction

function! s:get_source(source_name)
  if empty(s:default_sources)
    call s:load_default_sources()
  endif
  if !has_key(s:default_sources, a:source_name)
    return {}
  endif
  return s:default_sources[a:source_name]
endfunction

function! s:load_default_sources()
  " mainly copied from s:load_default_sources_and_kinds() in unite.vim
  let s:default_sources = {}
  for l:name in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')
    if l:name == 'alias'
      continue
    endif
    if type({'unite#sources#' . l:name . '#define'}()) == type([])
      for l:source in {'unite#sources#' . l:name . '#define'}()
        if !has_key(s:default_sources, l:source.name)
          let s:default_sources[l:source.name] = l:source
        endif
      endfor
    else
      let l:source = {'unite#sources#' . l:name . '#define'}()
      if !has_key(s:default_sources, l:source.name)
        let s:default_sources[l:source.name] = l:source
      endif
    endif
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
