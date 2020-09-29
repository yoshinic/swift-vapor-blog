function initQuill() {
  return new Quill(
    '#editor', 
    {
      modules: {
        syntax: true,
        toolbar: null
      },
      readOnly: true,
      theme: 'snow'
    }
  );
}

function unescapeHTML(str) {
  const div = document.createElement("div");
  div.innerHTML = str.replace(/</g,"&lt;")
                     .replace(/>/g,"&gt;")
                     .replace(/ /g, "&nbsp;")
                     .replace(/\r/g, "&#13;")
                     .replace(/\n/g, "&#10;");
  return div.textContent || div.innerText;
}

// 既に保存してある Quill データをサーバーから読み込む
function readContentsData(uri) {
  fetch(uri, {
    method: 'GET'
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`${response.status} ${response.statusText}`);
      }
      return response.arrayBuffer();
    })
    .then((data) => {
      const u8arr = new Uint8Array(data);
      const s = new TextDecoder().decode(u8arr);
      const x = unescapeHTML(s).replace(/\n/g, "\\n")
      const j = JSON.parse(x);
      quill.setContents(j);
    })
    .catch((reason) => {
      // エラー処理
      console.log('** fetch: catch');
      console.log(reason);
    });
}

// 画面表示時に読み込む処理セット
const quill = initQuill();