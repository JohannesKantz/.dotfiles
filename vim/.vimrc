set hidden
set encoding=utf-8
" history
set history=500
" set to auto read when a file is changed from the outside
set autoread
au FocusGained,BufEnter * checktime

set noshowmode

set bg=dark                     " background color



set mouse=a                     " enable mouse
set guicursor=
" Cursor settings:
"  1 -> blinking block
"  2 -> solid block 
"  3 -> blinking underscore
"  4 -> solid underscore
"  5 -> blinking vertical bar
"  6 -> solid vertical bar
" insert mode: line
let &t_SI = "\e[6 q"
" normal mode: block
let &t_EI = "\e[2 q"


syntax enable
syntax on                       " turns syntax highlighting on


set number                      " print the line number in front of each line
set cursorline                  " highlight the screen line of the cursor
set colorcolumn=80              " highlighted line at 80
set nowrap                      " no textwrap


set showcmd                     " show command in the last line of the screen
set cmdheight=2                 " height if the command-line
set scrolloff=6                 " minimal number of screen lines to keep above and below the cursor


" tab stuff
set smarttab                    " makes indentation smart
set tabstop=4                   " tab width
set softtabstop=4               " tab width while performing editing operations
set shiftwidth=4                " number of spaces to use for each step of (auto)indent
set expandtab                   " use spaces instead of tabs

set autoindent                  " copy indent from current line when starting a new line
set smartindent                 " smart autoindenting when starting a new line


" turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif



" search
set hlsearch                    " highlight search
set incsearch                   " search while typing
" Disable highlight when <leader><cr>(\ + Return) is pressed
map <silent> <leader><cr> :noh<cr>



set backspace=eol,start,indent  " Configure backspace so it acts as it should act
set whichwrap+=<,>,h,l          " jump to next line when moving the cursor horizontal

" annoying stuff
set noerrorbells                " no annoying error sounds

" Map <C-L> (redraw screen) to also turn off search highlighting until next search
nnoremap <C-L> :nohl<CR><C-L>


" vim-plug (https://github.com/junegunn/vim-plug)
call plug#begin()
    
    " Appearance
    Plug 'rafi/awesome-vim-colorschemes'

    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'


    " collection of language packs
    Plug 'sheerun/vim-polyglot'

    Plug 'ap/vim-css-color'
  
call plug#end()


" enable true colors (24 bit)
set termguicolors

" Color Scheme (https://github.com/rafi/awesome-vim-colorschemes)
"colorscheme onehalfdark
colorscheme gruvbox



"
"   Airline
"

" Status Bar (https://github.com/vim-airline/vim-airline-themes)
let g:airline_theme='deus'

" Tab Bar
let g:airline#extensions#tabline#enabled = 1

" enable powerline fonts
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif


" unicode symbols
let g:airline_left_sep = '▶'
let g:airline_left_sep = '»'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" powerline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.colnr = ':'
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ' :'
let g:airline_symbols.maxlinenr = '☰ '
let g:airline_symbols.dirty='⚡'

