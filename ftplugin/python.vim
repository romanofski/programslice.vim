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

" Slices by variable, not by line numbers. This is much more fine
" grained.
"
function! s:HighlightByVariable()
    let curword = expand("<cword>")
    let curpos = getcurpos()
    let results = s:VimSliceBuffer(curpos, curword)

    for [var, lineno, offset] in results
        " match everything in line \%l from column \%>c to column \%<c.
        " Use the length of the variable returned by programslice.
        " Check ;help patterns
        "
        let wlength = offset + strlen(var) + 1
        let pattern = join(['\%', lineno, 'l\%>', offset, 'c\%<', wlength, 'c'], '')
        let mID = matchadd('ProgramSlice', pattern)
    endfor
    call setpos('.', curpos)
endfunction
command! -nargs=0 SliceBuffer :call s:HighlightByVariable(<args>)

" Helper methods
"

function! s:VimSliceBuffer(pos, curword)
    " Write the current buffer to a temporary file in order to pass it
    " to programslice as an option
    "
    let tempin = tempname()
    let start = line(1)
    let end = search('\%$')
    let contents = getline(start, end)
    call writefile(contents, tempin)

    " Now slice the program from the current cursor position. We expect
    " the default is only line numbers.
    " signature:
    "   command filename word linenumber column
    let cmd = printf('%s %s %s %d %d', g:programslice_cmd, tempin, a:curword, a:pos[1], a:pos[2] - 1)
    let stdout = call('system', [cmd])
    let result = s:ParseSliceResult(cmd, stdout)
    return result
endfunction

" logs to debug file
function! s:LogToFile(cmd, stdout)
    if exists("g:programslice_debug_file")
        execute 'redir >> ' . g:programslice_debug_file
        silent echo "Invoked with: " . a:cmd . "\n\n"
        silent echo a:stdout
        silent! redir END
    endif
endfunction


" Parse the result
" `cmd` is only needed if we need to log the Traceback in case of an
" error.
" Errors are appended to the debug file.
"
function! s:ParseSliceResult(cmd, stdout)
    if match(a:stdout, 'Traceback') == 0
        let ermsg = "Error occured. Set g:programslice_debug_file to point to a file to see a Traceback"
        echoerr ermsg
        call s:LogToFile(a:cmd, a:stdout)
        return []
    endif

    call s:LogToFile(a:cmd, a:stdout)

    let lines = split(a:stdout, '\n')
    let parsed = []

    for l in lines
        " TODO: if line starts with 'usage' we ran into an API
        " incompatibility, since we've passed wrong arguments to the
        " commandline utility
        " https://github.com/romanofski/programslice.vim/issues/1
        let tuple = split(l, ',')
        call add(parsed, tuple)
    endfor
    return parsed
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
        call s:HighlightByVariable()
    endif
endfunction
command! -nargs=0 ToggleSliceBuffer :call s:ToggleSlice()
