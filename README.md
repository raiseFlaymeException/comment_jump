# Comment Jump

A neovim extension to highlight comments and jump to if from code

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Example](#example)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

If you use [packer](https://github.com/wbthomason/packer.nvim):
```lua
use 'raiseFlaymeException/comment_jump'
```

## Usage

in your after folder
```lua
require("comment_jump").setup({
    comments={{regex="TODO", fg="red"}}
})
```

- <p>regex</p> is a [regex vim style](https://vimregex.com/) to match for each comment 
- <p>color</p> is a color from vim to color each comment (see: https://codeyarns.com/tech/2011-07-29-vim-chart-of-color-names.html)

## Example

```lua
{
    "raiseFlaymeException/comment_jump",
    opts = {
        remove_spaces = false, -- don't remove the spaces after the comment (example: -- TODO won't work whereas --TODO will)
        comments={
            {regex="^TODO.*$", fg="red"}, -- match any comment starting with TODO
            {regex="!", fg="#6e6600", bg="blue"}
        } -- list of comment to hilight in color <color>
    },
    dependencies = { { "nvim-treesitter/nvim-treesitter" } }
},
```

```lua
require("comment_jump").setup({
    remove_spaces = false, -- don't remove the spaces after the comment (example: -- TODO won't work whereas --TODO will)
    comments={
        {regex="^TODO.*$", fg="red"}, -- match any comment starting with TODO
        {regex="!", fg="#6e6600", bg="blue"}
    }, -- list of comment to hilight in color <color>
    requires = { {"nvim-treesitter/nvim-treesitter"} }
})
```

## Maintainers

[@raiseFlaymeException](https://github.com/raiseFlaymeException).

## Contributing

Feel free to contibute [Open an issue](https://github.com/raiseFlaymeException/comment_jump/issues/new) or submit PRs
(especially for language support).

## License

[ZLIB](LICENSE) © raiseFlaymeException
