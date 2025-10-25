local keymap = vim.keymap

-- increment/decrement
keymap.set('n', '+', '<C-a>')
keymap.set('n', '-', '<C-x>')

-- 全選択
keymap.set('n', '<C-a>', 'gg<S-v>G')

-- 新しいタブ
keymap.set('n', 'te', ':tabedit<Return>', { silent = true })
-- ウィンドウの分割
keymap.set('n', 'sv', ':split<Return><C-w>w', { silent = true })
keymap.set('n', 'ss', ':vsplit<Return><C-w>w', { silent = true })
-- ウインドウの移動
keymap.set('n', '<Space>', '<C-w>w')
keymap.set('', 's<left>', '<C-w>h ')
keymap.set('', 's<up>', '<C-w>k')
keymap.set('', 's<down>', '<C-w>j')
keymap.set('', 's<right>', '<C-w>l')
keymap.set('', 'sh', '<C-w>h')
keymap.set('', 'sk', '<C-w>k')
keymap.set('', 'sj', '<C-w>j')
keymap.set('', 'sl', '<C-w>l')
-- ウインドウのリサイズ
keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')
