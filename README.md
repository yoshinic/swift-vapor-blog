# ブログアプリ
 
Swift Web Framework の [Vapor](https://docs.vapor.codes/4.0/) を使用した自作のブログアプリです。

<br>

# 確認している環境
 
* macOS 10.15 ~
* Swift 5.2 ~
* Vapor 4.29.0 ~
* PostgreSQL 12.3 ~

<br>

# デモ

### トップ画面

<br>

![トップ画面](https://user-images.githubusercontent.com/64339302/94624498-8d8af480-02f1-11eb-906c-750c65fe33f8.png)

<br>

### ブログ作成・編集画面

<br>

![編集画面](https://user-images.githubusercontent.com/64339302/94624711-05591f00-02f2-11eb-9e5f-7c86e0ee822f.png)

# 使用方法

### 実行するまでの流れ

<br>

0. Homebrew のインストール
1. Docker のインストール
2. Swift が実行できる環境をつくる
3. Vapor をインストールする
4. Docker コンテナとしての PostgreSQL 環境をつくる
5. このアプリを GitHub からクローンして実行ファイル作成
6. Vapor .env ファイルによる環境変数を設定
7. アプリ実行

<br>

### 0.Homebrew のインストール

<br>

[Homebrew](https://brew.sh/index_ja) というのは Mac のパッケージ管理アプリです。<br>
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
~ $ brew update
~ $ brew cask install docker
```

この後、Docker アプリを起動します。<br>
おそらく Mac の管理者パスワードを求められると思いますので入力します。<br>
これで Docker がインストールされ、 docker コマンドが使用出来ます。

<br>

### 2. Swift が実行できる環境をつくる

<br>

App Store から Xcode の最新版をインストールします。<br>
すると Swift の最新版もインストールされます。

<br>

### 3. Vapor をインストールする

<br>

Vapor を利用するための Vapor Toolbox というものをインストールします。これにより vapor コマンドが使えるようになり、build や run などが簡単に行えるようになります。<br>
これも[公式サイト](https://docs.vapor.codes/4.0/install/macos/#install-toolbox)にインストール方法があります。

```
~ $ brew install vapor
```

<br>

### 4. Docker コンテナとしての PostgreSQL 環境をつくる

<br>

このアプリで使用する DB の PostgreSQL をインストールします。<br>
ここでは、現在の最新版の 12.4 をインストールしています。

```
~ $ docker run --name myblog -e POSTGRES_ROOT_PASSWORD=9999 -e POSTGRES_USER=postgres_vapor -e POSTGRES_PASSWORD=password -e POSTGRES_DB=blogdb -p 5432:5432 -d postgres:12.4
```

<br>

### 5. このアプリを GitHub からクローンして実行ファイル作成

<br>

```
~ $ cd ~/Desktop
Desktop $ git clone https://github.com/yoshiswift/swift-vapor-blog.git
Desktop $ cd swift-vapor-blog
swift-vapor-blog $ swift build
・・・
Linking Run
```

最後の行に「Linking Run」と出たら OK です。

<br>

### 6. 環境変数の設定

<br>

Vapor では、 Vapor 用の環境変数を設定出来ます。<br>

[Vapor's Environment API](https://docs.vapor.codes/4.0/environment/)

これはプログラムの外側から設定できるので、作成した Web アプリの構成を動的に変える事が出来ます。<br>
Vapor で設定できる範囲なら、設定項目は自分で自由に決められます。<br>

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
ここでは、nano というコマンドライン上のテキストエディタを使用して、「.env.development」という名前のファイルを新規作成しています。<br>

> nano の簡単な入力方法<br>
> - 保存：「control」+「o」 -> 「エンターキー」
> - キャンセル：「control」+「o」 -> 「control」+「c」
> - 終了：「control」+「x」 
<br><br>
> 間違えた時は、一旦キャンセルで抜けましょう

```
swift-vapor-blog $ nano .env.development
```

ターミナル上でテキストエディタが開いたと思いますので上記の項目を入力します。<br>
下記はその一例です。コピペでもOKです。

例：
```
SERVER_PORT=8080
DEFAULT_MAX_BODY_SIZE=10mb

DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres_vapor
DATABASE_PASSWORD=password
DATABASE_NAME=blogdb

USER_NAME=VAPOR
USER_USERNAME=vapor
USER_PASSWORD=9999
```

<br>

### 7. アプリ実行

<br>

```
swift-vapor-blog $ ./.build/debug/Run
```

<br>

### 8. ブラウザを開く

http://localhost:8080

<br><br>

# 使い方

<br>

1. ブログを作成するには、環境変数で作成したアプリの管理ユーザーでログインします。上記の例の場合、ユーザー名「vapor」、パスワード「9999」です。もしくは、「新規登録」から新しくユーザーを作成してもOKです。

2. ログインすると、メニューに「ブログ作成」というボタンが出てくるのでクリックします。

3. デモに載せている作成画面になります。

4. 好きに書いて「送信」ボタンを押します。

<br><br>

# 修正したい箇所・欲しい機能など

<br>

- ブログを作成するのは自分だけなので、「ユーザー一覧」「新規作成」は必要ない
- それと関連して、不要なソースコードが多くある
- まだまだ UI が不便 & 統一性が無いので直したい
- 関連するブログの表示機能が欲しい
- 下書き機能が欲しい