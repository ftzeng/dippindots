" Has to be defined first
let mapleader=";"

lua require('plugins')
lua require('verses')

" navigation
set number            			" Show line numbers
set nostartofline 				" Don't reset cursor to start of line when moving
set cursorline 				    " Highlight current line
set scrolloff=3 				" Start scrolling three lines before border
set showmatch 					" Show matching brackets
let &showbreak='↳ '             " Show this at the start of wrapped lines
set laststatus=0                " Never show the status bar
set relativenumber 			    " Use relative line numbering

" whitespace
set wrap                          " Wrap lines
set tabstop=4                     " Set tab spaces
set shiftwidth=4                  " Set autoindent (with <<) spaces
set expandtab                     " Use spaces, not tabs
set list                          " Show invisible characters
set smartindent
set autoindent
set backspace=indent,eol,start    " Backspace through everything in insert mode

" search
set incsearch   " Search as pattern is typed
set ignorecase  " Case insensitive searches...
set smartcase   " Unless they contain 1+ capital letters
set hlsearch    " Highlight search matches
set gdefault 	" Global search/replace by default

" misc config
set conceallevel=1
set noerrorbells 				" Disable error bells
set novisualbell                " Disable visual bells
set showmode 					" Show the current mode
set showcmd 					" Show the command as it's typed
set shortmess=atI 				" Hide Vim intro message
set wrap
set hidden
set textwidth=0 wrapmargin=0 formatoptions=cq
set display+=lastline
set updatetime=750
set switchbuf+=usetab
set clipboard^=unnamed,unnamedplus " Use OS clipboard
set completeopt=menu,menuone,noselect   " Autocomplete settings

" Shorter timeout to avoid lag,
" this is used for multi-key bindings,
" e.g. how long to wait to see if another key is coming
" for bindings like `<leader>db`.
set timeoutlen=250

" list chars (i.e. hidden characters)
set listchars=""                  " Reset the listchars
set listchars=tab:\ \             " A tab should display as "  "
set listchars+=trail:.            " Show trailing spaces as dots
set listchars+=extends:>          " The character to show in the last column when wrap is
                                  " off and the line continues beyond the right of the screen
set listchars+=precedes:<         " The character to show in the last column when wrap is
                                  " off and the line continues beyond the right of the screen

" centralize backup, swap, & undo files
set backupdir^=~/.vim/.backup// 	" Backup files
set directory^=~/.vim/.temp// 		" Swap files
if exists("&undodir")
	set undodir=~/.vim/.undo 		" Undo files
    set undofile
    set undolevels=500
    set undoreload=500
endif

" webbrowser for `gx`
let g:netrw_browsex_viewer='firefox'

" don’t add empty newlines at the end of files
set noeol

" specify how vim saves files
" so it works better with processes
" that watch files for changes
set backupcopy=yes

" automatically trim trailing whitespace on save.
autocmd BufWritePre * :%s/\s\+$//e

" bind return to clear last search highlight.
nnoremap <CR> :noh<CR><CR>

" tabs
map gr gT
nnoremap [t :tabprevious<cr>
nnoremap ]t :tabnext<cr>

" bind jk to escape
imap jk <Esc>
xnoremap jk <Esc>

" open new line from insert mode
imap <C-o> <esc>o

" quick buffer nav
nnoremap [b :bprevious<cr>
nnoremap ]b :bnext<cr>

" quickfix nav
nnoremap [c :cprev<cr>
nnoremap ]c :cnext<cr>
" close quickfix/location list
nnoremap <leader>q :ccl <bar> lcl<cr>

" bind | and _ to vertical and horizontal splits
nnoremap <expr><silent> \| !v:count ? "<C-W>v<C-W><Right>" : '\|'
nnoremap <expr><silent> _  !v:count ? "<C-W>s<C-W><Down>"  : '_'

" new tab
nmap <S-t> :tabnew<cr>

" show current filename
nnoremap <C-h> :f<cr>

" command flubs
command WQ wq
command Wq wq
command W w
command Q q

" more convenient 'anchoring'
" hit `mm` to drop a mark named 'A'
" hit `;m` to return to that mark
nnoremap mm mA
nnoremap <leader>m `A

" filetypes
filetype plugin indent on
if has("autocmd")
  " make Python follow PEP8 for whitespace (http://www.python.org/dev/peps/pep-0008/)
  au FileType python setlocal softtabstop=4 tabstop=4 shiftwidth=4

  " other filetype specific settings
  au FileType crontab setlocal backupcopy=yes
  au FileType css setlocal tabstop=2 shiftwidth=2
  au FileType sass setlocal tabstop=2 shiftwidth=2
  au FileType javascript setlocal tabstop=2 shiftwidth=2
  au FileType typescript setlocal tabstop=2 shiftwidth=2
  au FileType typescriptreact setlocal tabstop=2 shiftwidth=2

  " for text
  au FileType text setlocal nocursorcolumn spell complete+=kspell

  " remember last location in file, but not for commit messages.
  au BufReadPost * if &filetype !~ '^git\c' && line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g`\"" | endif

  " gliss scripts
  autocmd BufNewFile,BufRead *.script set filetype=script
  au FileType script setlocal tabstop=2 shiftwidth=2
endif

" ctrl-w + o to toggle maximizing a window
function! MaximizeToggle()
  if exists("s:maximize_session")
    exec "source " . s:maximize_session
    call delete(s:maximize_session)
    unlet s:maximize_session
    let &hidden=s:maximize_hidden_save
    unlet s:maximize_hidden_save
  else
    let s:maximize_hidden_save = &hidden
    let s:maximize_session = tempname()
    set hidden
    exec "mksession! " . s:maximize_session
    only
  endif
endfunction
nnoremap <c-w>o :call MaximizeToggle()<CR>

" Delete no name, empty buffers when leaving a buffer
" to keep the buffer list clean
function! CleanNoNameEmptyBuffers()
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val) && empty(bufname(v:val)) && bufwinnr(v:val) < 0 && (getbufline(v:val, 1, "$") == [""])')
    if !empty(buffers)
        exe 'bd '.join(buffers, ' ')
    endif
endfunction
autocmd BufLeave * :call CleanNoNameEmptyBuffers()