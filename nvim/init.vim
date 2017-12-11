"pei's vimrc
" Author: pei0804
" URL: http://tikasan.hatenablog.com/
" Source: https://github.com/pei0804/dotfiles
"=============================================================
"            ________    _______       ___
"           |\   __  \  |\  ___ \     |\  \
"           \ \  \|\  \ \ \   __/|    \ \  \
"            \ \   ____\ \ \  \_|/__   \ \  \
"             \ \  \___|  \ \  \_|\ \   \ \  \
"              \ \__\      \ \_______\   \ \__\
"               \|__|       \|_______|    \|__|
"=============================================================
"----------------------------------------
" plugin :PlugInstall
"----------------------------------------

" vim-plug
let vimplug_exists=expand('~/.local/share/nvim/site/autoload/plug.vim')
if !filereadable(vimplug_exists)
    echo "Installing vim-plug...\n"
    !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    let g:not_finish_vimplug = "yes"
    autocmd VimEnter * PlugInstall
endif

call plug#begin()

" all
Plug 'Shougo/unite.vim'
Plug 'Shougo/vimfiler'
Plug 'tomtom/tcomment_vim'
Plug 'cohama/lexima.vim'
Plug 'kassio/neoterm'
Plug 'itchyny/lightline.vim'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'majutsushi/tagbar'
Plug 'mattn/emmet-vim'
Plug 'w0rp/ale'
Plug 'itchyny/vim-gitbranch'
Plug 'mhartington/oceanic-next'
Plug 'tpope/vim-fugitive'
Plug 'kana/vim-submode'
Plug 'kana/vim-operator-user'
Plug 'haya14busa/vim-operator-flashy'
Plug 'haya14busa/incsearch.vim'
Plug 'tpope/vim-pathogen'
Plug 'iamcco/mathjax-support-for-mkdp', {'for': 'markdown'}
Plug 'iamcco/markdown-preview.vim', {'for': 'markdown'}
Plug 'osyo-manga/vim-over'
Plug 'tyru/operator-camelize.vim'
Plug 'kana/vim-operator-user'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-go', { 'do': 'make'}

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-go', { 'do': 'make'}

" snip
Plug 'tomtom/tlib_vim'
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'garbas/vim-snipmate'

" for language
" php
Plug 'szw/vim-tags', {'for': ['php', 'javascript']}
Plug 'vim-php/tagbar-phpctags.vim', {'for': 'php'}
Plug 'flyinshadow/php_localvarcheck.vim', {'for': 'php'}
Plug 'shawncplus/phpcomplete.vim', {'for': 'php'}
Plug 'sumpygump/php-documentor-vim', {'for': 'php'}
Plug '2072/PHP-Indenting-for-VIm', {'for': 'php'}
Plug 'beanworks/vim-phpfmt', {'for': 'php'}

" go
Plug 'fatih/vim-go', {'for': 'go'}
Plug 'jodosha/vim-godebug', {'for': 'go'}
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }

" javascript
Plug 'othree/yajs.vim', {'for': 'javascript'}
Plug 'othree/javascript-libraries-syntax.vim'
Plug 'MaxMEllon/vim-jsx-pretty'

" html / css
Plug 'gregsexton/MatchTag', { 'for': 'html' }
Plug 'othree/html5.vim', { 'for': 'html' }
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }
Plug 'cakebaker/scss-syntax.vim', { 'for': 'scss' }
Plug 'gko/vim-coloresque'

" Docker
Plug 'ekalinin/Dockerfile.vim'

call plug#end()

