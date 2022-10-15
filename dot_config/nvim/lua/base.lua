vim.cmd('autocmd!')

-- エンコーディング
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

vim.wo.number = true

vim.opt.title = true

-- 新しい行を開始したとき新しい行のインデントを現在行と同じにする
vim.opt.autoindent = true
-- 前回の検索パターンが存在するとき、それにマッチするテキストをすべて強調表示
vim.opt.hlsearch = true
-- ファイルを上書きする前にバックアップを作る
vim.opt.backup = false
-- コマンドの一部を画面の最下行に表示する
vim.opt.showcmd = true
-- コマンドラインに使われる画面上の行数
vim.opt.cmdheight = 1
-- 最下ウインドウに常にステータスを表示する
vim.opt.laststatus = 2
-- insert modeで<Tab>を挿入するとき、代わりに適切な数の空白を使う
vim.opt.expandtab = true
-- カーソルの上または下に、最低でも指定した数の行を表示させる
vim.opt.scrolloff = 10
-- シェルの名前
vim.opt.shell = 'zsh'
-- 書き込みをするファイルの名前にマッチするパターンがあれば、バックアップファイルが作られない
vim.opt.backupskip = '/tmp/*,/private/tmp/*'
-- 検索と複雑な検索と置換の両方をライブでプレビューすることができる
vim.opt.inccommand = 'split'
-- 検索パターンにおいて大文字と小文字を区別しない
vim.opt.ignorecase = true
-- 行頭の余白内で<Tab>を打ち込むと'shiftwidth'の数だけ空白挿入される
vim.opt.smarttab = true
-- 折り返された行を同じインデントで表示する
vim.opt.breakindent = true
-- インデントの空白の数
vim.opt.shiftwidth = 2
-- ファイル内の<Tab>が対応する空白の数
vim.opt.tabstop = 2
-- 折返しは行われれず、長い行は一部のみが表示される
vim.opt.wrap = false
-- eol: 改行を超えてバックスペースを働かせる
-- start: 挿入区間の始めでバックスペースを働かせるがctrl-w, ctrl-uは挿入区間の始めで一旦止まる
-- indent: autoindentを超えてバックスペースを働かせる
vim.opt.backspace = 'start,eol,indent'

vim.opt.path:append  { '**' } -- Finding files - Search down into subfolders
vim.opt.wildignore:append { '*/node_moduels/*' }

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
-- but this doesn't work on iTerm2.

-- insertモードから離れるときにpasteモードを止める
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = '*',
  command = "set nopaste"
})

vim.opt.formatoptions:append { 'r' }
