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

" Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'} " 入力補完
Plug 'roxma/nvim-yarp'
Plug 'roxma/vim-hug-neovim-rpc'

" all
Plug 'Shougo/unite.vim' "統合ユーザインターフェース
Plug 'Shougo/vimfiler' " File Viwer
Plug 'tomtom/tcomment_vim' " Comment作成
Plug 'kassio/neoterm' " neovimのterminalをカスタマイズ
Plug 'ConradIrwin/vim-bracketed-paste' " コピペずれしないようにする
Plug 'ctrlpvim/ctrlp.vim' " ファイル検索
Plug 'majutsushi/tagbar' " tagを一覧する
Plug 'cohama/lexima.vim' " 閉じ括弧をいい感じにする
Plug 'mattn/emmet-vim' " emmet
Plug 'w0rp/ale' " 非同期文法チェック
Plug 'itchyny/lightline.vim' " ステータスライン
Plug 'itchyny/vim-gitbranch' " gitブランチ名を取得する lightline.vimに使う
Plug 'tpope/vim-fugitive' " git
Plug 'mhartington/oceanic-next' " カラーテーマ
Plug 'kana/vim-submode' " サブモードを定義
Plug 'haya14busa/vim-operator-flashy' " テキスト選択範囲の見える化
Plug 'haya14busa/incsearch.vim' " 検索文字列のハイライトをいい感じにする
Plug 'osyo-manga/vim-over' " 文字列置換の可視化
Plug 'tyru/operator-camelize.vim' " キャメルケースとスネークケースの切り替え \c
Plug 'kana/vim-operator-user' " tyru/operator-camelize.vimで使う
Plug 'rhysd/vim-grammarous' " 文法チェック
Plug 'rhysd/ghpr-blame.vim' " git blame
Plug 'szw/vim-tags' " ctagsを保存する度に自動生成
Plug 'Chiel92/vim-autoformat' " フォーマッター
Plug 'fuenor/qfixhowm' " メモ系 https://qiita.com/mago1chi/items/bd9b756d4fc1abfc6224
Plug 'rhysd/vim-fixjson', {'for': 'json'} " json fix
Plug 'jparise/vim-graphql', {'for': ['graphql', 'graphqls', 'gql']} " graphql syntax
Plug 'chr4/nginx.vim' " nginx syntax
Plug 'k0kubun/vim-open-github' " OpenGithub

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

call plug#end()

filetype plugin indent on