filetype plugin indent on
"----------------------------------------
" deoplete
"----------------------------------------
set completeopt+=noinsert
let g:deoplete#sources#go#gocode_binary = $GOPATH.'/bin/gocode'
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
let g:min_pattern_length = 0
"----------------------------------------
" deoplete-go
"----------------------------------------
let g:deoplete#sources#go#align_class = 1
let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']
let g:deoplete#sources#go#package_dot = 1
"----------------------------------------
" vim-go
"----------------------------------------
set autowrite
let g:go_fmt_command = "goimports"
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_version_warning = 0
let g:go_list_type = "quickfix"
let g:go_fmt_experimental = 1
autocmd BufWritePost *.go normal! zv
" let g:go_auto_type_info = 1
" let g:go_auto_sameids = 1
autocmd FileType go nmap <xRight> :cnext<CR>
autocmd FileType go nmap <xLeft> :cprevious<CR>
autocmd FileType go nmap <Leader>u  <Plug>(go-test-func)
autocmd FileType go nmap <Leader>t  <Plug>(go-test)
autocmd FileType go nmap <Leader>b  <Plug>(go-build)
autocmd FileType go nmap <Leader>r  <Plug>(go-run)
autocmd FileType go nmap <Leader>d  <Plug>(go-doc)
autocmd FileType go nmap <Leader>i <Plug>(go-info)
autocmd FileType go nmap <Leader>ds <Plug>(go-def-split)
autocmd FileType go nmap <Leader>dv <Plug>(go-def-vertical)
autocmd FileType go nmap <Leader>q :GoSameIds<CR>
autocmd FileType go setlocal noexpandtab
autocmd FileType go setlocal tabstop=4
autocmd FileType go setlocal shiftwidth=4
set rtp+=$GOROOT/misc/vim
exe "set rtp+=".globpath($GOPATH, "src/github.com/nsf/gocode/vim")
"----------------------------------------
" go
"----------------------------------------
autocmd FileType go set foldmethod=indent
autocmd FileType go set foldnestmax=1
"----------------------------------------
" php
"----------------------------------------
" 保存時に走らせる
autocmd FileType php set makeprg=php\ -l\ %
autocmd BufWritePost *.php silent make | if len(getqflist()) != 1 | copen | else | cclose | endif
" 変数チェック
let g:php_localvarcheck_enable = 1
let g:php_localvarcheck_global = 0
" phpfmt
" composer global require "squizlabs/php_codesniffer=*"
let g:phpfmt_standard = 'PSR2'
let g:phpfmt_autosave = 1
" errormarker.vim
" composer global require ha1t/php-vimparse
if executable('vimparse.php')
  setlocal makeprg=vimparse.php\ %\ $*
  setlocal errorformat=%f:%l:%m
  setlocal shellpipe=2>&1\ >
  autocmd BufWritePost <buffer> silent make
endif
"----------------------------------------
" terminal
"----------------------------------------
" Esc または jj で戻す
tnoremap <silent> <ESC> <C-\><C-n>
tnoremap <silent> jj <C-\><C-n>
tnoremap <C-w>h <C-\><C-n><C-w>h
tnoremap <C-w>j <C-\><C-n><C-w>j
tnoremap <C-w>k <C-\><C-n><C-w>k
tnoremap <C-w>l <C-\><C-n><C-w>l
"----------------------------------------
" neoterm
"----------------------------------------
noremap <silent> tt :Tnew<CR>
let g:neoterm_size = 8
let g:neoterm_autojump = 1
let g:neoterm_autoinsert = 1
"----------------------------------------
" ctrlp
"----------------------------------------
set wildignore+=**/tmp/,*.so,*.swp,*.zip,*.pyc,htmlcov,__pycache__
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn|htmlcov|node_modules|DS_Store)$',
  \ 'file': '\v\.(exe|so|dll|pyc)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_open_new_file = 'r'
let g:ctrlp_extensions = ['tag', 'quickfix', 'dir', 'line', 'mixed']
let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:18'
" 終了時キャッシュをクリアしない
let g:ctrlp_clear_cache_on_exit = 0
" MRUの最大記録数
let g:ctrlp_mruf_max = 10000
" 絞り込みで一致した部分のハイライト
let g:ctrlp_highlight_match = [1, 'IncSearch']
let g:ctrlp_prompt_mappings = {
    \ 'PrtSelectMove("j")':   ['<c-j>', '<c-n>'],
    \ 'PrtSelectMove("k")':   ['<c-k>', '<c-p>'],
    \ 'PrtHistory(-1)':       ['<down>'],
    \ 'PrtHistory(1)':        ['<up>'],
    \ }
"----------------------------------------
" emmet https://mattn.kaoriya.net/software/vim/20100306021632.htm
"----------------------------------------
" <c-y>,
let g:user_emmet_leader_key='<Leader>'
let g:user_emmet_install_global = 0
autocmd FileType html,css,tmpl EmmetInstall
"----------------------------------------
" kannokanno/previm
"----------------------------------------
" :PrevimOpen
let g:previm_open_cmd = 'open -a Firefox'
augroup PrevimSettings
    autocmd!
    autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
  augroup END
