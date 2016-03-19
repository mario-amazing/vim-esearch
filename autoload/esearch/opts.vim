fu! esearch#opts#new(opts) abort
  return extend(a:opts, {
        \ 'out':             'win',
        \ 'backend':         has('nvim') ? 'nvim' : 'dispatch',
        \ 'adapter':         'ag',
        \ 'regex':           0,
        \ 'case':            0,
        \ 'word':            0,
        \ 'updatetime':      300.0,
        \ 'batch_size':      2000,
        \ 'ticks':           40,
        \ 'context_width':   { 'l': 60, 'r': 60 },
        \ 'recover_regex':   1,
        \ 'highlight_match': 1,
        \ 'escape_special':  1,
        \ 'wordchars':      'a-z,A-Z,_',
        \ 'use': ['visual', 'hlsearch', 'last'],
        \ 'nerdtree_plugin': 1,
        \ 'invert':      function('<SID>invert'),
        \}, 'keep')
endfu

fu! s:invert(key) dict abort
  let option = !self[a:key]
  let self[a:key] = option
  return option
endfu