"---------------------------------------u
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
" vim-scripts/nginx.vim
"----------------------------------------
au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/*,nginx*.conf if &ft == '' | setfiletype nginx | endif
"----------------------------------------
" fuenor/qfixhowm
"----------------------------------------
" m,i：サイドメニューを表示する
" m,u：一時的なメモを開く
" m,：その日に紐付いたメモを開く
" m,q：カレンダーを確認する
" m,s：これまでに作成したメモから指定キーワードで横断検索
" キーマップリーダー
let QFixHowm_Key = 'm'
" howm_dirはファイルを保存したいディレクトリを設定
let howm_dir             = expand('~/Dropbox/memo')
let howm_filename        = '%Y/%m/%Y-%m-%d-%H%M%S.md'
let howm_fileencoding    = 'utf-8'
let howm_fileformat      = 'dos'
" キーコードやマッピングされたキー列が完了するのを待つ時間(ミリ秒)
set timeout timeoutlen=3000 ttimeoutlen=100
" " プレビューや絞り込みをQuickFix/ロケーションリストの両方で有効化(デフォル
" ト:2)
let QFixWin_EnableMode = 1
" QFixHowmのファイルタイプ
" 私がよくmarkdown使うので以下のように設定
let QFixHowm_FileType = 'markdown'
" タイトル記号を # に変更する(markdown使用の都合上)
let QFixHowm_Title = '#'
" QuickFixウィンドウでもプレビューや絞り込みを有効化
let QFixWin_EnableMode = 1
" QFixHowm/QFixGrepの結果表示にロケーションリストを使用する/しない
let QFix_UseLocationList = 1
set shellslash
" textwidthの再設定
au Filetype qfix_memo setlocal textwidth=0
" 休日定義ファイル
let QFixHowm_HolidayFile = expand('~/dotfiles/nvim/plugged/qfixhowm/misc/holiday/Sche-Hd-0000-00-00-000000.utf8')
" オートリンクでファイルを開く
let QFixHowm_Wiki = 1
"----------------------------------------
" rhysd/vim-fixjson
"----------------------------------------
let g:fixjson_fix_on_save = 1
"----------------------------------------
" szw/vim-tags
"----------------------------------------
let g:vim_tags_project_tags_command = "/usr/local/bin/ctags -R {OPTIONS} {DIRECTORY} 2>/dev/null"
let g:vim_tags_gems_tags_command = "/usr/local/bin/ctags -R {OPTIONS} `bundle show --paths` 2>/dev/null"
"----------------------------------------
" Chiel92/vim-autoformat
"----------------------------------------
let g:autoformat_verbosemode=1
"----------------------------------------
" grammar
"----------------------------------------
let g:grammarous#hooks = {}
function! g:grammarous#hooks.on_check(errs) abort
    nmap <buffer><C-n> <Plug>(grammarous-move-to-next-error)
    nmap <buffer><C-p> <Plug>(grammarous-move-to-previous-error)
endfunction

function! g:grammarous#hooks.on_reset(errs) abort
  nunmap <buffer><C-n>
  nunmap <buffer><C-p>
endfunction
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
" let g:user_emmet_leader_key='<Leader>'
let g:user_emmet_install_global = 0
autocmd FileType html,css,tmpl,tpl EmmetInstall
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
autocmd FileType php,html,javascript,rb nnoremap <C-]> g<C-]> 
"----------------------------------------
" snip
"----------------------------------------
imap <Tab> <Plug>snipMateNextOrTrigger
"----------------------------------------
" ale
"----------------------------------------
let g:ale_lint_on_text_changed = 'never'
let g:ale_list_window_size = 3
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1
let g:ale_sign_column_always = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_open_list = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
nmap <silent> <xRight> <Plug>(ale_previous)
nmap <silent> <xLeft> <Plug>(ale_next)
nmap <silent> <xLeft> <Plug>(ale_next)
" language
let g:ale_linters = {
\ 'go': ['gometalinter'],
\ 'python': ['flake8'],
\}
" setting
" pip install flake8
let g:ale_python_flake8_args = '--max-line-length=120'
" go get -u github.com/alecthomas/gometalinter
" gometalinter --install
let g:ale_go_gometalinter_options = '--vendored-linters --disable-all --enable=gotype --enable=vet --enable=golint -t'
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
" operator-camelize
" vim-operator-user
"----------------------------------------
" \c
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
" インデント
"----------------------------------------
autocmd FileType c           setlocal sw=4 sts=4 ts=4 et
autocmd FileType html        setlocal sw=4 sts=4 ts=4 et
autocmd FileType ruby        setlocal sw=2 sts=2 ts=2 et
autocmd FileType js          setlocal sw=4 sts=4 ts=4 et
autocmd FileType zsh         setlocal sw=4 sts=4 ts=4 et
autocmd FileType python      setlocal sw=4 sts=4 ts=4 et
autocmd FileType scala       setlocal sw=4 sts=4 ts=4 et
autocmd FileType json        setlocal sw=4 sts=4 ts=4 et
autocmd FileType html        setlocal sw=4 sts=4 ts=4 et
autocmd FileType css         setlocal sw=4 sts=4 ts=4 et
autocmd FileType scss        setlocal sw=4 sts=4 ts=4 et
autocmd FileType sass        setlocal sw=4 sts=4 ts=4 et
autocmd FileType javascript  setlocal sw=4 sts=4 ts=4 et
"----------------------------------------
" 畳み込み
"----------------------------------------
set foldmethod=manual
autocmd FileType ruby :set foldlevel=1
autocmd FileType ruby :set foldnestmax=2
autocmd FileType go :set foldmethod=indent
autocmd FileType go :set foldnestmax=1
autocmd FileType json :set foldmethod=manual
autocmd FileType sql :set foldmethod=manual
" http://thinca.hatenablog.com/entry/20110523/1306080318
augroup foldmethod-expr
  autocmd!
  autocmd InsertEnter * if &l:foldmethod ==# 'expr'
  \                   |   let b:foldinfo = [&l:foldmethod, &l:foldexpr]
  \                   |   setlocal foldmethod=manual foldexpr=0
  \                   | endif
  autocmd InsertLeave * if exists('b:foldinfo')
  \                   |   let [&l:foldmethod, &l:foldexpr] = b:foldinfo
  \                   | endif
augroup END
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
" Escの2回押しでハイライト消去
nnoremap tn :tabnew<CR>
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
" For Neovim 0.1.3 and 0.1.4
" let $NVIM_TUI_ENABLE_TRUE_COLOR=1
" Or if you have Neovim >= 0.1.5
" if (has("termguicolors"))
"   set termguicolors
" endif
" Theme
syntax enable
colorscheme OceanicNext
set cmdheight=2

" テーマカスタマイズ
" set cursorline
" hi CursorLineNr term=bold cterm=Bold ctermfg=237 ctermbg=209 gui=reverse guifg=#343d46 guibg=#f99157
hi clear Folded
hi Folded term=bold cterm=Bold ctermfg=240 ctermbg=235 guifg=#585858 guibg=#262626