"----------------------------------------
" incsearch
"----------------------------------------
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
"----------------------------------------
" operator-flashy
"----------------------------------------
map y <Plug>(operator-flashy)
nmap Y <Plug>(operator-flashy)$
let g:operator#flashy#flash_time = 200
"----------------------------------------
" ctags
"----------------------------------------
set tags=tags
autocmd FileType php,html,javascript nnoremap <C-]> g<C-]> 
"----------------------------------------
" snip
"----------------------------------------
nmap <Tab> <Plug>snipMateShow
"----------------------------------------
" ale
"----------------------------------------
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1
let g:ale_sign_column_always = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_linters = {'go': ['gometalinter']}
let g:ale_go_gometalinter_options = '--vendored-linters --disable-all --enable=gotype --enable=vet --enable=golint -t'
let g:ale_open_list = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
"----------------------------------------
" tab
"----------------------------------------
autocmd FileType go nmap <leader>g :TagbarToggle<CR>
let g:tagbar_left = 0
let g:tagbar_autofocus = 1
let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }
"----------------------------------------
" VimFiler
"----------------------------------------
let g:vimfiler_as_default_explorer = 1
nnoremap <C-e> :VimFiler<CR>
map F <Plug>(vimfiler_make_directory)
"----------------------------------------
" tyru/operator-camelize.vim'
" kana/vim-operator-user'
"----------------------------------------
map <leader>c <plug>(operator-camelize-toggle)
"----------------------------------------
" vim-over
"----------------------------------------
" 全体置換
nnoremap <silent> <Space>o :OverCommandLine<CR>%s//g<Left><Left>
" 選択範囲置換
vnoremap <silent> <Space>o :OverCommandLine<CR>s//g<Left><Left>
" カーソルしたの単語置換
nnoremap sub :OverCommandLine<CR>%s/<C-r><C-w>//g<Left><Left>
"----------------------------------------
" TComment
"----------------------------------------
nmap <C-_> :TComment<CR>
"----------------------------------------
" itchyny/lightline.vim
"----------------------------------------
" ステータスラインを常に表示
set laststatus=2
" 現在のモードを表示
set showmode
" 打ったコマンドをステータスラインの下に表示
set showcmd
" ステータスラインの右側にカーソルの現在位置を表示する
set ruler
" デフォルトのステータスラインを削除
set noshowmode

let g:gitgutter_sign_added = '✚'
let g:gitgutter_sign_modified = '➜'
let g:gitgutter_sign_removed = '✘'
let g:lightline = {
        \ 'mode_map': {'c': 'NORMAL'},
        \ 'active': {
        \   'left': [
        \     ['mode', 'paste'],
        \     ['fugitive', 'gitgutter', 'filename'],
        \   ],
        \   'right': [
        \     ['lineinfo', 'syntastic'],
        \     ['percent'],
        \     ['charcode', 'fileformat', 'fileencoding', 'filetype'],
        \   ]
        \ },
        \ 'component_function': {
        \   'modified': 'MyModified',
        \   'readonly': 'MyReadonly',
        \   'fugitive': 'MyFugitive',
        \   'filename': 'MyFilename',
        \   'fileformat': 'MyFileformat',
        \   'filetype': 'MyFiletype',
        \   'fileencoding': 'MyFileencoding',
        \   'mode': 'MyMode',
        \   'syntastic': 'SyntasticStatuslineFlag',
        \   'charcode': 'MyCharCode',
        \   'gitgutter': 'MyGitGutter',
        \ },
        \ 'separator': {'left': '⮀', 'right': '⮂'},
        \ 'subseparator': {'left': '⮁', 'right': '⮃'}
        \ }

function! MyModified()
  return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! MyReadonly()
  return &ft !~? 'help\|vimfiler\|gundo' && &ro ? '⭤' : ''
endfunction

