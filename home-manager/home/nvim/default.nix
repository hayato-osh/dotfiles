{ config, lib, pkgs, lazyvim, ... }:

{
  imports = [ lazyvim.homeManagerModules.default ];

  programs.lazyvim = {
    enable = true;

    # ripgrep / fd など LazyVim が前提とする基本依存をまとめて入れる
    installCoreDependencies = true;

    plugins.colorscheme = ''
      return {
        "cocopon/iceberg.vim",
        lazy = false,
        priority = 1000,
        config = function()
          vim.cmd.colorscheme("iceberg")
        end,
      }
    '';

    plugins.overrides = ''
      return {
        {
          "nvim-mini/mini.pairs",
          event = "VeryLazy",
          opts = {
            modes = { insert = true, command = true, terminal = false },
            skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
            skip_ts = { "string" },
            skip_unbalanced = true,
            markdown = true,
          },
          config = function(_, opts)
            LazyVim.mini.pairs(opts)
          end,
        },
        {
          "folke/todo-comments.nvim",
          cmd = { "TodoTrouble", "TodoTelescope" },
          event = "LazyFile",
          opts = {},
          keys = {
            { "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
            { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
            { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
            { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
            { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
            { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
          },
        },
      }
    '';
  };
}
