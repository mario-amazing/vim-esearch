let s:default_mappings = {
      \ '<Plug>(esearch-T)': 'T',
      \ '<Plug>(esearch-t)': 't',
      \ '<Plug>(esearch-s)': 's',
      \ '<Plug>(esearch-S)': 'S',
      \ '<Plug>(esearch-v)': 'v',
      \ '<Plug>(esearch-V)': 'V',
      \ '<Plug>(esearch-cr)': '<CR>',
      \ '<Plug>(esearch-cp)': '<C-p>',
      \ '<Plug>(esearch-cn)': '<C-n>',
      \ }

let s:mappings = {}
let s:header = '%d matches'

fu! esearch#win#update()
  if esearch#util#cgetfile(b:request)
    return 1
  endif
  setlocal noreadonly
  setlocal modifiable

  call s:extend_results()

  let qf_len = len(b:qf)
  if qf_len > b:_es_iterator
    if qf_len - b:_es_iterator - 1 <= g:esearch_settings.batch_size
      let qfrange = range(b:_es_iterator, qf_len - 1)
      let b:_es_iterator = qf_len
    else
      let qfrange = range(b:_es_iterator, b:_es_iterator + g:esearch_settings.batch_size - 1)
      let b:_es_iterator += g:esearch_settings.batch_size
    endif

    call s:render_results(qfrange)
    call setline(1, printf(s:header, b:_es_iterator))
  endif

  setlocal readonly
  setlocal nomodifiable
  setlocal nomodified
  " exe g:esearch_settings.update_statusline_cmd
  let b:last_update_time = esearch#util#timenow()
endfu

fu! s:extend_results()
  if b:handler_running
    if len(b:qf) < len(b:qf_file) - 1 && !empty(b:qf_file)
      call extend(b:qf, esearch#util#parse_results(len(b:qf), len(b:qf_file)-2))
    endif
  else
    if len(b:qf) < len(b:qf_file) && !empty(b:qf_file)
      call extend(b:qf, esearch#util#parse_results(len(b:qf), len(b:qf_file)-1))
    endif
  endif
endfu

fu! s:render_results(qfrange)
  let line = line('$') + 1
  for i in a:qfrange
    let context  = b:qf[i].text
    let fname    = substitute(b:qf[i].fname, b:pwd.'/', '', '')

    if fname !=# b:prev_filename
      call setline(line, '')
      let line += 1
      call setline(line, fname)
      let line += 1
    endif
    call setline(line, ' '.printf('%3d', b:qf[i].lnum).' '.esearch#util#trunc_str(context, 80))
    let line += 1
    let b:prev_filename = fname
  endfor
endfu

fu! esearch#win#init()
  augroup EasysearchAutocommands
    au! * <buffer>
    au CursorMoved <buffer> call esearch#handlers#cursor_moved()
    au CursorHold  <buffer> call esearch#handlers#cursor_hold()
    au BufLeave    <buffer> let  &updatetime = b:updatetime_backup
    au BufEnter    <buffer> let  b:updatetime_backup = &updatetime
  augroup END

  call s:init_mappings()

  let b:updatetime_backup = &updatetime
  let &updatetime = float2nr(g:esearch_settings.updatetime)

  let b:qf = []
  let b:pwd = $PWD
  let b:qf_file = []
  let b:qf_entirely_parsed = 0
  let b:_es_iterator    = 0
  let b:handler_running = 0
  let b:prev_filename = ''
  let b:broken_results = []

  setlocal noreadonly
  setlocal modifiable
  exe '1,$d'
  call setline(1, printf(s:header, b:_es_iterator))
  setlocal readonly
  setlocal nomodifiable
  setlocal noswapfile
  setlocal nonumber
  setlocal buftype=nofile
  setlocal ft=esearch

  let b:last_update_time = esearch#util#timenow()
endfu


fu! esearch#win#map(map, plug)
  if has_key(s:mappings, a:plug)
    let s:mappings[a:plug] = a:map
  else
    echoerr 'There is no such action: "'.a:plug.'"'
  endif
endfu

fu! s:init_mappings()
  nnoremap <silent><buffer> <Plug>(esearch-t)   :call <sid>open('tabnew')<cr>
  nnoremap <silent><buffer> <Plug>(esearch-T)   :call <SID>open('tabnew', 'tabprevious')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-s)   :call <SID>open('new')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-S)   :call <SID>open('new', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-v)   :call <SID>open('vnew')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-V)   :call <SID>open('vnew', 'wincmd p')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-cr)  :call <SID>open('edit')<CR>
  nnoremap <silent><buffer> <Plug>(esearch-cn)  :<C-U>sil exe <SID>move(1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-cp)  :<C-U>sil exe <SID>move(-1)<CR>
  nnoremap <silent><buffer> <Plug>(esearch-Nop) <Nop>

  call extend(s:mappings, s:default_mappings, 'keep')
  for plug in keys(s:mappings)
    exe 'nmap <buffer> ' . s:mappings[plug] . ' ' . plug
  endfor
endfu

fu! s:open(cmd, ...)
  let new_cursor_pos = [s:line_number(), 1]
  let fname = s:filename()
  if !empty(fname)
    exe a:cmd . ' ' . fname
    call cursor(new_cursor_pos)
    norm! zz
    if a:0 | exe a:1 | endif
  endif
endfu

fu! s:move(direction)
  let pattern = '^\s\+\d\+\s\+.*'
  if a:direction == 1 || line('.') < 4
    call search(pattern, 'W')
  else
    call search(pattern, 'Wbe')
  endif

  return '.|norm! w'
endfu

fu! s:filename()
  let lnum = search('^\%>1l[^ ]', 'bcWn')
  if lnum == 0
    let lnum = search('^\%>1l[^ ]', 'cWn')
    if lnum == 0 | return '' | endif
  endif

  let filename = matchstr(getline(lnum), '^\zs[^ ].\+')
  if empty(filename)
    return ''
  else
    return b:pwd . '/' . filename
  endif
endfu

fu! s:line_number()
  let pattern = '^\%>1l\s\+\d\+.*'

  if line('.') < 3 || match(getline('.'), '^[^ ].*') >= 0
    let lnum = search(pattern, 'cWn')
  else
    let lnum = search(pattern, 'bcWn')
  endif

  return matchstr(getline(lnum), '^\s\+\zs\d\+\ze.*')
endfu