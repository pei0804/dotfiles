" 基本設定
set nowrapscan
set ignorecase
set hlsearch
set scrolloff=8
set number
set visualbell
set noerrorbells
set clipboard=unnamed

" シンタックスハイライトを有効化
syntax enable

" カラースキームの設定（お好みで変更可能）
colorscheme desert

" インデント設定
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" キーマッピング
inoremap <C-]> <Esc>
vnoremap < <gv
vnoremap > >gv
inoremap <C-a> <C-o>^
inoremap <C-e> <C-o>$<Right>
inoremap <C-b> <Left>
inoremap <C-f> <Right>
inoremap <C-n> <Down>
inoremap <C-p> <Up>
inoremap <C-h> <BS>
inoremap <C-d> <Del>
inoremap <C-k> <C-o>D<Right>
inoremap <C-u> <C-o>d^

" タブ操作
nnoremap <Tab> gt
nnoremap <S-Tab> gT

" Yank関連
nnoremap Y y$
nnoremap <silent> cy ciw<C-r>0<ESC>:let@/=@1<CR>:noh<CR><ESC>
nnoremap <silent> ciy ce<C-r>0<ESC>:let@/=@1<CR>:noh<CR><ESC>

" 移動関連
nnoremap j gj
onoremap j gj
xnoremap j gj
nnoremap k gk
onoremap k gk
xnoremap k gk
nnoremap gj j
nnoremap gk k

" コマンドライン操作
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-l> <C-d>
cnoremap <C-d> <Delete>

" ; と : の入れ替え
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;
nnoremap q; q:
vnoremap q; q:

" Neovim特有の設定
set termguicolors  " True Colorサポート
set inccommand=split  " インクリメンタル置換のプレビュー

" ファイルタイプ別のプラグイン・インデント設定を有効化
filetype plugin indent on