function! MyFilename()
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
        \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
        \  &ft == 'unite' ? unite#get_status_string() :
        \  &ft == 'vimshell' ? substitute(b:vimshell.current_dir,expand('~'),'~','') :
        \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
        \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! MyFugitive()
  try
    if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head')
      let _ = fugitive#head()
      return strlen(_) ? '⭠ '._ : ''
    endif
  catch
  endtry
  return ''
endfunction

function! MyFileformat()
  return winwidth('.') > 70 ? &fileformat : ''
endfunction

function! MyFiletype()
  return winwidth('.') > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! MyFileencoding()
  return winwidth('.') > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! MyMode()
  return winwidth('.') > 60 ? lightline#mode() : ''
endfunction

function! MyGitGutter()
  if ! exists('*GitGutterGetHunkSummary')
        \ || ! get(g:, 'gitgutter_enabled', 0)
        \ || winwidth('.') <= 90
    return ''
  endif
  let symbols = [
        \ g:gitgutter_sign_added . ' ',
        \ g:gitgutter_sign_modified . ' ',
        \ g:gitgutter_sign_removed . ' '
        \ ]
  let hunks = GitGutterGetHunkSummary()
  let ret = []
  for i in [0, 1, 2]
    if hunks[i] > 0
      call add(ret, symbols[i] . hunks[i])
    endif
  endfor
  return join(ret, ' ')
endfunction

" https://github.com/Lokaltog/vim-powerline/blob/develop/autoload/Powerline/Functions.vim
function! MyCharCode()
  if winwidth('.') <= 70
    return ''
  endif

  " Get the output of :ascii
  redir => ascii
  silent! ascii
  redir END

  if match(ascii, 'NUL') != -1
    return 'NUL'
  endif

  " Zero pad hex values
  let nrformat = '0x%02x'

  let encoding = (&fenc == '' ? &enc : &fenc)

  if encoding == 'utf-8'
    " Zero pad with 4 zeroes in unicode files
    let nrformat = '0x%04x'
  endif

  " Get the character and the numeric value from the return value of :ascii
  " This matches the two first pieces of the return value, e.g.
  " "<F>  70" => char: 'F', nr: '70'
  let [str, char, nr; rest] = matchlist(ascii, '\v\<(.{-1,})\>\s*([0-9]+)')

  " Format the numeric value
  let nr = printf(nrformat, nr)

  return "'". char ."' ". nr
endfunction
"----------------------------------------
" 全体
"----------------------------------------

" <Leader>
let mapleader = "\<Space>"

" ファイルを上書きする前にバックアップを作ることを無効化
set nowritebackup
" ファイルを上書きする前にバックアップを作ることを無効化
set nobackup
" vim の矩形選択で文字が無くても右へ進める
set virtualedit=block
" 挿入モードでバックスペースで削除できるようにする
set backspace=indent,eol,start
" 全角文字専用の設定
set ambiwidth=double
" wildmenuオプションを有効(vimバーからファイルを選択できる)
set wildmenu
"----------------------------------------
" 検索
"----------------------------------------
" 検索するときに大文字小文字を区別しない
set ignorecase
" 小文字で検索すると大文字と小文字を無視して検索
set smartcase
" 検索がファイル末尾まで進んだら、ファイル先頭から再び検索
set wrapscan
" インクリメンタル検索 (検索ワードの最初の文字を入力した時点で検索が開始)
set incsearch
" 検索結果をハイライト表示
set hlsearch

" 検索結果に移動した時に中央にする
noremap n nzz
noremap N Nzz
noremap * *zz
noremap # #zz
noremap g* g*zz
noremap g# g#zz

"==========================
" 文字コード
"==========================
set encoding=utf-8
set fileformats=unix,dos,mac

