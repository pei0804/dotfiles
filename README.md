# dotfiles

```console
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/pei0804/dotfiles/master/setup.sh)"
$ Dotfiles
$ make all
```

## antigen not found

```
$ rm -rf Dotfiles/antigen
$ git clone https://github.com/zsh-users/antigen.git antigen
```

## bashからzsh

[Macの環境設定(3) zshを入れる - Qiita](http://qiita.com/nenokido2000/items/763a4af5c161ff5ede68)

## ghq + peco

- gをタイプすると、$GOPATH以下のリポジトリをghq pecoを使って移動
- ghq get hoge.gitでリポジトリ追加
