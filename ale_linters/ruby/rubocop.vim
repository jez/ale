" Author: ynonp - https://github.com/ynonp, Eddie Lebow https://github.com/elebow
" Description: RuboCop, a code style analyzer for Ruby files

function! ale_linters#ruby#rubocop#GetCommand(buffer) abort
    let l:executable = ale#handlers#rubocop#GetExecutable(a:buffer)
    let l:exec_args = l:executable =~? 'bundle$'
    \   ? ' exec rubocop'
    \   : ''

    return ale#Escape(l:executable) . l:exec_args
    \   . ' --format json --force-exclusion '
    \   . ale#Var(a:buffer, 'ruby_rubocop_options')
    \   . ' --stdin ' . bufname(a:buffer)
endfunction

function! ale_linters#ruby#rubocop#Handle(buffer, lines) abort
    if len(a:lines) == 0
      return []
    endif

    let l:errors = json_decode(a:lines[0])

    let l:output = []

    for l:error in l:errors['files'][0]['offenses']
        let l:start_col = l:error['location']['column'] + 0
        call add(l:output, {
        \   'lnum': l:error['location']['line'] + 0,
        \   'col': l:start_col,
        \   'end_col': l:start_col + l:error['location']['length'] - 1,
        \   'text': l:error['message'],
        \   'type': ale_linters#ruby#rubocop#GetType(l:error['severity']),
        \})
    endfor

    return l:output
endfunction

function! ale_linters#ruby#rubocop#GetType(severity) abort
    if a:severity ==? 'convention'
    \|| a:severity ==? 'warning'
    \|| a:severity ==? 'refactor'
        return 'W'
    endif

    return 'E'
endfunction

call ale#linter#Define('ruby', {
\   'name': 'rubocop',
\   'executable_callback': 'ale#handlers#rubocop#GetExecutable',
\   'command_callback': 'ale_linters#ruby#rubocop#GetCommand',
\   'callback': 'ale_linters#ruby#rubocop#Handle',
\})