"----------------------------------------
" 表示設定
"----------------------------------------
" エラーメッセージの表示時にビープを鳴らさない
set noerrorbells
" Windowsでパスの区切り文字をスラッシュで扱う
set shellslash
" 対応する括弧やブレースを表示
set showmatch matchtime=1
" インデント方法の変更
set cinoptions+=:0
" メッセージ表示欄を2行確保
set cmdheight=2
" ウィンドウの右下にまだ実行していない入力中のコマンドを表示
set showcmd
" 省略されずに表示
set display=lastline
" タブ文字を CTRL-I で表示し、行末に $ で表示する
set list
" 行末のスペースを可視化
set listchars=tab:>-,trail:-,extends:<,precedes:<
" コマンドラインの履歴を10000件保存する
set history=10000
" コメントの色を水色
hi Comment ctermfg=3
" 入力モードでTabキー押下時に半角スペースを挿入
set expandtab
" インデント幅
set shiftwidth=2
" タブキー押下時に挿入される文字幅を指定
set softtabstop=2
" ファイル内にあるタブ文字の表示幅
set tabstop=2
" ツールバーを非表示にする
set guioptions-=T
" yでコピーした時にクリップボードに入る
set guioptions+=a
" メニューバーを非表示にする
set guioptions-=m
" 右スクロールバーを非表示
set guioptions+=R
" 対応する括弧を強調表示
set showmatch
" 改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set smartindent
" スワップファイルを作成しない
set noswapfile
" タイトルを表示
set title
" 行番号の表示
set number
" Escの2回押しでハイライト消去
nnoremap <Esc><Esc> :nohlsearch<CR><ESC>
" シンタックスハイライト
syntax on
" すべての数を10進数として扱う
set nrformats=
" 行をまたいで移動
set whichwrap=b,s,h,l,<,>,[,],~
" バッファスクロール
set mouse=a
" セミコロンをコロン
nnoremap ; :
"選択範囲のインデントを連続して変更
vnoremap < <gv
vnoremap > >gv
" 畳み込み
set foldmethod=syntax
set foldnestmax=1
" 折り返し部分を見やすくする
set showbreak=↪
" 矢印キーでなら行内を動けるように
nnoremap <Down> gj
nnoremap <Up>   gk
" 日本語入力がオンのままでも使えるコマンド(Enterキーは必要)
nnoremap あ a
nnoremap い i
nnoremap う u
nnoremap お o
nnoremap っd dd
nnoremap っy yy
"undoできる数
set undolevels=100
" クリップボードにコピー
set clipboard=unnamed
" pasteモード解除
autocmd InsertLeave * set nopaste
" jj でEsc
inoremap <silent> jj <ESC>
" 行末の余分なスペースを取り除く
function! RTrim()
  let s:cursor = getpos(".")
  if &filetype == "markdown"
    %s/\s\+\(\s\{2}\)$/\1/e
    match Underlined /\s\{2}/
  else
    %s/\s\+$//e
  endif
  call setpos(".", s:cursor)
endfunction

call submode#enter_with('bufmove', 'n', '', '<Leader>.', '<C-w>15>')
call submode#enter_with('bufmove', 'n', '', '<Leader>,', '<C-w>15<')
call submode#enter_with('bufmove', 'n', '', '<Leader>=', '<C-w>15+')
call submode#enter_with('bufmove', 'n', '', '<Leader>-', '<C-w>15-')

" auto reload .vimrc
augroup source-vimrc
  autocmd!
  autocmd BufWritePost *vimrc source $MYVIMRC | set foldmethod=marker
  autocmd BufWritePost *gvimrc if has('gui_running') source $MYGVIMRC
augroup END

" auto comment off
augroup auto_comment_off
  autocmd!
  autocmd BufEnter * setlocal formatoptions-=r
  autocmd BufEnter * setlocal formatoptions-=o
augroup END

" HTML/XML閉じタグ自動補完
augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

" 編集箇所のカーソルを記憶
if has("autocmd")
  augroup redhat
    " In text files, always limit the width of text to 78 characters
    autocmd BufRead *.txt set tw=78
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
  augroup END
endif

" Theme
if has('nvim')
  " For Neovim 0.1.3 and 0.1.4
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  " Or if you have Neovim >= 0.1.5
  if (has("termguicolors"))
    set termguicolors
  endif
  " Theme
  syntax enable
  colorscheme OceanicNext
else
  syntax enable
  set t_Co=256
  if (has("termguicolors"))
    set termguicolors
  endif
  colorscheme OceanicNext
endif
set cmdheight=2

" テーマカスタマイズ
set cursorline
hi CursorLineNr term=bold cterm=Bold ctermfg=237 ctermbg=209 gui=reverse guifg=#343d46 guibg=#f99157
hi clear Folded
hi Folded term=bold cterm=Bold ctermfg=240 ctermbg=235 guifg=#585858 guibg=#262626
