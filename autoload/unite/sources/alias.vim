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
  for [l:name, l:config] in items(g:unite_source_alias_aliases)
    let l:original_source = 
          \ (!has_key(l:config, 'source')) ? {} :
          \ s:get_source(l:config.source)

    if empty(l:original_source)
      continue
    endif

    let l:args = 
          \ (!has_key(l:config, 'args')) ? [] :
          \ (type(l:config.args) == type([])) ? l:config.args :
          \ [l:config.args]
    
    let l:description =
          \ (!has_key(l:config, 'description')) ? s:make_default_description(l:config.source, l:args) :
          \ l:config.description
    
    let l:alias = deepcopy(l:original_source)
    let l:alias.name = l:name
    let l:alias.description = l:description
    let l:alias.source__alias__ = {
          \   'args': l:args,
          \   'gather_candidates': l:alias.gather_candidates,
          \   'hooks': {},
          \ }

    function! l:alias.gather_candidates(args, context)
      let l:args = self.source__alias__.args + a:args
      let l:originals = self.source__alias__.gather_candidates(l:args, a:context)
      let l:candidates = []
      for l:candidate in l:originals
        let l:candidate.source = self.name
        call add(l:candidates, l:candidate)
      endfor
      return l:candidates
    endfunction

    if has_key(l:alias, 'hooks')
      let l:hook_keys = copy(keys(l:alias.hooks))
      let l:alias.hooks.__args__ = l:args
      let l:alias.hooks.__originals__ = {}
      for l:hook_key in l:hook_keys
        let l:alias.hooks.__originals__[l:hook_key] = l:alias.hooks[l:hook_key]
        let l:define_function = join([ 
              \ 'function! l:alias.hooks.' . l:hook_key . '(args, context)',
              \ '  let l:args = self.__args__ + a:args',
              \ '  return self.__originals__.' . l:hook_key . '(l:args, a:context)',
              \ 'endfunction'], "\n")
        execute l:define_function
      endfor
    endif
    
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

function! s:make_default_description(source_name, args)
  let l:desc = 'alias for "' . a:source_name
  if empty(a:args)
    return l:desc . '"'
  endif
  let l:desc .= ':' . join(a:args, ':') . '"'
  return l:desc
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
