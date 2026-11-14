let s:Filepath = vital#esearch#import('System.Filepath')

fu! esearch#compat#filemanager#nvimtree#import() abort
  return s:NVIMTree
endfu

let s:NVIMTree = esearch#compat#filemanager#base#import()

fu! s:NVIMTree.path_under_cursor() abort
  return luaeval("require'esearch.nvim.filemanager.nvimtree'.path_under_cursor()")
endfu

" Marked nodes win when there are any, otherwise the directory under the
" cursor or the directory of the file under the cursor, like the other filers do.
fu! s:NVIMTree.nearest_dir_or_selected_nodes() abort
  let marked = luaeval("require'esearch.nvim.filemanager.nvimtree'.marked_paths()")
  if !empty(marked) | return marked | endif

  let path = self.path_under_cursor()
  return isdirectory(path) ? [path] : [s:Filepath.dirname(path)]
endfu
