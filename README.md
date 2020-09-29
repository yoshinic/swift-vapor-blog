# ブログアプリ
 
Swift Web Framework の [Vapor](https://docs.vapor.codes/4.0/) を使用した自作のブログアプリです。

<br>
<br>

# 確認している環境
 
* macOS 10.15 ~
* Swift 5.2 ~
* Vapor 4.29.0 ~
* PostgreSQL 12.3 ~

<br>
<br>

# 使用方法

### 実行するまでの流れ

<br>

0. [Homebrew](https://brew.sh/index_ja) のインストール
1. [Docker](https://circleci.com/docker/index.html) のインストール
2. Swift が実行できる環境をつくる
3. Vapor をインストールする
4. PostgreSQL をインストールする
5. このアプリを GitHub からクローンして実行ファイル作成
6. Vapor .env ファイルによる環境変数を設定
7. アプリ実行

<br>

### 0.Homebrew のインストール

<br>

[Homebrew](https://brew.sh/index_ja) というのは Mac のパッケージ管理アプリです。
これを使ってアプリやライブラリをインストールすれば、そのバージョン管理などが簡単になります。<br>
まずはこれをインストールします。ターミナルを開いて下記を実行して下さい。

```
~$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
これで brew コマンドが使用出来るようになりました。

<br>

### 1. Docker のインストール

<br>

次に [Docker](https://circleci.com/docker/index.html) をインストールします。仮想環境を整えてくれます。

```
~$ brew update
~$ brew cask install docker
```

この後、Docker アプリを起動します。<br>
おそらく Mac の管理者パスワードを求められると思いますので入力します。<br>
これで Docker がインストールされ、 docker コマンドが使用出来ます。

<br>

### 2. Swift が実行できる環境をつくる

<br>

[Swift の公式サイト](https://swift.org/download/#docker)に Docker を使用した Swift 環境の整え方が掲載されています。


```
~$ docker pull swift
~$ docker run --privileged --interactive --tty \
--name swift-latest swift:latest /bin/bash
```

そのまま Docker コンテナに入りますので、Swift のバージョンを確認します。<br>
「57e066e55e27」という数字の箇所は、私と同じになるとは限りません。

```
root@57e066e55e27:/# swift --version
Swift version 5.3 (swift-5.3-RELEASE)
Target: x86_64-unknown-linux-gnu
```

<br>

### 3. Vapor をインストールする

<br>

Vapor を利用するための Vapor Toolbox というものをインストールします。これにより vapor コマンドが使えるようになり、build や run などが簡単に行えるようになります。<br>
これも[公式サイト](https://docs.vapor.codes/4.0/install/linux/#install-toolbox)にインストール方法があり、[こちら](https://github.com/vapor/toolbox/releases)から toolbox の最新バージョンを確認してインストールします。執筆時点では「18.2.2」です。

```
root@57e066e55e27:/# git clone https://github.com/vapor/toolbox.git
root@57e066e55e27:/# cd toolbox
root@57e066e55e27:/toolbox# git checkout 18.2.2
root@57e066e55e27:/toolbox# make install
```

少し警告が出ますが大丈夫です。インストールできたか確認します。

```
root@57e066e55e27:/toolbox# vapor --help
Usage: vapor <command>

Vapor Toolbox (Server-side Swift web framework)

Commands:
       build Builds an app in the console.
       clean Cleans temporary files.
      heroku Commands for working with Heroku
         new Generates a new app.
         run Runs an app from the console.
  supervisor Commands for working with Supervisord
       xcode Opens an app in Xcode.

Use `vapor <command> [--help,-h]` for more information on a command.
```

このような Help の説明が出れば OK です。
一応カレントディレクトリを戻します。

```
root@57e066e55e27:/toolbox# cd ..
```

<br>

### 4. PostgreSQL をインストールする

<br>

```
root@57e066e55e27:/# apt-get update
root@57e066e55e27:/# apt-get install wget -y
root@57e066e55e27:/# sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
root@57e066e55e27:/# wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -

root@57e066e55e27:/# apt-get update
root@57e066e55e27:/# apt-get install postgresql -y

root@57e066e55e27:/# su postgres
postgres@57e066e55e27:/# createuser --createdb --username=postgres --pwprompt postgres_vapor

// パスワード入力（何でも良いです）
Enter password for new role: （例：password）
Enter it again:　（上と同じ文字列）

// バージョンを確認します。
postgres@57e066e55e27:/# psql --version
psql (PostgreSQL) 12.4 (Ubuntu 12.4-1.pgdg18.04+1)
```

postgres ユーザーからログアウトします。

```
postgres@57e066e55e27:/#　exit
root@57e066e55e27:/toolbox# cd ..
```

<br>

### 5. このアプリを GitHub からクローンして実行ファイル作成

<br>

```
root@57e066e55e27:/# git clone https://github.com/yoshiswift/swift-vapor-blog.git
root@57e066e55e27:/# cd swift-vapor-blog
root@57e066e55e27:/swift-vapor-blog# swift build
```

<br>

### 6. 環境変数の設定

<br>

Vapor では、 Vapor 用の環境変数を設定出来ます。<br>

[Vapor's Environment API](https://docs.vapor.codes/4.0/environment/)

これはプログラムの外側から設定できるので、作成した Web アプリの構成を動的に変える事が出来ます。<br>

私のアプリで設定できる項目は下記の通りです。<br><br>


- SERVER_PORT　・・・　Vapor サーバーのポート番号
- DEFAULT_MAX_BODY_SIZE　・・・　クライアントからサーバーへ送信するブログデータサイズの最大値

- （PostgreSQLの設定）
    - DATABASE_HOST　・・・　ホスト名
    - DATABASE_PORT　・・・　ポート番号
    - DATABASE_USERNAME　・・・　ユーザー名
    - DATABASE_PASSWORD　・・・　パスワード
    - DATABASE_NAME　・・・　ブログデータの保存に使用するデータベース名

- （アプリの管理ユーザーを作成）<br>
ブログの閲覧は誰でも出来ますが、ブログの保存や削除はログイン後に出来るようになります。
    - USER_NAME　・・・　ブログアプリ上で表示されるユーザー名
    - USER_USERNAME　・・・　データベースで使用するユーザー名
    - USER_PASSWORD　・・・　パスワード

<br>

では実際に作成してみます。<br>
ターミナルを開いて下記を入力してください。<br>
ここでは、nano というコマンドライン上のテキストエディタを使用して、「.env.development」という（少し変な）名前のファイルを新規作成しています。

```bash
~/Desktop/swift-vapor-blog$ nano .env.development
```

ターミナル上でテキストエディタが開いたと思いますので上記の項目を入力します。<br>
下記はその一例です。

例
```
SERVER_PORT=8081
DEFAULT_MAX_BODY_SIZE=10mb

DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=vapor
DATABASE_PASSWORD=password
DATABASE_NAME=mydb

USER_NAME=VAPOR
USER_USERNAME=vapor
USER_PASSWORD=9999
```



実行

```bash
./.build/debug/Run
```
