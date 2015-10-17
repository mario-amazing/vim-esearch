let s:mappings = {
      \'<Plug>(esearch-regex)': '<C-s><C-r>',
      \'<Plug>(esearch-case)':  '<C-s><C-c>',
      \'<Plug>(esearch-word)':  '<C-s><C-w>',
      \}
let s:dir_prompt = ''

cnoremap <Plug>(easysearch-regex) <C-r>=<SID>invert('regex')<CR>
cnoremap <Plug>(easysearch-case) <C-r>=<SID>invert('case')<CR>
cnoremap <Plug>(easysearch-word) <C-r>=<SID>invert('word')<CR>

fu! esearch#cmdline#read(initial, dir)
  let old_mapargs = s:init_mappings()
  let s:dir_prompt = s:dir_prompt(a:dir)
  let s:cmdline = a:initial
  let s:cmdpos = len(s:cmdline) + 1
  let s:int_pending = 0
  while 1
    let str = input(s:prompt(), s:cmdline)
    if s:int_pending
      let s:int_pending = 0
      let s:cmdline .= s:get_correction()
      redraw!
    else
      break
    endif
  endwhile
  unlet s:int_pending

  call s:restore_mappings(old_mapargs)
  return str
endfu


fu! esearch#cmdline#map(map, plug)
    let s:mappings[a:plug] = a:map
endfu


fu! s:prompt()
  let r = g:esearch_settings.stringify('regex')
  let c = g:esearch_settings.stringify('case')
  let w = g:esearch_settings.stringify('word')
  return s:dir_prompt.'pattern '.r.c.w.' '
endfu

fu! s:dir_prompt(dir)
  if a:dir ==# $PWD
    return ''
  endif
  return 'Dir: '.substitute(a:dir , $PWD, '.', '')."\n"
endfu

fu! s:get_correction()
  if len(s:cmdline) + 1 != s:cmdpos
    return repeat("\<Left>", len(s:cmdline) + 1 - s:cmdpos )
  endif
  return ''
endfu

fu! s:init_mappings()
  let mapargs =  {}
  for plug in keys(s:mappings)
    let map = s:mappings[plug]
    let mapargs[map] = maparg(map, 'c', 0, 1)
    exe "cmap " . map . ' ' . plug
  endfor

  return mapargs
endfu

fu! s:restore_mappings(mapargs)
  for map in keys(a:mapargs)
    let maparg = a:mapargs[map]
    if empty(maparg)
      exe 'cunmap '.map
    else
      let cmd  = 'silent ' . maparg.mode . (maparg.noremap ? 'nore': '')
      let cmd .= 'map ' . maparg.lhs . maparg.rhs
      exe cmd
    endif
  endfor
endfu

fu! s:invert(option)
  let s:int_pending = 1
  let s:cmdline = getcmdline()
  let s:cmdpos = getcmdpos()
  call g:esearch_settings.invert(a:option)
  call feedkeys("\<C-c>", 'n')
  return ''
endfu