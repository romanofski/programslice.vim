"======================================================================
" vim-programslice - A Python filetype plugin to slice python programs
"
" Language:    Python (ft=python)
" Maintainer:  Róman Joost <roman@bromeco.de>
"
"======================================================================


" Do initialize below once.
if exists("g:programslice_ftplugin_loaded")
    finish
endif
let g:programslice_ftplugin_loaded = 1

" The highlight group we link against to mark depending lines
if !exists('g:programslice_dependent_lines')
    let g:programslice_dependent_lines = 'WarningMsg'
endif

" Define the path to the programslice command
if !exists('g:programslice_cmd')
    let g:programslice_cmd = "programslice"
endif
if !executable(g:programslice_cmd)
    echoerr "Can't find the `programslice` command in the current $PATH."
    echoerr "You may need to adjust the g:programslice_cmd in your .vimrc"
    finish
endif

" Highlight group.
" This group is used to highlight the sliced lines, which depend on the
" starting line.
"
execute 'highlight link ProgramSlice ' . g:programslice_dependent_lines


" Cleares all highlighted lines
"
function! s:clear_slice_matches()
    let matches = getmatches()
    for matchId in matches
        if matchId['group'] == 'ProgramSlice'
            call matchdelete(matchId['id'])
        endif
    endfor
endfunction
exe 'command! -buffer -nargs=0 ClearSliceMatches :call s:clear_slice_matches()'

" Simple slice which only highlights line numbers.
"
function! s:highlight_line_numbers()
    let lines = s:slice_buffer('linenumbers')
    for line in lines
        let lineno = join(['\%', line, 'l\n\@!'], '')
        let mID = matchadd('ProgramSlice', lineno)
    endfor
endfunction
command! -nargs=0 SliceBuffer :call s:highlight_line_numbers()

" Helper methods
"

" Runs the slice from the current line
"
function! s:slice_buffer(output)
python << EOF
import vim
from programslice import glue

cmd = vim.eval('string(g:programslice_cmd)')
splitview = vim.eval('string(a:output)')
currentlineno, col = vim.current.window.cursor
contents = vim.current.buffer[:]
contents = '\n'.join(contents) + '\n'
vimenc = vim.eval('&encoding')
if vimenc:
    contents = contents.decode(vimenc)
result = glue(cmd, contents, currentlineno)
vim.command('let result = %s' % result)
EOF
return result
endfunction


" Returns a positive integer if the current buffer is sliced.
"
function! s:is_sliced()
    let matches = getmatches()
    let is_highlighted = 0
    for matchId in matches
        if matchId['group'] == 'ProgramSlice'
            let is_highlighted = 1
            break
        endif
    endfor
    return is_highlighted
endfunction

function! s:toggle_slice()
    let is_highlighted = s:is_sliced()

    if is_highlighted == 1
        call s:clear_slice_matches()
    else
        call s:highlight_line_numbers()
    endif
endfunction
command! -nargs=0 ToggleSliceBuffer :call s:toggle_slice()
