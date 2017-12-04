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

Plug 'Shougo/unite.vim'
Plug 'Shougo/vimfiler'
Plug 'tomtom/tcomment_vim'
Plug 'itchyny/lightline.vim'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'majutsushi/tagbar'
Plug 'mattn/emmet-vim'
Plug 'w0rp/ale'
Plug 'itchyny/vim-gitbranch'
Plug 'mhartington/oceanic-next'

Plug 'fatih/vim-go', {'for': 'go'}
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plug 'zchee/deoplete-go', { 'do': 'make'}
else
  Plug 'Shougo/neocomplete.vim'
endif

call plug#end()

filetype plugin indent on
"=======================================
" nvim area
"=======================================
if has('nvim')
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
  " 設定
  "----------------------------------------
  set clipboard=unnamed
"=======================================
" vim area
"=======================================
else
  "----------------------------------------
  " neocompleate
  "----------------------------------------
  let g:neocomplete#enable_at_startup = 1
  " 補完を始めるキーワード長を長くする
  let g:neocomplete#sources#syntax#min_keyword_length = 4
  let g:neocomplete#auto_completion_start_length = 4
  " 補完が止まった際に、スキップする長さを短くする
  let g:neocomplete#skip_auto_completion_time = '0.2'
  " 使用する補完の種類を減らす
  " 現在のSourceの取得は `:echo keys(neocomplete#variables#get_sources())`
  " デフォルト: ['file', 'tag', 'neosnippet', 'vim', 'dictionary', 'omni', 'member', 'syntax', 'include', 'buffer', 'file/include']
  let g:neocomplete#sources = {
    \ '_' : ['vim', 'omni', 'include', 'buffer', 'file/include']
    \ }
  "----------------------------------------
  " 設定
  "----------------------------------------
  " ヤンクでクリップボードにコピー
  set clipboard=unnamed,autoselect
endif
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
autocmd FileType go nmap <leader>u  <Plug>(go-test-func)
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <leader>b  <Plug>(go-build)
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>d  <Plug>(go-doc)
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
" emmet https://mattn.kaoriya.net/software/vim/20100306021632.htm
"----------------------------------------
" <c-y>,
let g:user_emmet_leader_key='<leader>'
let g:user_emmet_install_global = 0
autocmd FileType html,css,tmpl EmmetInstall
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
" ステータス表示方法
let g:lightline = {
      \ 'component_function': {
      \   'filename': 'LightlineFilename',
      \   'gitbranch': 'gitbranch#name'
      \ },
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ }

function! LightlineFilename()
  return &filetype ==# 'vimfiler' ? vimfiler#get_status_string() :
        \ &filetype ==# 'unite' ? unite#get_status_string() :
        \ &filetype ==# 'vimshell' ? vimshell#get_status_string() :
        \ expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
endfunction

let g:unite_force_overwrite_statusline = 0
let g:vimfiler_force_overwrite_statusline = 0
let g:vimshell_force_overwrite_statusline = 0
"----------------------------------------
" 全体
"----------------------------------------

" <Leader>
let mapleader = "\<Space>"

" 閉じ括弧補完
inoremap { {}<Left>
inoremap {<Enter> {}<Left><CR><ESC><S-o>
"inoremap ( ()<ESC>i
"inoremap (<Enter> ()<Left><CR><ESC><S-o>

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
source $HOME/.vim/encode.vim

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
set foldmethod=indent
set foldnestmax=1
" 行を強調表示
set cursorline
" 列を強調表示
set cursorcolumn
"undoできる数
set undolevels=100

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
