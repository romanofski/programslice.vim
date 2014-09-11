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
    echohl WarningMsg
    echomsg "Can't find the `programslice` command in the current $PATH."
    echomsg "You may need to adjust the g:programslice_cmd in your .vimrc or install programslice Python program."
    echohl
    finish
endif

" Highlight group.
" This group is used to highlight the sliced lines, which depend on the
" starting line.
"
execute 'highlight link ProgramSlice ' . g:programslice_dependent_lines


" Cleares all highlighted lines
"
function! s:ClearSliceMatches()
    let matches = getmatches()
    for matchId in matches
        if matchId['group'] == 'ProgramSlice'
            call matchdelete(matchId['id'])
        endif
    endfor
endfunction
exe 'command! -buffer -nargs=0 ClearSliceMatches :call s:ClearSliceMatches()'

" Simple slice which only highlights line numbers.
"
function! s:HighlightLineNumbers()
    let curpos = getcurpos()
    let lines = s:VimSliceBuffer(curpos[1])
    for line in lines
        let lineno = join(['\%', line, 'l\n\@!'], '')
        let mID = matchadd('ProgramSlice', lineno)
    endfor
    call setpos('.', curpos)
endfunction
command! -nargs=0 SliceBuffer :call s:HighlightLineNumbers()

" Helper methods
"

function! s:VimSliceBuffer(pos)
    " Write the current buffer to a temporary file in order to pass it
    " to programslice as an option
    "
    let tempin = tempname()
    let start = line(1)
    let end = search('\%$') - 1
    let contents = getline(start, end)
    call writefile(contents, tempin)

    " Now slice the program from the current cursor position. We expect
    " the default is only line numbers.
    let cmd = printf('%s %s %d', g:programslice_cmd, tempin, a:pos)
    let stdout = call('system', [cmd])
    let result = split(stdout, '\n')
    return result
endfunction

" Returns a positive integer if the current buffer is sliced.
"
function! s:IsSliced()
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

function! s:ToggleSlice()
    let is_highlighted = s:IsSliced()

    if is_highlighted == 1
        call s:ClearSliceMatches()
    else
        call s:HighlightLineNumbers()
    endif
endfunction
command! -nargs=0 ToggleSliceBuffer :call s:ToggleSlice()
