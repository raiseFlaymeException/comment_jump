# Comment Jump

A neovim extension to highlight comments and jump to if from code

## Table of Contents

- [Install](#install)
- [Usage](#usage)
	- [Generator](#generator)
- [Badge](#badge)
- [Example Readmes](#example-readmes)
- [Related Efforts](#related-efforts)
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
require("comment_jump").Setup({{regex="TODO", color="red"}})
```

- <p>regex</p> is a [regex vim style](https://vimregex.com/) to match for each comment 
- <p>color</p> is a color from vim to color each comment 

## Example Readmes

```lua
require("comment_jump").Setup({{regex="TODO", color="red"}, {regex="!", color="#6e6600"}})
```

## Maintainers

[@raiseFlaymeException](https://github.com/raiseFlaymeException).

## Contributing

Feel free to contibute [Open an issue](https://github.com/raiseFlaymeException/comment_jump/issues/new) or submit PRs.

## License

[ZLIB](LICENSE) © raiseFlaymeException
