set number
set relativenumber
set wildmenu
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab


syntax on
call plug#begin() 
Plug 'raimondi/delimitmate'
Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ervandew/supertab'
Plug 'lilydjwg/colorizer'
Plug 'joshdick/onedark.vim'
Plug 'girishji/vimcomplete'
Plug 'fatih/vim-go'


Plug 'prabirshrestha/vim-lsp'

Plug 'kien/ctrlp.vim'
Plug 'tpope/vim-markdown'

Plug 'vim-perl/vim-perl', { 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny' }
call plug#end()

colorscheme onedark
let g:airline_theme='onedark'


let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
let g:markdown_syntax_conceal = 0
let g:markdown_minlines = 100

"autocmd FileType java setlocal omnifunc=javacomplete#Complete

"let g:go_def_mode='gopls'
"let g:go_info_mode='gopls'

