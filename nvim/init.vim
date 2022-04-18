"use system colorsset nocompatible
"lua require('~/.config/nvim/config/config.lua')

filetype off
set rtp+=~/.config/nvim/bundle/Vundle.vim
call vundle#begin()

" This is the Vundle package, which can be found on GitHub.
" For GitHub repos, you specify plugins using the
" 'user/repository' format
Plugin 'VundleVim/Vundle.vim'

" We could also add repositories with a ".git" extension
Plugin 'scrooloose/nerdtree.git'

" To get plugins from Vim Scripts, you can reference the plugin
" by name as it appears on the site
Plugin 'Buffergator'

" Now we can turn our filetype functionality back on
filetype plugin indent on
"Plugin 'sonph/onehalf', {'rtp': 'vim/'}
Plugin 'sheerun/vim-polyglot'
"Plugin 'xuhdev/vim-latex-live-preview'
Plugin 'chriskempson/base16-vim'
Plugin 'chrisbra/colorizer'
Plugin 'dylanaraps/wal'
"Plugin 'neovim/nvim-lspconfig'
Plugin 'haorenW1025/completion-nvim'
Plugin 'nvim-treesitter/nvim-treesitter'
Plugin 'nvim-treesitter/completion-treesitter'
"Plugin 'nvim-lua/completion-nvim'
"Plugin 'norcalli/nvim-base16.lua'
Plugin 'neoclide/coc.nvim'
"Plugin 'nvim-lua/popup.nvim'
"Plugin 'nvim-lua/plenary.nvim'
"Plugin 'neovim/nvim-lspconfig'
Plugin 'github/copilot.vim'
Plugin 'nvim-telescope/telescope.nvim'
call vundle#end()
"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif



set background=dark 
syntax on
set tabstop=4
set expandtab
set autoindent
set number
set cursorline
let g:onedark_termcolors=16
set mouse=a
colorscheme wal
let base16colorspace=256
colorscheme base16-seti
colorscheme base16-synth-midnight-dark
ab pdfpreview LLPStratPreview
let g:polyglot_disabled = ['latex']
let g:onedark_bg = 'darkest'
let mapleader = ","
nmap <leader>nt :NERDTree<cr>
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
set clipboard+=unnamedplus
